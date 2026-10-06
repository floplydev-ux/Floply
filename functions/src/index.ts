import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";

admin.initializeApp();
const db = admin.firestore();

// ──────────────────────────────────────────────────────────────────────────────
// Tipos
// ──────────────────────────────────────────────────────────────────────────────

interface RedeemRequest {
  code: string;
}

interface RedeemResponse {
  benefitLabel: string;
}

// ──────────────────────────────────────────────────────────────────────────────
// redeemPromoCode — callable HTTPS function
//
// Valida y canjea un código promocional de forma atómica.
// La app Flutter NUNCA decide localmente si un código es válido:
// toda la lógica vive aquí, en el backend.
//
// Flujo:
//  1. Verificar autenticación.
//  2. Normalizar código (trim + toUpperCase).
//  3. Transacción Firestore:
//       a. Leer promo_codes/{code}   → validar existencia, activo, fechas, cupo.
//       b. Leer promo_redemptions/{uid}_{code} → verificar no canjeado antes.
//       c. Leer users/{uid}          → obtener promoExpiresAt actual.
//       d. Calcular nueva fecha de vencimiento (extiende si ya tenía promo).
//       e. Escribir promo_redemptions/{uid}_{code}.
//       f. Incrementar promo_codes/{code}.redemptionCount atómicamente.
//       g. Actualizar users/{uid}.promoExpiresAt.
//  4. Devolver { benefitLabel }.
// ──────────────────────────────────────────────────────────────────────────────
export const redeemPromoCode = onCall<RedeemRequest, Promise<RedeemResponse>>(
  { region: "us-central1" },
  async (request) => {
    // 1. Auth
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "unauthenticated");
    }
    const uid = request.auth.uid;

    // 2. Normalizar
    const raw = request.data.code;
    if (typeof raw !== "string") {
      throw new HttpsError("invalid-argument", "invalid_argument");
    }
    const code = raw.trim().toUpperCase();
    if (!code) {
      throw new HttpsError("not-found", "promo_not_found");
    }

    // 3. Referencias
    const promoRef = db.collection("promo_codes").doc(code);
    const redemptionId = `${uid}_${code}`;
    const redemptionRef = db.collection("promo_redemptions").doc(redemptionId);
    const userRef = db.collection("users").doc(uid);

    const result = await db.runTransaction(async (t) => {
      // Lecturas (deben ir antes de cualquier escritura en Firestore txn)
      const [promoSnap, redemptionSnap, userSnap] = await Promise.all([
        t.get(promoRef),
        t.get(redemptionRef),
        t.get(userRef),
      ]);

      // a. Promo existe
      if (!promoSnap.exists) {
        throw new HttpsError("not-found", "promo_not_found");
      }
      const promo = promoSnap.data()!;

      // b. Activo
      if (promo.active !== true) {
        throw new HttpsError("failed-precondition", "promo_inactive");
      }

      // c. Fecha de inicio
      const now = admin.firestore.Timestamp.now().toDate();
      if (promo.startsAt instanceof admin.firestore.Timestamp) {
        if (promo.startsAt.toDate() > now) {
          throw new HttpsError("failed-precondition", "promo_not_started");
        }
      }

      // d. Fecha de vencimiento del código
      if (promo.expiresAt instanceof admin.firestore.Timestamp) {
        if (promo.expiresAt.toDate() < now) {
          throw new HttpsError("failed-precondition", "promo_expired");
        }
      }

      // e. Cupo
      if (
        promo.maxRedemptions !== null &&
        promo.maxRedemptions !== undefined &&
        typeof promo.maxRedemptions === "number"
      ) {
        const count =
          typeof promo.redemptionCount === "number" ? promo.redemptionCount : 0;
        if (count >= promo.maxRedemptions) {
          throw new HttpsError("resource-exhausted", "promo_exhausted");
        }
      }

      // f. Ya canjeado por este usuario
      if (redemptionSnap.exists) {
        throw new HttpsError("already-exists", "promo_already_redeemed");
      }

      // g. Calcular nueva fecha de promo
      const existingExpiry: Date | null =
        userSnap.exists &&
        userSnap.data()?.promoExpiresAt instanceof admin.firestore.Timestamp
          ? (userSnap.data()!.promoExpiresAt as admin.firestore.Timestamp).toDate()
          : null;

      // Extiende desde el vencimiento actual si aún es futuro;
      // de lo contrario extiende desde ahora.
      const base =
        existingExpiry && existingExpiry > now ? existingExpiry : now;

      const durationValue: number =
        typeof promo.durationValue === "number" ? promo.durationValue : 0;
      const durationUnit: string =
        typeof promo.durationUnit === "string" ? promo.durationUnit : "days";

      const newExpiry = new Date(base);
      if (durationUnit === "months") {
        newExpiry.setMonth(newExpiry.getMonth() + durationValue);
      } else {
        // 'days' (default)
        newExpiry.setTime(
          newExpiry.getTime() + durationValue * 24 * 60 * 60 * 1000
        );
      }

      const newExpiryTs = admin.firestore.Timestamp.fromDate(newExpiry);

      // h. Escrituras dentro de la transacción
      t.set(redemptionRef, {
        code,
        userId: uid,
        redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
        benefitType: promo.benefitType ?? "premium",
        durationValue,
        durationUnit,
        promoExpiresAt: newExpiryTs,
      });

      t.update(promoRef, {
        redemptionCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      t.set(userRef, { promoExpiresAt: newExpiryTs }, { merge: true });

      return { durationValue, durationUnit };
    });

    // 4. Construir benefitLabel legible
    const { durationValue, durationUnit } = result;
    const unitLabel =
      durationUnit === "months"
        ? durationValue === 1
          ? "mes"
          : "meses"
        : durationValue === 1
          ? "día"
          : "días";

    return { benefitLabel: `Premium por ${durationValue} ${unitLabel}` };
  }
);

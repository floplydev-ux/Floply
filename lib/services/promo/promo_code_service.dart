import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'promo_code_failure.dart';

/// Región de Firebase Functions donde está deployado [redeemPromoCode].
const _kFunctionsRegion = 'us-central1';

/// Servicio de códigos promocionales.
///
/// Responsabilidades:
///  1. Llamar al backend (Firebase Function) para validar y canjear un código.
///  2. Mantener el estado de promo activo leyendo [promoExpiresAt] de Firestore
///     en tiempo real — así el estado refleja cambios del backend sin reinicios.
///
/// [isPromoActive] es `true` mientras la fecha de vencimiento de la promo
/// sea futura. Esto complementa RevenueCat: la fuente de verdad para Premium
/// por suscripción sigue siendo RC; este servicio añade el carril de promos.
abstract class PromoCodeService extends ChangeNotifier {
  bool get isPromoActive;
  DateTime? get promoExpiresAt;

  /// Normaliza y canjea [code]. Devuelve [PromoCodeSuccess] o [PromoCodeFailure].
  Future<PromoCodeResult> redeem(String code);

  /// Sincroniza el usuario con el estado de auth — inicia/cancela la
  /// suscripción a Firestore según si hay un [uid] activo.
  void onUserChanged(String? uid);
}

class FirebasePromoCodeService extends PromoCodeService {
  FirebasePromoCodeService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: FirebaseFirestore.instance.app,
              databaseId: 'default',
            ),
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: _kFunctionsRegion);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  DateTime? _promoExpiresAt;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  DateTime? get promoExpiresAt => _promoExpiresAt;

  @override
  bool get isPromoActive {
    final expiry = _promoExpiresAt;
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  @override
  void onUserChanged(String? uid) {
    _sub?.cancel();
    _sub = null;
    if (uid == null) {
      _promoExpiresAt = null;
      notifyListeners();
      return;
    }
    _sub = _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(_onUserSnapshot, onError: (_) {});
  }

  void _onUserSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    final raw = data?['promoExpiresAt'];
    DateTime? parsed;
    if (raw is Timestamp) {
      parsed = raw.toDate();
    } else if (raw is String) {
      parsed = DateTime.tryParse(raw);
    }
    _promoExpiresAt = parsed;
    notifyListeners();
  }

  @override
  Future<PromoCodeResult> redeem(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const PromoCodeFailure(PromoCodeFailureReason.notFound);
    }
    try {
      final callable = _functions.httpsCallable('redeemPromoCode');
      final result = await callable.call<Map<String, dynamic>>({'code': normalized});
      final benefitLabel = result.data['benefitLabel'] as String? ?? '';
      return PromoCodeSuccess(benefitLabel: benefitLabel);
    } on FirebaseFunctionsException catch (e) {
      return PromoCodeFailure(_mapFunctionsError(e));
    } catch (_) {
      return const PromoCodeFailure(PromoCodeFailureReason.serverError);
    }
  }

  PromoCodeFailureReason _mapFunctionsError(FirebaseFunctionsException e) {
    return switch (e.code) {
      'unauthenticated' => PromoCodeFailureReason.unauthenticated,
      'not-found' => PromoCodeFailureReason.notFound,
      'already-exists' => PromoCodeFailureReason.alreadyRedeemed,
      'resource-exhausted' => PromoCodeFailureReason.exhausted,
      'failed-precondition' => switch (e.message) {
          'promo_inactive' => PromoCodeFailureReason.inactive,
          'promo_not_started' => PromoCodeFailureReason.notStarted,
          'promo_expired' => PromoCodeFailureReason.expired,
          _ => PromoCodeFailureReason.serverError,
        },
      _ => PromoCodeFailureReason.serverError,
    };
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

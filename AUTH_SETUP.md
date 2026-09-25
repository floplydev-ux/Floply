# Sistema de cuentas de Floply — arquitectura y puesta en producción

Este documento describe la capa de identidad/autenticación agregada sobre
la app existente, y qué falta configurar manualmente (fuera de este
repositorio) para que el login real contra Google/Apple/email funcione.

## 1. Arquitectura de autenticación

Todo vive bajo `lib/auth/`, como una capa independiente por encima de lo
que ya existía — ninguna pantalla de Academia/Bankroll/Home/Practice Room
conoce esta capa, y ella tampoco conoce el motor pedagógico más allá de la
interfaz `AcademyStore` ya existente.

```
lib/auth/
├── models/
│   ├── floply_user.dart       FloplyUser: la identidad de cuenta
│   ├── auth_provider_type.dart enum google/apple/email
│   ├── auth_identity.dart     lo que devuelve el proveedor crudo
│   ├── auth_state.dart        AuthLoading/Unauthenticated/Guest/Authenticated
│   └── account_conflict.dart  modelo del conflicto de cuentas (Fase 9)
├── auth_repository.dart       interfaz — nadie más importa Firebase
├── firebase_auth_repository.dart  implementación real
├── fake_auth_repository.dart      doble para tests
├── user_repository.dart       interfaz de perfil (Firestore)
├── firestore_user_repository.dart / fake_user_repository.dart
├── auth_controller.dart       orquestación (ChangeNotifier, como AcademyController)
└── widgets/
    ├── auth_gate.dart         el único widget que ramifica sobre el estado global
    ├── auth_screen.dart       Google / Apple / email / continuar sin cuenta
    ├── email_link_screen.dart flujo de email sin contraseña
    ├── account_screen.dart    Perfil → Cuenta (reemplaza el tab Perfil)
    └── account_conflict_sheet.dart

lib/persistence/
├── firestore_academy_store.dart  implementa el AcademyStore YA EXISTENTE
├── syncing_academy_store.dart    decorador local+remoto, reglas de merge
└── local_auth_flag_store.dart    flag "eligió continuar sin cuenta"
```

`AppShell` recibe ahora `academyStore` y `authController` por constructor
— `AuthGate` decide cuál `AcademyStore` corresponde (local puro en
invitado, sincronizado autenticado) antes de construirlo. Nada del motor
pedagógico (`AcademyEngine`, `AcademyProgress`, `UserKnowledge`,
curriculum, ejercicios, mesa, fichas) cambió.

## 2. Proveedores

`AuthProviderType { google, apple, email }`. Agregar uno nuevo (teléfono,
etc.) implica: un valor más acá, un método más en `AuthRepository`, y una
rama más en `_ProviderButton`/`_MethodRow` de la UI — no reestructurar
nada existente.

## 3. Estructura de usuario — `FloplyUser`

`id` (el de Firebase Auth — igual sin importar el proveedor),
`createdAt`, `updatedAt`, `displayName`, `username?`, `email?`,
`photoUrl?`, `locale`, `country?`, `onboardingCompleted`,
`accountStatus`, `linkedProviders` (lista de `LinkedProvider {type,
providerUid, email?, linkedAt}` — el id ESTABLE de cada proveedor, nunca
el email). Documento Firestore en `users/{id}`.

## 4. Almacenamiento local

- `FileAuthFlagStore` (`lib/persistence/local_auth_flag_store.dart`): un
  archivo marcador (`guest_mode.flag`) en el directorio de documentos de
  la app — mismo mecanismo que ya usaba `FileAcademyStore`, sin agregar
  `shared_preferences` para un solo booleano.
- El progreso de Academia sigue guardándose local con
  `FileAcademyStore`/`InMemoryAcademyStore` (sin cambios) — en modo
  invitado es la única fuente; autenticado, queda envuelto por
  `SyncingAcademyStore` como caché.

## 5. Almacenamiento remoto

Cloud Firestore. Colecciones:

- `users/{uid}` — el documento `FloplyUser` (perfil + proveedores vinculados).
- `users/{uid}/academy/progress` — el mismo blob JSON versionado que ya
  producía `AcademySaveData.toJson()` (`{version, knowledge, academy}`),
  sin cambios de esquema entre local y remoto.

Reglas de seguridad recomendadas (a configurar en la consola de Firebase,
no en este repo):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /academy/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

## 6. Sincronización

`SyncingAcademyStore.load()` prioriza el remoto (multi-dispositivo) y cae
al local si no hay red. `save()` escribe local primero (nunca depende de
la red) e intenta el remoto best-effort. Firestore además trae caché
local + sync automático de fábrica (`persistenceEnabled`), que es la
razón principal por la que se eligió Firebase (ver el plan técnico
presentado antes de implementar, o la sección "Decisión de tecnología"
más abajo).

## 7. Migración (invitado → cuenta)

Al autenticarse por primera vez, `AuthController._onIdentityChanged`
arma un `SyncingAcademyStore` con el local existente (que puede tener
progreso de uso como invitado) + el remoto de la cuenta, y llama a
`reconcile()` **una sola vez**. Reglas (Fase 13), en
`SyncingAcademyStore`:

- **A) sin remoto + con local** → sube el local tal cual.
- **B) con remoto + sin local** → baja el remoto tal cual.
- **C) ambos** → merge por lección (gana completada sobre no completada;
  entre dos completadas o dos no completadas, gana el mejor puntaje) y
  por concepto (gana el `MasteryState` más avanzado, tomando ESE lado
  completo — nunca se mezclan campos de dos lados distintos, para no
  romper la relación intentos/aciertos de cada `UserConceptMastery`).

Idempotente por construcción: todo está keyado por ids de lección/concepto
ya existentes, nunca se agregan ids nuevos en el merge — correrlo dos
veces da el mismo resultado (probado en
`test/engine/syncing_academy_store_test.dart`).

## 8. Vinculación de cuentas

`AuthController.linkGoogle()/linkApple()/sendEmailLinkForLinking()` usan
`user.linkWithCredential()` de Firebase sobre la sesión activa — el uid
nunca cambia. Si el proveedor ya está asociado a OTRA cuenta, Firebase
devuelve `credential-already-in-use`/`account-exists-with-different-credential`,
que se traduce a `AuthAttemptConflict` (Fase 9): la UI muestra
`AccountConflictSheet` y el usuario elige explícitamente — nunca se
fusiona nada solo.

## 9. Eliminación de cuenta

`AuthController.deleteAccount()`: borra el documento de perfil
(`users/{uid}`), borra el progreso remoto
(`users/{uid}/academy/progress`), y por último `user.delete()` en
Firebase Auth (requiere sesión reciente — si Firebase pide
reautenticación, se resuelve con `AuthController.reauthenticate(tipo)`
antes de reintentar). El progreso **local** del dispositivo no se toca
automáticamente (queda igual que estaba antes de tener cuenta) — es una
decisión de producto pendiente si además se lo quiere borrar del
dispositivo; hoy la app vuelve a `AuthUnauthenticated` sin login.

## 10. Variables / configuración necesarias

| Dato | Dónde se usa | Cómo se obtiene |
|---|---|---|
| Proyecto Firebase | `lib/firebase_options.dart` | Consola de Firebase → crear proyecto |
| `google-services.json` | `android/app/` | Consola de Firebase → agregar app Android |
| `GoogleService-Info.plist` | `ios/Runner/` | Consola de Firebase → agregar app iOS |
| OAuth Client ID (Google, tipo Web) | `googleServerClientId` al construir `FirebaseAuthRepository` | Google Cloud Console → Credentials (lo genera Firebase Auth al activar el proveedor Google) |
| SHA-1/SHA-256 de firma Android | Consola de Firebase → app Android | `keytool` sobre tu keystore de debug/release |
| Services ID + Team ID + Key de Sign in with Apple | Apple Developer Program (de pago) | developer.apple.com → Certificates, Identifiers & Profiles |
| Dominio propio verificado (App Links/Universal Links) | `emailLinkContinueUrl` al construir `FirebaseAuthRepository` | Tu propio dominio; Firebase Dynamic Links está en proceso de baja, así que el link de email usa App Links/Universal Links directo |

## 11. Configuración Android

1. `flutterfire configure` (o descargar `google-services.json` manual
   desde la consola de Firebase) y colocarlo en `android/app/`.
2. Activar Google Sign-In en la consola de Firebase Auth, con el SHA-1 de
   tu keystore.
3. `applicationId`/`namespace` ya están definitivos: `com.floply.app`
   (en `android/app/build.gradle.kts`, con
   `android/app/src/main/kotlin/com/floply/app/MainActivity.kt`
   siguiendo esa misma ruta de paquete). Falta usar ese mismo id al
   registrar la app Android en la consola de Firebase.
4. `minSdk` ya cumple lo que piden los SDKs de Google/Firebase (usa
   `flutter.minSdkVersion`, que Flutter mantiene al día).

## 12. Configuración iOS

`ios/` no existía en el proyecto — se creó con `flutter create
--platforms=ios .` (scaffold estándar, no toca nada existente). Falta,
todo del lado de Apple/Xcode (no verificable desde este entorno, sin
Mac):

1. `flutterfire configure` (o `GoogleService-Info.plist` manual) en
   `ios/Runner/`.
2. En Xcode: agregar la capability "Sign in with Apple" al target Runner.
3. Apple Developer Program: crear un Services ID, asociarlo al bundle id,
   y una Sign in with Apple key.
4. Confirmar `iosBundleId` en `firebase_options.dart` una vez que se
   defina el bundle id real (hoy `com.floply.app` de referencia).

## 13. Configuración Web

`google_sign_in` en web requiere el botón renderizado por el propio SDK
de Google (no un `signIn()` programático) — `FirebaseAuthRepository`
hoy detecta esto (`supportsAuthenticate()`) y devuelve un error
controlado en vez de romper; falta agregar el botón nativo de Google
para Web como una iteración aparte. Apple y Email Link si funcionan en
web sin pasos extra más allá del proyecto Firebase.

## 14. Pasos para producción (resumen)

1. Crear el proyecto Firebase real y correr `flutterfire configure`
   (reemplaza `lib/firebase_options.dart` por los valores reales).
2. Activar los proveedores Google/Apple/Email Link en Firebase Auth.
3. Configurar reglas de seguridad de Firestore (sección 5).
4. Cambiar `applicationId`/bundle id de placeholder a el real (sección 11/12).
5. Configurar un dominio propio para Email Link (sección 10).
6. Volver a correr `flutter test` y las builds de cada plataforma.

## 15. Secretos a configurar manualmente (nunca en este repo)

`google-services.json`, `GoogleService-Info.plist` — ya en `.gitignore`.
Las API key de `firebase_options.dart` no son secretas en sentido
estricto (están pensadas para ir en el cliente; se protegen con las
reglas de Firestore/App Check, no ocultándolas) pero igual conviene no
versionar la configuración real de un proyecto en un repo público — el
archivo hoy tiene solo placeholders, documentado en su propio
encabezado.

## 16. Qué NO debe entrar a Git

- `google-services.json` / `GoogleService-Info.plist` (ya ignorados).
- Cualquier `firebase_options.dart` con valores reales, si el repo es
  público (decisión del equipo — hoy sigue versionado porque son
  placeholders).
- Certificados/keys de Sign in with Apple (`.p8`), keystores de firma
  Android (`.jks`/`.keystore`) — no forman parte de este cambio pero
  aplica el mismo criterio a futuro.

---

## Decisión de tecnología (resumen — detalle completo en el plan presentado)

Se evaluó Firebase vs. Supabase. Se eligió **Firebase (Auth + Firestore)**
principalmente porque Firestore trae caché local + sincronización
automática de fábrica, que es exactamente lo que pedía la Fase 15
(offline) sin tener que construir esa capa a mano — la alternativa más
fuerte de Supabase (OTP de email nativo, más simple que el Email Link de
Firebase) no compensaba tener que reimplementar todo el sync offline.

## Límites de esta implementación (honesto, no oculto)

- No se pudo crear un proyecto Firebase real, ni credenciales OAuth de
  Google, ni un Services ID/capability de Apple — requieren las cuentas
  del propio equipo. El código está escrito y compila contra los SDKs
  reales (`flutter analyze`, `flutter test`, `flutter build web` y
  `flutter build apk` — los cuatro verificados en este cambio), pero el
  login real contra Google/Apple/Firebase no se pudo probar en vivo.
- Los tests de `AuthController`/`SyncingAcademyStore` usan dobles en
  memoria (`FakeAuthRepository`/`FakeUserRepository`/
  `InMemoryAcademyStore`, mismo patrón que ya usaba el proyecto para
  `AcademyStore`) — cubren la orquestación y las reglas de merge, no el
  intercambio de credenciales real con Google/Apple.
- El botón de Google en Web necesita su propio renderizado nativo
  (sección 13) — no implementado en este pase.
- El link de email, sin un dominio propio configurado (sección 10),
  sigue siendo seguro y funciona, pero abre en el navegador en vez de
  reabrir la app sola.

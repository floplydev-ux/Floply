import 'models/auth_identity.dart';
import 'models/auth_provider_type.dart';

/// Lo que pasó al intentar autenticar o vincular un método — separado de
/// una excepción cruda de Firebase a propósito: nada por encima de esta
/// capa debería saber que existe Firebase (Fase 24).
sealed class AuthAttemptResult {
  const AuthAttemptResult();
}

/// Éxito de la operación. [identity] es `null` cuando la operación no
/// produce sesión todavía (p. ej. "se mandó el link de acceso por email"
/// — el usuario completa el ingreso recién al tocar ese link).
class AuthAttemptSuccess extends AuthAttemptResult {
  const AuthAttemptSuccess([this.identity]);
  final AuthIdentity? identity;
}

/// El usuario canceló el flujo (cerró el picker de Google, canceló el
/// diálogo de Apple…). No es un error — no debe mostrarse ningún mensaje.
class AuthAttemptCancelled extends AuthAttemptResult {
  const AuthAttemptCancelled();
}

/// El método ya está asociado a otra cuenta (Fase 9). La UI decide qué
/// ofrecer; acá solo se reporta el hecho.
class AuthAttemptConflict extends AuthAttemptResult {
  const AuthAttemptConflict({required this.provider, this.existingEmail});
  final AuthProviderType provider;
  final String? existingEmail;
}

/// Cualquier otro fallo (red, proveedor caído, etc.), ya traducido a un
/// [AuthFailureReason] que la UI puede mostrar sin conocer el proveedor
/// real (Fase 23: nunca el texto técnico crudo).
class AuthAttemptFailure extends AuthAttemptResult {
  const AuthAttemptFailure(this.reason);
  final AuthFailureReason reason;
}

enum AuthFailureReason {
  network,
  providerError,
  invalidCode,
  expiredCode,
  reauthenticationRequired,
  tooManyAttempts,
  // Nuevos — flujo email+contraseña y verificación telefónica
  wrongPassword,
  emailNotFound,
  invalidPhone,
  phoneAlreadyRegistered,
  weakPassword,
  emailAlreadyInUse,
  unknown,
}

/// La capa de autenticación cruda. Ninguna pantalla debe importar
/// `firebase_auth`/`google_sign_in`/`sign_in_with_apple` directamente —
/// siempre a través de esta interfaz (Fase 24). `AuthController` es el
/// único consumidor.
abstract class AuthRepository {
  /// Emite la identidad actual cada vez que cambia (login/logout/
  /// vinculación). `null` = sin sesión. Es la fuente de verdad de
  /// `AuthGate` — sin polling, sin flags propios.
  Stream<AuthIdentity?> authStateChanges();

  AuthIdentity? get currentIdentity;

  Future<AuthAttemptResult> signInWithGoogle();
  Future<AuthAttemptResult> signInWithApple();

  /// Envía el link de acceso sin contraseña (Fase 5). No hay resultado
  /// inmediato: el usuario completa el ingreso al tocar el link.
  Future<AuthAttemptResult> sendEmailSignInLink(String email);

  bool isEmailSignInLink(String link);

  Future<AuthAttemptResult> confirmEmailSignInLink({
    required String email,
    required String link,
  });

  /// Inicia sesión con email y contraseña (flujo clásico).
  Future<AuthAttemptResult> signInWithEmailPassword(
    String email,
    String password,
  );

  /// Envía un código SMS al [phoneNumber] y devuelve el `verificationId`
  /// (opaco, necesario para confirmar el código después). `null` si falla.
  Future<String?> sendSmsVerificationCode(String phoneNumber);

  /// Crea una cuenta completa: verifica el teléfono con el código SMS y
  /// vincula email+contraseña en un solo paso atómico (con rollback si
  /// algo falla).
  Future<AuthAttemptResult> createAccountWithPhone({
    required String name,
    required String email,
    required String password,
    required String phoneVerificationId,
    required String smsCode,
  });

  Future<AuthAttemptResult> linkGoogle();
  Future<AuthAttemptResult> linkApple();
  Future<AuthAttemptResult> sendEmailLinkForLinking(String email);
  Future<AuthAttemptResult> confirmEmailLink({
    required String email,
    required String link,
  });

  Future<void> unlink(AuthProviderType type);

  /// Requerido antes de una operación sensible (borrar cuenta) si
  /// Firebase exige sesión reciente. No-op si no hace falta.
  Future<AuthAttemptResult> reauthenticate(AuthProviderType type);

  Future<void> signOut();

  /// Elimina la cuenta del proveedor de autenticación. La eliminación de
  /// los datos asociados (perfil, progreso) es responsabilidad de
  /// `AuthController`/`UserRepository` — esta capa solo borra la
  /// identidad.
  Future<void> deleteAuthAccount();

  /// Devuelve `true` si el usuario autenticado tiene el Firebase Custom
  /// Claim `reviewerPremium: true` — asignado exclusivamente vía Admin SDK
  /// a la cuenta de Google Play Reviewer. El cliente nunca puede establecer
  /// este claim por sí solo.
  Future<bool> isReviewerAccount();
}

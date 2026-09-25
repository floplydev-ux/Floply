import 'auth_provider_type.dart';

/// Lo que devuelve la capa de autenticación cruda (Firebase Auth), antes
/// de tener un perfil [FloplyUser]. Deliberadamente separado de
/// [FloplyUser]: esto es "¿quién dice el proveedor que sos ahora mismo?",
/// no "¿cuál es tu perfil de Floply?" — la Fase 24 pide esta separación
/// explícita entre AUTHENTICATION y USER PROFILE.
class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    required this.providers,
    this.displayName,
    this.email,
    this.photoUrl,
    this.emailVerified = false,
    this.isNewUser = false,
  });

  /// El uid de Firebase Auth. Es estable para una misma cuenta sin
  /// importar con qué proveedor se ingresó — Firebase ya resuelve la
  /// regla "un solo id sin importar el método" a este nivel; encima de
  /// esto construimos [FloplyUser].
  final String uid;

  final Set<AuthProviderType> providers;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  /// Del proveedor: si Firebase Auth confirma que el email de esta
  /// identidad está verificado ahora mismo. Deliberadamente no se
  /// persiste en [FloplyUser] — es un dato vivo de Firebase Auth, no algo
  /// propio de Floply, y puede cambiar sin que haya un login nuevo.
  final bool emailVerified;

  /// `true` solo en la respuesta del sign-in que crea la cuenta por
  /// primera vez (Firebase lo informa vía `UserCredential.additionalUserInfo`).
  final bool isNewUser;
}

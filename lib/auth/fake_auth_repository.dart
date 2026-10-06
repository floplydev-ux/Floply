import 'dart:async';

import 'auth_repository.dart';
import 'models/auth_identity.dart';
import 'models/auth_provider_type.dart';

/// Implementación en memoria de [AuthRepository], **solo para tests**
/// (mismo rol que `InMemoryAcademyStore` para `AcademyStore`): no hay
/// forma de ejecutar un login real contra Google/Apple/Firebase en este
/// entorno, así que la lógica de orquestación (`AuthController`) se
/// prueba contra este doble, controlado explícitamente por cada test.
///
/// Patrón: cada test encola con [queue] el resultado que debería devolver
/// la PRÓXIMA llamada (`signInWithGoogle`, `linkApple`, etc.) — determinista
/// y explícito, sin intentar reimplementar las reglas reales de Firebase.
class FakeAuthRepository implements AuthRepository {
  final StreamController<AuthIdentity?> _controller =
      StreamController<AuthIdentity?>.broadcast();
  AuthIdentity? _current;
  final List<AuthAttemptResult> _queue = [];

  /// Encola el resultado de la próxima operación (sign-in, link,
  /// confirmación de email, reautenticación…).
  void queue(AuthAttemptResult result) => _queue.add(result);

  /// Atajo para el caso más común en tests: un login/link exitoso.
  void queueSuccess(AuthIdentity identity) =>
      queue(AuthAttemptSuccess(identity));

  AuthAttemptResult _consume() {
    if (_queue.isEmpty) {
      throw StateError(
          'FakeAuthRepository: no hay ningún resultado encolado — llamar '
          'queue()/queueSuccess() antes de esta operación.');
    }
    final result = _queue.removeAt(0);
    if (result is AuthAttemptSuccess && result.identity != null) {
      _current = result.identity;
      _controller.add(_current);
    }
    return result;
  }

  @override
  Stream<AuthIdentity?> authStateChanges() => _controller.stream;

  @override
  AuthIdentity? get currentIdentity => _current;

  @override
  Future<AuthAttemptResult> signInWithGoogle() async => _consume();

  @override
  Future<AuthAttemptResult> signInWithApple() async => _consume();

  String? _pendingEmail;

  @override
  Future<AuthAttemptResult> sendEmailSignInLink(String email) async {
    final result = _consume();
    if (result is AuthAttemptSuccess) _pendingEmail = email;
    return result;
  }

  @override
  bool isEmailSignInLink(String link) => link.startsWith('flopy-email-link:');

  @override
  Future<AuthAttemptResult> confirmEmailSignInLink({
    required String email,
    required String link,
  }) async =>
      _consume();

  @override
  Future<AuthAttemptResult> signInWithEmailPassword(
    String email,
    String password,
  ) async =>
      _consume();

  String? _pendingVerificationId;

  void queueVerificationId(String? id) => _pendingVerificationId = id;

  @override
  Future<String?> sendSmsVerificationCode(String phoneNumber) async {
    final id = _pendingVerificationId;
    _pendingVerificationId = null;
    return id;
  }

  @override
  Future<AuthAttemptResult> createAccountWithPhone({
    required String name,
    required String email,
    required String password,
    required String phoneVerificationId,
    required String smsCode,
  }) async =>
      _consume();

  @override
  Future<AuthAttemptResult> linkGoogle() async => _consume();

  @override
  Future<AuthAttemptResult> linkApple() async => _consume();

  @override
  Future<AuthAttemptResult> sendEmailLinkForLinking(String email) async {
    final result = _consume();
    if (result is AuthAttemptSuccess) _pendingEmail = email;
    return result;
  }

  @override
  Future<AuthAttemptResult> confirmEmailLink({
    required String email,
    required String link,
  }) async =>
      _consume();

  @override
  Future<AuthAttemptResult> reauthenticate(AuthProviderType type) async =>
      _consume();

  @override
  Future<void> unlink(AuthProviderType type) async {
    final current = _current;
    if (current == null) return;
    _current = AuthIdentity(
      uid: current.uid,
      providers: current.providers.difference({type}),
      displayName: current.displayName,
      email: current.email,
      photoUrl: current.photoUrl,
    );
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _pendingEmail = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAuthAccount() async {
    _current = null;
    _controller.add(null);
  }

  bool _isReviewer = false;

  /// Permite que los tests simulen una cuenta reviewer. Por defecto `false`.
  // ignore: avoid_setters_without_getters
  set reviewerForTest(bool value) => _isReviewer = value;

  @override
  Future<bool> isReviewerAccount() async => _isReviewer;

  /// El último email para el que se mandó un link (sign-in o linking),
  /// para que los tests lo puedan leer sin repetirlo aparte.
  String? get pendingEmail => _pendingEmail;

  void dispose() => _controller.close();
}

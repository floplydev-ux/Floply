import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_repository.dart';
import 'models/auth_identity.dart';
import 'models/auth_provider_type.dart';

/// Implementación real de [AuthRepository] sobre Firebase Auth +
/// `google_sign_in` + `sign_in_with_apple`. Es la ÚNICA clase del proyecto
/// que debería importar esos tres paquetes (Fase 24) — todo lo demás pasa
/// por la interfaz.
///
/// Nota sobre el email: acá "email" quiere decir *Email Link*
/// (passwordless, ver Fase 5), nunca email+contraseña — Floply nunca
/// guarda ni maneja contraseñas.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    this.googleServerClientId,
    this.emailLinkContinueUrl,
    this.androidPackageId,
  })  : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// El client id "web" del proyecto Firebase — lo pide `google_sign_in`
  /// en Android para que el idToken tenga la audiencia correcta. Ver
  /// `AUTH_SETUP.md`.
  final String? googleServerClientId;

  /// A dónde "continúa" el link de email (un dominio propio, verificado,
  /// con App Links/Universal Links — ver `AUTH_SETUP.md`, Fase 2 del
  /// plan). Sin esto configurado, `sendSignInLinkToEmail` falla.
  final String? emailLinkContinueUrl;

  /// Paquete Android, para que el link de email pueda reabrir la app
  /// (`AndroidPackageName` de `ActionCodeSettings`).
  final String? androidPackageId;

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(serverClientId: googleServerClientId);
    _googleInitialized = true;
  }

  AuthIdentity? _toIdentity(fb.User? user) {
    if (user == null) return null;
    return AuthIdentity(
      uid: user.uid,
      providers: user.providerData
          .map((p) => AuthProviderType.fromFirebaseProviderId(p.providerId))
          .whereType<AuthProviderType>()
          .toSet(),
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  AuthAttemptSuccess _success(fb.UserCredential credential) =>
      AuthAttemptSuccess(_toIdentity(credential.user));

  @override
  Stream<AuthIdentity?> authStateChanges() =>
      _auth.authStateChanges().map(_toIdentity);

  @override
  AuthIdentity? get currentIdentity => _toIdentity(_auth.currentUser);

  // ----------------------------------------------------------------
  // Google
  // ----------------------------------------------------------------

  /// Devuelve la credencial de Firebase JUNTO con la cuenta de Google en
  /// sí (`GoogleSignInAccount`) — hace falta la cuenta aparte porque
  /// `GoogleAuthProvider.credential` solo viaja con el idToken, nunca con
  /// la foto de perfil.
  Future<(fb.OAuthCredential, GoogleSignInAccount)?> _googleCredential() async {
    await _ensureGoogleInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      // Web: requiere el botón renderizado por el SDK de Google, no un
      // signIn programático — se resuelve en una iteración futura (ver
      // AUTH_SETUP.md). No rompe mobile, que es la plataforma principal.
      return null;
    }
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) return null;
    return (fb.GoogleAuthProvider.credential(idToken: idToken), account);
  }

  /// Firebase solo completa `User.photoURL`/`displayName` con lo que
  /// traía la credencial en el momento en que la cuenta de Firebase se
  /// CREÓ — no los vuelve a sincronizar solo en logins posteriores (el
  /// mismo motivo por el que `_fillDisplayNameFromApple`, más abajo, hace
  /// falta para el nombre de Apple). Acá el equivalente para la foto de
  /// perfil de Google: si Firebase no tiene una todavía pero la cuenta de
  /// Google sí, se completa a mano — así una cuenta de Google real nunca
  /// se queda mostrando el avatar genérico por esto.
  Future<fb.User?> _fillPhotoFromGoogle(fb.User? user, GoogleSignInAccount account) async {
    if (user == null) return null;
    if (user.photoURL != null && user.photoURL!.isNotEmpty) return user;
    final photo = account.photoUrl;
    if (photo == null || photo.isEmpty) return user;
    await user.updatePhotoURL(photo);
    await user.reload();
    return _auth.currentUser;
  }

  @override
  Future<AuthAttemptResult> signInWithGoogle() async {
    try {
      final result = await _googleCredential();
      if (result == null) {
        return const AuthAttemptFailure(AuthFailureReason.providerError);
      }
      final (credential, account) = result;
      final signedIn = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));
      final user = await _fillPhotoFromGoogle(signedIn.user, account);
      return AuthAttemptSuccess(_toIdentity(user));
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled
          ? const AuthAttemptCancelled()
          : const AuthAttemptFailure(AuthFailureReason.providerError);
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.google);
    } on TimeoutException {
      return const AuthAttemptFailure(AuthFailureReason.network);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  @override
  Future<AuthAttemptResult> linkGoogle() async {
    try {
      final result = await _googleCredential();
      if (result == null) {
        return const AuthAttemptFailure(AuthFailureReason.providerError);
      }
      final (credential, account) = result;
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return const AuthAttemptFailure(AuthFailureReason.unknown);
      }
      final linked = await currentUser.linkWithCredential(credential);
      final user = await _fillPhotoFromGoogle(linked.user, account);
      return AuthAttemptSuccess(_toIdentity(user));
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled
          ? const AuthAttemptCancelled()
          : const AuthAttemptFailure(AuthFailureReason.providerError);
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.google);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  // ----------------------------------------------------------------
  // Apple
  // ----------------------------------------------------------------

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();

  Future<fb.OAuthCredential?> _appleCredential() async {
    final rawNonce = _generateNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256(rawNonce),
    );
    final identityToken = credential.identityToken;
    if (identityToken == null) return null;
    return fb.OAuthProvider('apple.com').credential(
      idToken: identityToken,
      rawNonce: rawNonce,
      accessToken: credential.authorizationCode,
    );
  }

  /// Apple manda el nombre completo SOLO en la primerísima autorización.
  /// Si Firebase todavía no tiene displayName, lo completamos con eso —
  /// si no se captura acá, se pierde para siempre.
  Future<void> _fillDisplayNameFromApple(
    fb.User? user,
    AuthorizationCredentialAppleID credential,
  ) async {
    if (user == null) return;
    if (user.displayName != null && user.displayName!.isNotEmpty) return;
    final parts = [credential.givenName, credential.familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    if (parts.isNotEmpty) await user.updateDisplayName(parts);
  }

  @override
  Future<AuthAttemptResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256(rawNonce),
      );
      final identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        return const AuthAttemptFailure(AuthFailureReason.providerError);
      }
      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      await _fillDisplayNameFromApple(userCredential.user, appleCredential);
      return _success(userCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      return e.code == AuthorizationErrorCode.canceled
          ? const AuthAttemptCancelled()
          : const AuthAttemptFailure(AuthFailureReason.providerError);
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.apple);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  @override
  Future<AuthAttemptResult> linkApple() async {
    try {
      final credential = await _appleCredential();
      if (credential == null) {
        return const AuthAttemptFailure(AuthFailureReason.providerError);
      }
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthAttemptFailure(AuthFailureReason.unknown);
      }
      return _success(await user.linkWithCredential(credential));
    } on SignInWithAppleAuthorizationException catch (e) {
      return e.code == AuthorizationErrorCode.canceled
          ? const AuthAttemptCancelled()
          : const AuthAttemptFailure(AuthFailureReason.providerError);
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.apple);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  // ----------------------------------------------------------------
  // Email + contraseña
  // ----------------------------------------------------------------

  @override
  Future<AuthAttemptResult> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _success(credential);
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.email);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  // ----------------------------------------------------------------
  // Verificación telefónica (SMS)
  // ----------------------------------------------------------------

  @override
  Future<String?> sendSmsVerificationCode(String phoneNumber) {
    final completer = Completer<String?>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) {
        // En Android, Firebase puede recuperar el código automáticamente
        // (instant verification). Si verificationId es nulo o vacío, no
        // completamos: esperamos a codeSent que trae el ID real.
        final id = credential.verificationId;
        if (id != null && id.isNotEmpty && !completer.isCompleted) {
          completer.complete(id);
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.complete(null);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );
    return completer.future;
  }

  @override
  Future<AuthAttemptResult> createAccountWithPhone({
    required String name,
    required String email,
    required String password,
    required String phoneVerificationId,
    required String smsCode,
  }) async {
    fb.User? newPhoneUser;
    try {
      final phoneCredential = fb.PhoneAuthProvider.credential(
        verificationId: phoneVerificationId,
        smsCode: smsCode,
      );
      final phoneSignIn = await _auth.signInWithCredential(phoneCredential);
      final phoneUser = phoneSignIn.user;
      if (phoneUser == null) {
        return const AuthAttemptFailure(AuthFailureReason.unknown);
      }

      // Si el teléfono ya estaba registrado en Firebase, NO borramos la
      // cuenta existente — simplemente cerramos la sesión y reportamos el
      // conflicto. Solo hacemos rollback (delete) si era una cuenta NUEVA.
      final isNew = phoneSignIn.additionalUserInfo?.isNewUser ?? true;
      if (!isNew) {
        try { await _auth.signOut(); } catch (_) {}
        return const AuthAttemptFailure(AuthFailureReason.phoneAlreadyRegistered);
      }

      // A partir de aquí, phoneUser es nuevo — el rollback (delete) es seguro.
      newPhoneUser = phoneUser;

      final emailCredential = fb.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await newPhoneUser.linkWithCredential(emailCredential);
      await newPhoneUser.updateDisplayName(name.trim());
      await newPhoneUser.reload();
      return AuthAttemptSuccess(_toIdentity(_auth.currentUser));
    } on fb.FirebaseAuthException catch (e) {
      if (newPhoneUser != null) {
        try { await newPhoneUser.delete(); } catch (_) {}
        try { await _auth.signOut(); } catch (_) {}
      }
      if (e.code == 'email-already-in-use') {
        return const AuthAttemptFailure(AuthFailureReason.emailAlreadyInUse);
      }
      return _mapFirebaseException(e, AuthProviderType.email);
    } catch (_) {
      if (newPhoneUser != null) {
        try { await newPhoneUser.delete(); } catch (_) {}
        try { await _auth.signOut(); } catch (_) {}
      }
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  // ----------------------------------------------------------------
  // Email link (passwordless)
  // ----------------------------------------------------------------

  fb.ActionCodeSettings get _actionCodeSettings => fb.ActionCodeSettings(
        url: emailLinkContinueUrl ?? 'https://floply.app/finishSignIn',
        handleCodeInApp: true,
        androidPackageName: androidPackageId,
        androidInstallApp: androidPackageId != null,
        androidMinimumVersion: '1',
        iOSBundleId: androidPackageId,
      );

  @override
  Future<AuthAttemptResult> sendEmailSignInLink(String email) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: _actionCodeSettings,
      );
      return const AuthAttemptSuccess();
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.email);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.network);
    }
  }

  @override
  bool isEmailSignInLink(String link) => _auth.isSignInWithEmailLink(link);

  @override
  Future<AuthAttemptResult> confirmEmailSignInLink({
    required String email,
    required String link,
  }) async {
    try {
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      return _success(credential);
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.email);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  @override
  Future<AuthAttemptResult> sendEmailLinkForLinking(String email) async {
    // Mismo mecanismo: el link, al confirmarse con una sesión activa,
    // vincula en vez de crear cuenta (ver confirmEmailLink).
    return sendEmailSignInLink(email);
  }

  @override
  Future<AuthAttemptResult> confirmEmailLink({
    required String email,
    required String link,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthAttemptFailure(AuthFailureReason.unknown);
      }
      final credential = fb.EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: link,
      );
      return _success(await user.linkWithCredential(credential));
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, AuthProviderType.email);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  // ----------------------------------------------------------------
  // Vinculación / sesión / cuenta
  // ----------------------------------------------------------------

  @override
  Future<void> unlink(AuthProviderType type) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.unlink(type.firebaseProviderId);
  }

  @override
  Future<AuthAttemptResult> reauthenticate(AuthProviderType type) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthAttemptFailure(AuthFailureReason.unknown);
      }
      fb.AuthCredential? credential;
      switch (type) {
        case AuthProviderType.google:
          credential = (await _googleCredential())?.$1;
        case AuthProviderType.apple:
          credential = await _appleCredential();
        case AuthProviderType.email:
        case AuthProviderType.phone:
          // La reautenticación por email/teléfono requiere el flujo completo
          // de reingreso de credenciales — se maneja en la UI.
          return const AuthAttemptFailure(AuthFailureReason.providerError);
      }
      if (credential == null) {
        return const AuthAttemptFailure(AuthFailureReason.providerError);
      }
      return _success(await user.reauthenticateWithCredential(credential));
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseException(e, type);
    } catch (_) {
      return const AuthAttemptFailure(AuthFailureReason.unknown);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized) {
      // No revoca el acceso ni loguea al usuario fuera de Google — solo
      // limpia la sesión ligera local, como corresponde a "cerrar sesión"
      // (Fase 16), no a revocar el permiso de la app.
      await _googleSignIn.signOut();
    }
  }

  @override
  Future<void> deleteAuthAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }

  // ----------------------------------------------------------------
  // Reviewer Custom Claim
  // ----------------------------------------------------------------

  /// Lee el Firebase ID token para comprobar si el claim `reviewerPremium`
  /// vale `true`. Se fuerza un refresh para capturar claims recién
  /// asignados por el Admin SDK. Si el usuario no está autenticado, o si
  /// hay algún error de red, devuelve `false` de forma segura.
  @override
  Future<bool> isReviewerAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      final token = await user.getIdTokenResult(true);
      return token.claims?['reviewerPremium'] == true;
    } catch (_) {
      return false;
    }
  }

  // ----------------------------------------------------------------
  // Errores (Fase 23: nunca el texto técnico crudo llega a la UI)
  // ----------------------------------------------------------------

  AuthAttemptResult _mapFirebaseException(
    fb.FirebaseAuthException e,
    AuthProviderType attempted,
  ) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
      case 'email-already-in-use':
        return AuthAttemptConflict(
          provider: attempted,
          existingEmail: e.email,
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthAttemptFailure(AuthFailureReason.wrongPassword);
      case 'user-not-found':
        return const AuthAttemptFailure(AuthFailureReason.emailNotFound);
      case 'invalid-phone-number':
        return const AuthAttemptFailure(AuthFailureReason.invalidPhone);
      case 'phone-number-already-exists':
        return const AuthAttemptFailure(
            AuthFailureReason.phoneAlreadyRegistered);
      case 'weak-password':
        return const AuthAttemptFailure(AuthFailureReason.weakPassword);
      case 'invalid-action-code':
      case 'invalid-verification-code':
        return const AuthAttemptFailure(AuthFailureReason.invalidCode);
      case 'expired-action-code':
        return const AuthAttemptFailure(AuthFailureReason.expiredCode);
      case 'requires-recent-login':
        return const AuthAttemptFailure(
            AuthFailureReason.reauthenticationRequired);
      case 'too-many-requests':
        return const AuthAttemptFailure(AuthFailureReason.tooManyAttempts);
      case 'network-request-failed':
        return const AuthAttemptFailure(AuthFailureReason.network);
      default:
        return const AuthAttemptFailure(AuthFailureReason.providerError);
    }
  }
}

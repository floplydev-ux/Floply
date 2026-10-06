import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../engine/academy/academy_store.dart';
import '../engine/concepts/concept_registry.dart';
import '../models/app_user.dart';
import '../persistence/academy_store_provider.dart';
import '../persistence/firestore_academy_store.dart';
import '../persistence/local_auth_flag_store.dart';
import '../persistence/local_profile_store.dart';
import '../persistence/syncing_academy_store.dart';
import '../services/connectivity_service.dart';
import 'auth_repository.dart';
import 'firebase_auth_repository.dart';
import 'firestore_user_repository.dart';
import 'models/account_conflict.dart';
import 'models/auth_identity.dart';
import 'models/auth_provider_type.dart';
import 'models/auth_state.dart';
import 'models/floply_user.dart';
import 'user_repository.dart';

/// Mensaje de error listo para mostrar — nunca el texto técnico de
/// Firebase (Fase 23). `AuthController` lo calcula; las pantallas solo lo
/// muestran.
String authErrorMessage(AuthFailureReason reason) => switch (reason) {
      AuthFailureReason.network =>
        'No pudimos completar el inicio de sesión. Revisá tu conexión e '
            'intentá nuevamente.',
      AuthFailureReason.providerError =>
        'Algo falló durante el inicio de sesión. Probá de nuevo en unos '
            'segundos.',
      AuthFailureReason.invalidCode => 'Código incorrecto. Revisá e intentá de nuevo.',
      AuthFailureReason.expiredCode =>
        'El código venció. Pedí uno nuevo para continuar.',
      AuthFailureReason.reauthenticationRequired =>
        'Por seguridad, necesitamos que confirmes tu identidad de nuevo.',
      AuthFailureReason.tooManyAttempts =>
        'Demasiados intentos. Esperá un momento antes de volver a probar.',
      AuthFailureReason.wrongPassword ||
      AuthFailureReason.emailNotFound =>
        'Email o contraseña incorrectos.',
      AuthFailureReason.invalidPhone =>
        'Ese número de teléfono no es válido.',
      AuthFailureReason.phoneAlreadyRegistered =>
        'Ya existe una cuenta con ese número de teléfono.',
      AuthFailureReason.weakPassword =>
        'La contraseña debe tener al menos 6 caracteres.',
      AuthFailureReason.emailAlreadyInUse =>
        'Ya existe una cuenta con ese email.',
      AuthFailureReason.unknown =>
        'No pudimos completar la acción. Intentá nuevamente.',
    };

/// La base especial `(default)`, con paréntesis, que el SDK de Firestore
/// usa por defecto exige plan Blaze en este proyecto (ver AUTH_SETUP.md,
/// "Firestore — nombre de la base"). Se usa en cambio una base nombrada
/// literalmente `default` (sin paréntesis), creada sin facturación,
/// apuntada acá de forma explícita.
FirebaseFirestore _floplyFirestore() => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );

/// Coordina identidad de cuenta (Fase 24/25): sesión, vinculación,
/// conflictos, invitado, migración y la construcción del [AcademyStore]
/// correcto para `AppShell`. Mismo patrón que `AcademyController`
/// (`ChangeNotifier`, estado expuesto por getters) — ninguna pantalla
/// habla con `AuthRepository`/Firebase directo.
class AuthController extends ChangeNotifier {
  AuthController({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    AuthFlagStore? flagStore,
    ProfileStore? profileStore,
    ConceptRegistry? conceptRegistry,
    AcademyStore Function()? localStoreBuilder,
    RemoteAcademyStoreBuilder? remoteAcademyStoreBuilder,
    ConnectivityService? connectivity,
  })  : _auth = authRepository ?? FirebaseAuthRepository(),
        _users = userRepository ??
            FirestoreUserRepository(firestore: _floplyFirestore()),
        _flags = flagStore ?? FileAuthFlagStore(),
        _profiles = profileStore ?? FileProfileStore(),
        _registry = conceptRegistry ?? ConceptRegistry.standard(),
        _localStoreBuilder = localStoreBuilder ?? defaultAcademyStore,
        _remoteAcademyStoreBuilder = remoteAcademyStoreBuilder ??
            ((uid) => FirestoreAcademyStore(
                  uid: uid,
                  firestore: _floplyFirestore(),
                )),
        _connectivity = connectivity {
    _connectivity?.addListener(_onConnectivityChanged);
  }

  final AuthRepository _auth;
  final UserRepository _users;
  final AuthFlagStore _flags;
  final ProfileStore _profiles;
  final ConceptRegistry _registry;
  final AcademyStore Function() _localStoreBuilder;
  final AcademyStore Function(String uid) _remoteAcademyStoreBuilder;

  /// Modo offline (sección 10): opcional a propósito — los tests y
  /// cualquier otro consumidor que no le importe la reconciliación en
  /// vivo pueden seguir sin pasarlo, igual que antes.
  final ConnectivityService? _connectivity;

  /// `true` si el último intento de reconciliar progreso local↔remoto
  /// falló (offline) y todavía no se reintentó con éxito. La Academia
  /// sigue funcionando 100% en local mientras tanto — ver
  /// [SyncingAcademyStore].
  bool _pendingReconcile = false;
  bool get hasPendingSync => _pendingReconcile;

  void _onConnectivityChanged() {
    if (_connectivity?.isOnline == true && _pendingReconcile) {
      _retryReconcile();
    }
  }

  Future<void> _retryReconcile() async {
    final store = _academyStore;
    if (store is! SyncingAcademyStore) return;
    try {
      await store.reconcile(_registry);
      _pendingReconcile = false;
      notifyListeners();
    } catch (_) {
      // Sigue pendiente — se reintenta la próxima vez que la
      // conectividad vuelva a `online` (o en el próximo login).
    }
  }

  StreamSubscription<AuthIdentity?>? _sub;

  AuthState _state = const AuthLoading();
  AuthState get state => _state;

  AccountConflict? _pendingConflict;
  AccountConflict? get pendingConflict => _pendingConflict;

  AuthFailureReason? _lastFailure;
  AuthFailureReason? get lastFailure => _lastFailure;

  /// La última identidad que confirmó Firebase Auth — fuente de verdad
  /// para datos que no tiene sentido persistir en Firestore porque son
  /// del proveedor y pueden cambiar sin un login nuevo (`emailVerified`).
  AuthIdentity? _lastIdentity;

  /// Si el email de la sesión actual está verificado, según el proveedor
  /// — no según Firestore. `false` si no hay sesión.
  bool get isEmailVerified => _lastIdentity?.emailVerified ?? false;

  AcademyStore? _academyStore;

  /// El `AcademyStore` que le corresponde al estado actual — local puro
  /// en invitado, sincronizado con la nube una vez autenticado.
  /// `AppShell` lo usa para construir su `AcademyController`; nunca sabe
  /// cuál de los dos es.
  AcademyStore get academyStore => _academyStore ?? _localStoreBuilder();

  bool get isAuthenticated => _state is AuthAuthenticated;

  FloplyUser? get currentUser =>
      switch (_state) { AuthAuthenticated(:final user) => user, _ => null };

  /// Nombre/foto propios de un invitado (sin `FloplyUser`) — ver
  /// [updateGuestDisplayName]/[updateGuestAvatarPath]. Vacío hasta que
  /// [bootstrap] lo carga del disco.
  LocalProfile _guestProfile = const LocalProfile();
  LocalProfile get guestProfile => _guestProfile;

  /// Mantiene [AppUser.current] (leído por Home/Academia/Laboratorio, ver
  /// su doc-comment) al día con quien esté activo ahora — autenticado o
  /// invitado. Única forma en que este archivo toca `AppUser`: nunca un
  /// screen lo hace directo.
  void _syncAppUser() {
    final user = currentUser;
    if (user != null) {
      AppUser.current =
          AppUser(displayName: user.displayName, photoUrl: user.avatarUrl);
    } else if (_state is AuthGuest) {
      final name = _guestProfile.displayName;
      AppUser.current = AppUser(
        displayName: (name == null || name.trim().isEmpty) ? 'Jugador' : name,
        photoUrl: _guestProfile.avatarPath,
      );
    }
  }

  /// Se llama una única vez, al arrancar la app (antes de mostrar
  /// cualquier UI de auth) — evita el flash de la Fase 10.
  Future<void> bootstrap() async {
    _sub = _auth.authStateChanges().listen(_onIdentityChanged);
    final identity = _auth.currentIdentity;
    if (identity != null) {
      await _onIdentityChanged(identity);
    } else {
      // El modo invitado fue eliminado: FLOPly requiere una cuenta.
      // El flag de disco se ignora en adelante — si hubiera uno viejo,
      // el usuario simplemente ve la pantalla de login.
      _state = const AuthUnauthenticated();
      _syncAppUser();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connectivity?.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  /// Devuelve `false` si Firebase Auth confirmó la identidad pero la
  /// sincronización posterior (perfil/progreso) falló — nunca deja el
  /// estado colgado en [AuthLoading]: sin el try/catch, una excepción acá
  /// (red, Firestore no disponible) quedaba sin capturar y la UI se
  /// congelaba en el spinner para siempre, sin mensaje ni forma de
  /// reintentar.
  Future<bool> _onIdentityChanged(AuthIdentity? identity) async {
    _lastIdentity = identity;
    if (identity == null) {
      if (_state is! AuthUnauthenticated) {
        _academyStore = null;
        _state = const AuthUnauthenticated();
        notifyListeners();
      }
      return true;
    }

    // `_run` ya procesa esta MISMA identidad directamente (y espera a que
    // termine antes de devolver el resultado al que llama) — el stream de
    // `authStateChanges` también va a emitir este mismo cambio poco
    // después. Sin esta guarda se reprocesaría dos veces (fetch/save del
    // perfil, reconcile de progreso) para el mismo login — pero solo
    // cuando de verdad no cambió nada: comparar también los proveedores
    // vinculados, no solo el uid, para no ignorar un `linkApple`/
    // `linkGoogle` legítimo sobre una cuenta ya autenticada.
    final current = _state;
    if (current is AuthAuthenticated &&
        current.user.id == identity.uid &&
        current.user.linkedProviders
            .map((p) => p.type)
            .toSet()
            .containsAll(identity.providers)) {
      return true;
    }

    _state = const AuthLoading();
    notifyListeners();

    // Modo offline: un problema de red acá NUNCA debe devolver al usuario
    // a la pantalla de login — Firebase Auth ya confirmó la identidad
    // (viene cacheada del SDK, sin red) y eso alcanza para considerarlo
    // autenticado. Cada paso que sí toca Firestore es best-effort, con su
    // propio fallback, en vez de un único try/catch que tira todo abajo.
    FloplyUser? user;
    try {
      user = await _users.fetch(identity.uid);
    } catch (_) {
      // Sin red y sin nada cacheado todavía de este usuario: seguimos con
      // un perfil mínimo derivado de la identidad (mismo que un login
      // nuevo) en vez de dejar la sesión colgada.
    }
    user = _withCurrentProviders(user ?? _newUserFrom(identity), identity);
    try {
      await _users.save(user);
    } catch (_) {
      // best-effort — el próximo updateDisplayName/updateAvatarPath (o el
      // reintento de reconcile de abajo) lo vuelve a intentar.
    }

    final syncing = SyncingAcademyStore(
      local: _localStoreBuilder(),
      remote: _remoteAcademyStoreBuilder(identity.uid),
    );
    _academyStore = syncing;
    try {
      // Fase 12/13: concilia local (posible uso como invitado) con lo que
      // ya haya en la nube. Si no hay red, queda pendiente
      // (`_pendingReconcile`) — la Academia sigue andando igual: `syncing`
      // ya sirve datos 100% locales mientras tanto (ver su doc-comment),
      // y `_retryReconcile` reintenta sola apenas vuelve la conexión.
      await syncing.reconcile(_registry);
      _pendingReconcile = false;
    } catch (_) {
      _pendingReconcile = true;
    }

    await _flags.setGuestModeChosen(false);
    _state = AuthAuthenticated(user);
    _syncAppUser();
    notifyListeners();
    return true;
  }

  FloplyUser _newUserFrom(AuthIdentity identity) {
    final now = DateTime.now();
    return FloplyUser(
      id: identity.uid,
      createdAt: now,
      updatedAt: now,
      displayName: identity.displayName ?? _fallbackName(identity),
      email: identity.email,
      photoUrl: identity.photoUrl,
      locale: ui.PlatformDispatcher.instance.locale.toString(),
    );
  }

  String _fallbackName(AuthIdentity identity) {
    if (identity.email != null && identity.email!.contains('@')) {
      return identity.email!.split('@').first;
    }
    return 'Jugador';
  }

  FloplyUser _withCurrentProviders(FloplyUser user, AuthIdentity identity) {
    final now = DateTime.now();
    final existing = {for (final p in user.linkedProviders) p.type: p};
    for (final type in identity.providers) {
      existing.putIfAbsent(
        type,
        () => LinkedProvider(
          type: type,
          providerUid: identity.uid,
          email: identity.email,
          linkedAt: now,
        ),
      );
    }
    // Firebase Auth es la fuente de verdad para estos tres campos — se
    // refrescan en cada login (si la identidad no trae alguno, se
    // conserva el que ya había en Firestore como último valor conocido,
    // por eso el `??` mira para el otro lado que en `linkedProviders`).
    return user.copyWith(
      linkedProviders: existing.values.toList(),
      displayName: identity.displayName ?? user.displayName,
      email: identity.email ?? user.email,
      photoUrl: identity.photoUrl ?? user.photoUrl,
      updatedAt: now,
    );
  }

  // ----------------------------------------------------------------
  // Sign-in
  // ----------------------------------------------------------------

  Future<bool> signInWithGoogle() =>
      _run(() => _auth.signInWithGoogle(), AuthProviderType.google);

  Future<bool> signInWithApple() =>
      _run(() => _auth.signInWithApple(), AuthProviderType.apple);

  Future<bool> signInWithEmailPassword(String email, String password) => _run(
        () => _auth.signInWithEmailPassword(email, password),
        AuthProviderType.email,
      );

  /// Envía el SMS de verificación y devuelve el `verificationId` para el
  /// siguiente paso. `null` indica un fallo al enviar.
  Future<String?> sendSmsVerificationCode(String phoneNumber) =>
      _auth.sendSmsVerificationCode(phoneNumber);

  Future<bool> createAccountWithPhone({
    required String name,
    required String email,
    required String password,
    required String phoneVerificationId,
    required String smsCode,
  }) =>
      _run(
        () => _auth.createAccountWithPhone(
          name: name,
          email: email,
          password: password,
          phoneVerificationId: phoneVerificationId,
          smsCode: smsCode,
        ),
        AuthProviderType.phone,
      );

  Future<bool> sendEmailSignInLink(String email) =>
      _run(() => _auth.sendEmailSignInLink(email), AuthProviderType.email);

  bool isEmailSignInLink(String link) => _auth.isEmailSignInLink(link);

  Future<bool> confirmEmailSignInLink({
    required String email,
    required String link,
  }) =>
      _run(
        () => _auth.confirmEmailSignInLink(email: email, link: link),
        AuthProviderType.email,
      );

  // ----------------------------------------------------------------
  // Vinculación (Fase 8) — requiere sesión activa
  // ----------------------------------------------------------------

  Future<bool> linkGoogle() =>
      _run(() => _auth.linkGoogle(), AuthProviderType.google);

  Future<bool> linkApple() =>
      _run(() => _auth.linkApple(), AuthProviderType.apple);

  Future<bool> sendEmailLinkForLinking(String email) =>
      _run(() => _auth.sendEmailLinkForLinking(email), AuthProviderType.email);

  Future<bool> confirmEmailLink({
    required String email,
    required String link,
  }) =>
      _run(
        () => _auth.confirmEmailLink(email: email, link: link),
        AuthProviderType.email,
      );

  Future<void> unlink(AuthProviderType type) async {
    final user = currentUser;
    if (user == null) return;
    await _auth.unlink(type);
    final updated = user.copyWith(
      linkedProviders:
          user.linkedProviders.where((p) => p.type != type).toList(),
    );
    await _users.save(updated);
    _state = AuthAuthenticated(updated);
    notifyListeners();
  }

  Future<bool> reauthenticate(AuthProviderType type) =>
      _run(() => _auth.reauthenticate(type), type);

  // ----------------------------------------------------------------
  // Perfil (Grupo 1 — navegación/perfil/configuración): editar nombre y
  // foto propia sobre el MISMO `FloplyUser`, mismo patrón que [unlink].
  // ----------------------------------------------------------------

  /// Actualiza el nombre visible. No hace nada si no hay sesión — la
  /// pantalla de Perfil llama a [updateGuestDisplayName] en modo invitado.
  Future<void> updateDisplayName(String displayName) async {
    final user = currentUser;
    final trimmed = displayName.trim();
    if (user == null || trimmed.isEmpty) return;
    final updated = user.copyWith(displayName: trimmed, updatedAt: DateTime.now());
    await _users.save(updated);
    _state = AuthAuthenticated(updated);
    _syncAppUser();
    notifyListeners();
  }

  /// Guarda la ruta local de la foto propia (ya copiada a disco por
  /// `pickAndSaveAvatar`) como [FloplyUser.customPhotoUrl] — gana
  /// prioridad sobre `photoUrl` del proveedor sin tocar nada más (ver el
  /// doc-comment de `FloplyUser.avatarUrl`).
  Future<void> updateAvatarPath(String localPath) async {
    final user = currentUser;
    if (user == null) return;
    final updated =
        user.copyWith(customPhotoUrl: localPath, updatedAt: DateTime.now());
    await _users.save(updated);
    _state = AuthAuthenticated(updated);
    _syncAppUser();
    notifyListeners();
  }

  /// Equivalentes de [updateDisplayName]/[updateAvatarPath] para modo
  /// invitado: no hay `FloplyUser`, así que se guardan en [LocalProfile]
  /// (`_profiles`) en vez de Firestore.
  Future<void> updateGuestDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;
    _guestProfile = _guestProfile.copyWith(displayName: trimmed);
    await _profiles.save(_guestProfile);
    _syncAppUser();
    notifyListeners();
  }

  Future<void> updateGuestAvatarPath(String localPath) async {
    _guestProfile = _guestProfile.copyWith(avatarPath: localPath);
    await _profiles.save(_guestProfile);
    _syncAppUser();
    notifyListeners();
  }

  /// Ejecuta un intento de auth/link y traduce el resultado a estado —
  /// único lugar que sabe interpretar [AuthAttemptResult] (Fase 9/23).
  Future<bool> _run(
    Future<AuthAttemptResult> Function() action,
    AuthProviderType provider,
  ) async {
    _pendingConflict = null;
    _lastFailure = null;
    final result = await action();
    switch (result) {
      case AuthAttemptSuccess(:final identity):
        // Se procesa DIRECTO acá (no se espera a que llegue por
        // authStateChanges) para que, cuando esto devuelve, `state` ya
        // sea el definitivo — quien llama (UI o tests) no debe adivinar
        // cuándo terminó de resolverse. authStateChanges también va a
        // emitir este mismo cambio; `_onIdentityChanged` lo ignora si ya
        // está procesado (ver la guarda ahí).
        final ok = identity == null || await _onIdentityChanged(identity);
        notifyListeners();
        return ok;
      case AuthAttemptCancelled():
        return false;
      case AuthAttemptConflict(:final provider, :final existingEmail):
        _pendingConflict = AccountConflict(
            attemptedProvider: provider, existingEmail: existingEmail);
        notifyListeners();
        return false;
      case AuthAttemptFailure(:final reason):
        _lastFailure = reason;
        notifyListeners();
        return false;
    }
  }

  void dismissConflict() {
    _pendingConflict = null;
    notifyListeners();
  }

  void clearLastFailure() {
    _lastFailure = null;
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // Logout / borrado (Fase 16/17)
  // ----------------------------------------------------------------

  /// Cierra sesión: limpia credenciales locales, NUNCA borra datos
  /// remotos. El progreso ya sincronizado sigue en la nube, listo para el
  /// próximo login.
  Future<void> signOut() async {
    await _auth.signOut();
    // _onIdentityChanged(null) hace el resto (estado -> unauthenticated).
  }

  /// Elimina la cuenta: perfil + progreso remoto + identidad del
  /// proveedor. Acción real, no un simple "ocultar" — ver `AUTH_SETUP.md`
  /// sobre la política de borrado.
  Future<bool> deleteAccount() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      await _users.delete(user.id);
      await _remoteAcademyStoreBuilder(user.id).clear();
      await _auth.deleteAuthAccount();
      return true;
    } catch (_) {
      _lastFailure = AuthFailureReason.reauthenticationRequired;
      notifyListeners();
      return false;
    }
  }
}

typedef RemoteAcademyStoreBuilder = AcademyStore Function(String uid);

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/auth/auth_controller.dart';
import 'package:poker_trainer/auth/auth_repository.dart';
import 'package:poker_trainer/auth/fake_auth_repository.dart';
import 'package:poker_trainer/auth/fake_user_repository.dart';
import 'package:poker_trainer/auth/models/auth_identity.dart';
import 'package:poker_trainer/auth/models/auth_provider_type.dart';
import 'package:poker_trainer/auth/models/auth_state.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/persistence/local_auth_flag_store.dart';

final _registry = ConceptRegistry.standard();
UserKnowledge _emptyKnowledge() => UserKnowledge(_registry);

/// Arma un [AuthController] con todas sus dependencias en memoria — mismo
/// nivel de fidelidad que `InMemoryAcademyStore` para `AcademyController`:
/// no hay forma de ejecutar un login real acá, así que la orquestación se
/// prueba contra dobles explícitos.
class _Harness {
  _Harness()
      : auth = FakeAuthRepository(),
        users = FakeUserRepository(),
        flags = InMemoryAuthFlagStore(),
        _sharedLocal = InMemoryAcademyStore(),
        _remotesByUid = {};

  final FakeAuthRepository auth;
  final FakeUserRepository users;
  final InMemoryAuthFlagStore flags;
  final InMemoryAcademyStore _sharedLocal;
  final Map<String, InMemoryAcademyStore> _remotesByUid;

  AcademyStore remoteFor(String uid) =>
      _remotesByUid.putIfAbsent(uid, () => InMemoryAcademyStore());

  AuthController build() => AuthController(
        authRepository: auth,
        userRepository: users,
        flagStore: flags,
        localStoreBuilder: () => _sharedLocal,
        remoteAcademyStoreBuilder: remoteFor,
      );

  AuthIdentity identity({
    String uid = 'uid-1',
    Set<AuthProviderType> providers = const {AuthProviderType.google},
    String? email = 'jugador@example.com',
    String? displayName = 'Jugador',
    String? photoUrl,
    bool emailVerified = false,
  }) =>
      AuthIdentity(
        uid: uid,
        providers: providers,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        emailVerified: emailVerified,
      );
}

void main() {
  group('creación / login', () {
    test('signInWithGoogle crea una FloplyUser nueva la primera vez', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();
      expect(controller.state, isA<AuthUnauthenticated>());

      h.auth.queueSuccess(h.identity());
      final ok = await controller.signInWithGoogle();

      expect(ok, isTrue);
      final state = controller.state;
      expect(state, isA<AuthAuthenticated>());
      final user = (state as AuthAuthenticated).user;
      expect(user.id, 'uid-1');
      expect(user.hasProvider(AuthProviderType.google), isTrue);
    });

    test(
        'si falla la sincronización de perfil después de un login exitoso '
        '(Firestore caído), no queda colgado en AuthLoading: vuelve a '
        'Unauthenticated con lastFailure seteado', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();

      h.users.throwOnFetch = true;
      h.auth.queueSuccess(h.identity());
      final ok = await controller.signInWithGoogle();

      expect(ok, isFalse);
      expect(controller.state, isA<AuthUnauthenticated>());
      expect(controller.lastFailure, AuthFailureReason.network);
    });

    test(
        'Firebase Auth es la fuente de verdad: photoURL/displayName '
        'llegan de la identidad en el primer login', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();

      h.auth.queueSuccess(h.identity(
        displayName: 'Juan G.',
        photoUrl: 'https://google/foto-1.png',
      ));
      await controller.signInWithGoogle();

      final user = controller.currentUser!;
      expect(user.displayName, 'Juan G.');
      expect(user.photoUrl, 'https://google/foto-1.png');
      expect(user.avatarUrl, 'https://google/foto-1.png');
    });

    test(
        'si la foto de Google cambia, el próximo login la refresca en vez '
        'de dejar la vieja congelada en Firestore', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();

      h.auth.queueSuccess(
          h.identity(photoUrl: 'https://google/foto-vieja.png'));
      await controller.signInWithGoogle();
      await controller.signOut();

      h.auth
          .queueSuccess(h.identity(photoUrl: 'https://google/foto-nueva.png'));
      await controller.signInWithGoogle();

      expect(controller.currentUser!.photoUrl, 'https://google/foto-nueva.png');
    });

    test(
        'isEmailVerified refleja la identidad viva de Firebase Auth, no '
        'algo persistido', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();
      expect(controller.isEmailVerified, isFalse);

      h.auth.queueSuccess(h.identity(emailVerified: true));
      await controller.signInWithGoogle();

      expect(controller.isEmailVerified, isTrue);
    });

    test(
        'login con una identidad ya conocida reutiliza la misma '
        'FloplyUser (no crea una segunda cuenta)', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();

      h.auth.queueSuccess(h.identity());
      await controller.signInWithGoogle();
      final firstId = controller.currentUser!.id;
      await controller.signOut();

      h.auth.queueSuccess(h.identity()); // mismo uid
      await controller.signInWithGoogle();

      expect(controller.currentUser!.id, firstId);
    });

    test('signInWithApple también resuelve a AuthAuthenticated', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();

      h.auth.queueSuccess(h.identity(
          uid: 'uid-apple', providers: {AuthProviderType.apple}, email: null));
      final ok = await controller.signInWithApple();

      expect(ok, isTrue);
      expect(
          controller.currentUser!.hasProvider(AuthProviderType.apple), isTrue);
    });

    test(
        'email: sendEmailSignInLink + confirmEmailSignInLink completan el '
        'acceso', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();

      h.auth.queue(const AuthAttemptSuccess());
      final sent = await controller.sendEmailSignInLink('jugador@example.com');
      expect(sent, isTrue);
      expect(controller.state, isA<AuthUnauthenticated>());

      h.auth.queueSuccess(
          h.identity(uid: 'uid-email', providers: {AuthProviderType.email}));
      final confirmed = await controller.confirmEmailSignInLink(
          email: 'jugador@example.com', link: 'flopy-email-link:xyz');

      expect(confirmed, isTrue);
      expect(controller.state, isA<AuthAuthenticated>());
    });
  });

  group('sesión persistente (Fase 10)', () {
    test(
        'bootstrap() con una sesión ya activa resuelve directo a '
        'AuthAuthenticated, nunca pasa por Unauthenticated', () async {
      final h = _Harness();
      // Simula "la app se reabre": el repo ya tiene una identidad actual.
      h.auth.queueSuccess(h.identity());
      await h.auth.signInWithGoogle();

      final controller = h.build();
      final states = <Type>[];
      controller.addListener(() => states.add(controller.state.runtimeType));
      await controller.bootstrap();

      expect(controller.state, isA<AuthAuthenticated>());
      expect(states, isNot(contains(AuthUnauthenticated)));
    });

    test(
        'invitado: continueAsGuest() persiste y bootstrap() posterior '
        'respeta el flag sin volver a preguntar', () async {
      final h = _Harness();
      final first = h.build();
      await first.bootstrap();
      await first.continueAsGuest();
      expect(first.state, isA<AuthGuest>());

      // "reabrir la app": nuevo controller, mismo flagStore.
      final second = h.build();
      await second.bootstrap();
      expect(second.state, isA<AuthGuest>());
    });
  });

  group('vinculación (Fase 8)', () {
    test(
        'linkApple agrega Apple a los métodos de una cuenta ya logueada '
        'con Google', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();
      h.auth.queueSuccess(h.identity());
      await controller.signInWithGoogle();

      h.auth.queueSuccess(h.identity(providers: {
        AuthProviderType.google,
        AuthProviderType.apple,
      }));
      final ok = await controller.linkApple();

      expect(ok, isTrue);
      final user = controller.currentUser!;
      expect(user.hasProvider(AuthProviderType.google), isTrue);
      expect(user.hasProvider(AuthProviderType.apple), isTrue);
      expect(user.id, 'uid-1'); // sigue siendo la MISMA cuenta
    });

    test('unlink quita un método sin tocar los demás', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();
      h.auth.queueSuccess(h.identity(providers: {
        AuthProviderType.google,
        AuthProviderType.apple,
      }));
      await controller.signInWithGoogle();

      await controller.unlink(AuthProviderType.apple);

      final user = controller.currentUser!;
      expect(user.hasProvider(AuthProviderType.apple), isFalse);
      expect(user.hasProvider(AuthProviderType.google), isTrue);
    });
  });

  group('conflicto de cuentas (Fase 9)', () {
    test(
        'un intento que devuelve conflicto no autentica y expone '
        'pendingConflict — no fusiona nada solo', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();

      h.auth.queue(const AuthAttemptConflict(
        provider: AuthProviderType.apple,
        existingEmail: 'jugador@example.com',
      ));
      final ok = await controller.linkApple();

      expect(ok, isFalse);
      expect(controller.state, isA<AuthUnauthenticated>());
      expect(controller.pendingConflict, isNotNull);
      expect(controller.pendingConflict!.attemptedProvider,
          AuthProviderType.apple);
    });
  });

  group('logout / eliminación (Fase 16/17)', () {
    test(
        'signOut limpia la sesión pero NO borra el perfil ni el progreso '
        'remoto', () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();
      h.auth.queueSuccess(h.identity());
      await controller.signInWithGoogle();
      final uid = controller.currentUser!.id;

      await controller.signOut();

      expect(controller.state, isA<AuthUnauthenticated>());
      expect(await h.users.fetch(uid), isNotNull); // el perfil sigue ahí
    });

    test('deleteAccount borra perfil y progreso remoto, y cierra sesión',
        () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();
      h.auth.queueSuccess(h.identity());
      await controller.signInWithGoogle();
      final uid = controller.currentUser!.id;

      final ok = await controller.deleteAccount();

      expect(ok, isTrue);
      expect(await h.users.fetch(uid), isNull);
      expect(controller.state, isA<AuthUnauthenticated>());
    });
  });

  group('migración de progreso (Fase 12/13)', () {
    test('progreso guardado como invitado aparece al crear la cuenta',
        () async {
      final h = _Harness();
      final controller = h.build();
      await controller.bootstrap();
      await controller.continueAsGuest();

      // Progreso "como invitado": se guarda en el store local compartido.
      await controller.academyStore.save(AcademySaveData(
        knowledge: _emptyKnowledge(),
        progress: AcademyProgress()..entry('1.1').completed = true,
      ));

      h.auth.queueSuccess(h.identity());
      await controller.signInWithGoogle();

      final data = await controller.academyStore.load(_registry);
      expect(data!.progress.isCompleted('1.1'), isTrue);
    });

    test(
        'sincronización entre dispositivos: login en un 2do controller '
        'con la misma cuenta ve el progreso ya subido', () async {
      final h = _Harness();
      final deviceA = h.build();
      await deviceA.bootstrap();
      h.auth.queueSuccess(h.identity());
      await deviceA.signInWithGoogle();
      await deviceA.academyStore.save(AcademySaveData(
        knowledge: _emptyKnowledge(),
        progress: AcademyProgress()..entry('3.1').completed = true,
      ));

      // "Otro dispositivo": mismo backend remoto (mismo _Harness/uid), pero
      // su propio local vacío — como un teléfono que nunca usó la app.
      final auth2 = FakeAuthRepository();
      final deviceB = AuthController(
        authRepository: auth2,
        userRepository: h.users,
        flagStore: InMemoryAuthFlagStore(),
        localStoreBuilder: () => InMemoryAcademyStore(),
        remoteAcademyStoreBuilder: h.remoteFor,
      );
      await deviceB.bootstrap();
      auth2.queueSuccess(h.identity());
      await deviceB.signInWithGoogle();

      final data = await deviceB.academyStore.load(_registry);
      expect(data!.progress.isCompleted('3.1'), isTrue);
    });
  });
}

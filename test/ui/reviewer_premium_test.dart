import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/auth/fake_auth_repository.dart';
import 'package:poker_trainer/auth/models/auth_identity.dart';
import 'package:poker_trainer/auth/models/auth_provider_type.dart';
import 'package:poker_trainer/services/premium/reviewer_claims_service.dart';

void main() {
  group('ReviewerClaimsService', () {
    late FakeAuthRepository fakeAuth;
    late ReviewerClaimsService service;

    setUp(() {
      fakeAuth = FakeAuthRepository();
      service = ReviewerClaimsService(fakeAuth);
    });

    tearDown(() => fakeAuth.dispose());

    test('isReviewer es false por defecto (sin usuario)', () async {
      await service.onUserChanged(null);
      expect(service.isReviewer, isFalse);
    });

    test('isReviewer es false para usuario normal', () async {
      fakeAuth.reviewerForTest = false;
      await service.onUserChanged('uid-normal-user');
      expect(service.isReviewer, isFalse);
    });

    test('isReviewer es true cuando el claim está activo', () async {
      fakeAuth.reviewerForTest = true;
      await service.onUserChanged('uid-reviewer');
      expect(service.isReviewer, isTrue);
    });

    test('isReviewer vuelve a false al hacer logout', () async {
      fakeAuth.reviewerForTest = true;
      await service.onUserChanged('uid-reviewer');
      expect(service.isReviewer, isTrue);

      fakeAuth.reviewerForTest = false;
      await service.onUserChanged(null);
      expect(service.isReviewer, isFalse);
    });

    test('notifica listeners cuando el estado cambia', () async {
      var notified = 0;
      service.addListener(() => notified++);

      fakeAuth.reviewerForTest = true;
      await service.onUserChanged('uid-reviewer');
      expect(notified, 1);

      // Sin cambio de estado → no notifica
      await service.onUserChanged('uid-reviewer');
      expect(notified, 1);

      // Logout → sí notifica
      fakeAuth.reviewerForTest = false;
      await service.onUserChanged(null);
      expect(notified, 2);
    });
  });

  group('FakeAuthRepository.isReviewerAccount', () {
    test('devuelve false por defecto', () async {
      final auth = FakeAuthRepository();
      expect(await auth.isReviewerAccount(), isFalse);
      auth.dispose();
    });

    test('devuelve true cuando reviewerForTest = true', () async {
      final auth = FakeAuthRepository();
      auth.reviewerForTest = true;
      expect(await auth.isReviewerAccount(), isTrue);
      auth.dispose();
    });

    test('usuario normal no obtiene isPremium reviewer', () async {
      // Verifica que el mecanismo no puede ser activado desde el cliente:
      // solo el test puede setearlo mediante el setter de test. En
      // producción solo el Admin SDK puede cambiar el custom claim.
      final auth = FakeAuthRepository();
      auth.queueSuccess(const AuthIdentity(
        uid: 'uid-normal',
        providers: {AuthProviderType.email},
        displayName: 'Normal User',
      ));
      await auth.signInWithEmailPassword('user@example.com', 'pass123');
      // Sin llamar reviewerForTest, sigue siendo false
      expect(await auth.isReviewerAccount(), isFalse);
      auth.dispose();
    });
  });
}

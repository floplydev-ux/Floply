import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/auth/auth_controller.dart';
import 'package:poker_trainer/auth/fake_auth_repository.dart';
import 'package:poker_trainer/auth/fake_user_repository.dart';
import 'package:poker_trainer/auth/models/auth_identity.dart';
import 'package:poker_trainer/auth/models/auth_provider_type.dart';
import 'package:poker_trainer/auth/widgets/auth_gate.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/local_auth_flag_store.dart';
import 'package:poker_trainer/services/premium/premium_service.dart';
import 'package:poker_trainer/widgets/bottom_navigation.dart';

({AuthController controller, FakeAuthRepository auth}) _harness() {
  final auth = FakeAuthRepository();
  final controller = AuthController(
    authRepository: auth,
    userRepository: FakeUserRepository(),
    flagStore: InMemoryAuthFlagStore(),
    localStoreBuilder: () => InMemoryAcademyStore(),
    remoteAcademyStoreBuilder: (_) => InMemoryAcademyStore(),
  );
  return (controller: controller, auth: auth);
}

void main() {
  testWidgets(
      '390dp: arranca en AuthScreen (sin flash) y "continuar sin cuenta" '
      'entra directo a la app', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = _harness().controller;
    await tester
        .pumpWidget(MaterialApp(home: AuthGate(controller: controller, premium: StubPremiumService())));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.authContinueGoogle), findsOneWidget);
    expect(find.text(AppStrings.authContinueApple), findsOneWidget);
    expect(find.text(AppStrings.authContinueEmail), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.authContinueWithoutAccount));
    await tester.pumpAndSettle();

    // Ya adentro de la app: la navegación inferior está visible.
    expect(find.byType(AppBottomNavigation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signInWithGoogle exitoso navega de AuthScreen a la app',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final h = _harness();
    final controller = h.controller;
    h.auth.queueSuccess(const AuthIdentity(
      uid: 'uid-1',
      providers: {AuthProviderType.google},
      displayName: 'Jugador',
      email: 'jugador@example.com',
    ));

    await tester
        .pumpWidget(MaterialApp(home: AuthGate(controller: controller, premium: StubPremiumService())));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authContinueGoogle));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNavigation), findsOneWidget);
    expect(find.text(AppStrings.authContinueGoogle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

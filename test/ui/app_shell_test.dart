import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/auth/auth_controller.dart';
import 'package:poker_trainer/auth/fake_auth_repository.dart';
import 'package:poker_trainer/auth/fake_user_repository.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/local_auth_flag_store.dart';
import 'package:poker_trainer/screens/root/app_shell.dart';

Widget _harness() => MaterialApp(
      home: AppShell(
        academyStore: InMemoryAcademyStore(),
        authController: AuthController(
          authRepository: FakeAuthRepository(),
          userRepository: FakeUserRepository(),
          flagStore: InMemoryAuthFlagStore(),
          localStoreBuilder: () => InMemoryAcademyStore(),
          remoteAcademyStoreBuilder: (_) => InMemoryAcademyStore(),
        ),
      ),
    );

/// Contrato de producto (eliminación de "Ayuda rápida"): el FAB persistente
/// de `AppShell` ya no existe en ninguna pestaña. Reemplaza a los tests que
/// antes verificaban que el FAB abría Table Mode.
void main() {
  testWidgets('no existe ningún FloatingActionButton en Home', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('no existe ningún FloatingActionButton al cambiar de pestaña '
      '(Academia)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.navAcademy.toUpperCase()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}

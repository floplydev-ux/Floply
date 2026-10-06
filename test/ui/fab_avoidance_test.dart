import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/auth/auth_controller.dart';
import 'package:poker_trainer/auth/fake_auth_repository.dart';
import 'package:poker_trainer/auth/fake_user_repository.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/local_auth_flag_store.dart';
import 'package:poker_trainer/screens/root/app_shell.dart';
import 'package:poker_trainer/services/premium/premium_service.dart';
import 'package:poker_trainer/widgets/bottom_navigation.dart';

import '../support/responsive_widths.dart';

/// Contrato de producto (eliminación de "Ayuda rápida"): el FAB persistente
/// de [AppShell] que antes interceptaba el tap sobre RAISE en Laboratorio
/// (BUG-001, `FLOPLY_HUMAN_QA_PHASE4_5_2026-09-19.md`) ya no existe. Este
/// archivo verifica que ya no hay ningún FAB Y que FOLD/CALL/RAISE siguen
/// funcionando en distintos anchos de teléfono — la regresión que
/// realmente importa ahora que la causa original (el FAB) desapareció.
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
        premium: StubPremiumService(),
      ),
    );

/// El tab "LABORATORIO" de la bottom nav — acotado a
/// [AppBottomNavigation] porque, una vez dentro de un ejercicio, el propio
/// encabezado (`_LabHeader`) repite el texto "LABORATORIO" y un
/// `find.text` sin acotar queda ambiguo.
Finder _labTab() => find.descendant(
      of: find.byType(AppBottomNavigation),
      matching: find.text(AppStrings.navLab.toUpperCase()),
    );

/// Deja el `tester` parado en la pantalla de Home/AppShell recién montada,
/// sobre el tab de Laboratorio (todavía sin tocarlo).
///
/// [width] default (360) es el ancho de teléfono real usado en todas las
/// fases de verificación en vivo con Marionette.
Future<void> _pumpShell(WidgetTester tester, {double width = 360.0}) async {
  setResponsiveWidth(tester, width, height: 800.0);
  await tester.pumpWidget(_harness());
  await tester.pumpAndSettle();
  await tester.tap(_labTab());
  await tester.pumpAndSettle();
}

/// Desde la pantalla de Laboratorio (idle o ya en un ejercicio anterior),
/// arranca un ejercicio nuevo en FÁCIL — siempre `openRaise`: héroe en
/// BTN, pote sin abrir, 100bb, así que FOLD/CALL/RAISE son las 3 acciones
/// siempre legales de esa decisión (`ExerciseScenarioBuilder.openRaise` +
/// `LegalActionEngine`). Si ya había un ejercicio en curso, sale primero
/// (botón "×" del encabezado) para volver al selector de dificultad.
Future<void> _startEasyExercise(WidgetTester tester) async {
  final exitButton = find.byTooltip(AppStrings.labExitTooltip);
  if (exitButton.evaluate().isNotEmpty) {
    await tester.tap(exitButton);
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text('FÁCIL'));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.text('FOLD'), findsOneWidget);
  expect(find.text('CALL'), findsOneWidget);
  expect(find.text('RAISE'), findsOneWidget,
      reason: 'un openRaise sin abrir siempre ofrece abrir como una de '
          'las 3 acciones legales');
}

/// Combina [_pumpShell] + [_startEasyExercise] para los tests que solo
/// necesitan un ejercicio, una vez.
Future<void> _enterEasyLabExercise(WidgetTester tester, {double width = 360.0}) async {
  await _pumpShell(tester, width: width);
  await _startEasyExercise(tester);
}

void main() {
  group('Ayuda rápida eliminada — Laboratorio sin FAB', () {
    testWidgets('no existe ningún FAB en un ejercicio de Laboratorio',
        (tester) async {
      await _enterEasyLabExercise(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('tocar RAISE registra la decisión real', (tester) async {
      await _enterEasyLabExercise(tester);

      await tester.tap(find.text('RAISE'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // La decisión sí avanzó de verdad: la fila de elegir acción (con
      // "FOLD" como una de sus opciones) ya no está en pantalla —
      // reemplazada por el paso de tamaño o por la devolución.
      expect(find.text('FOLD'), findsNothing);
    });

    testWidgets('tocar RAISE dos veces seguidas (dos ejercicios distintos) '
        'es reproducible, no un golpe de suerte', (tester) async {
      for (var i = 0; i < 2; i++) {
        await _enterEasyLabExercise(tester);
        await tester.tap(find.text('RAISE'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('FOLD'), findsNothing);
      }
    });

    testWidgets('FOLD funciona', (tester) async {
      await _enterEasyLabExercise(tester);

      await tester.tap(find.text('FOLD'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // FOLD nunca necesita tamaño ni tiene paso de razonamiento en
      // Laboratorio — resuelve directo a la devolución estructurada
      // (ver `LabFeedbackBuilder`/`_RichFeedbackBody`), que siempre
      // muestra la acción esperada en su sección DECISIÓN.
      expect(find.textContaining('Esperado:'), findsOneWidget);
    });

    testWidgets('CALL funciona', (tester) async {
      await _enterEasyLabExercise(tester);

      await tester.tap(find.text('CALL'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('FOLD'), findsNothing);
    });

    for (final width in kResponsivePhoneWidths) {
      testWidgets('RAISE recibe el tap a ${width.toInt()}px de ancho, sin '
          'FAB en pantalla', (tester) async {
        await _enterEasyLabExercise(tester, width: width);

        expect(find.byType(FloatingActionButton), findsNothing);

        await tester.tap(find.text('RAISE'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('FOLD'), findsNothing);
      });
    }
  });
}

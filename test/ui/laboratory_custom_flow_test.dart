import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';
import 'package:poker_trainer/screens/laboratory/laboratory_screen.dart';

/// Fase 8 — recorrido real de UI del modo Custom, sobre la pantalla de
/// PRODUCCIÓN (`LaboratoryScreen`), no un harness aislado. Complementa
/// `laboratory_custom_test.dart` (motor/controller): acá se valida que
/// el flujo de la UI (tocar CUSTOM, elegir áreas, elegir cantidad,
/// COMENZAR) realmente llega al controller con los datos correctos.
Future<LabSessionController> _pumpLab(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final controller = LabSessionController(engine: PokerTrainerEngine(seed: 8));
  addTearDown(controller.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: LaboratoryScreen(controller: controller)),
  ));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  group('Custom aparece y abre la configuración (Fase 8)', () {
    testWidgets('CUSTOM está en la entrada y abre el selector', (tester) async {
      final controller = await _pumpLab(tester);

      await tester.ensureVisible(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.labCustomLabel), findsOneWidget);

      await tester.tap(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.labCustomHeaderTitle), findsOneWidget);
      expect(find.text(AppStrings.labCustomAreasHeader), findsOneWidget);
      // Sigue en idle — abrir el selector no arranca ninguna sesión.
      expect(controller.phase, LabPhase.idle);
    });

    testWidgets('ATRÁS desde el selector vuelve a la lista sin arrancar nada',
        (tester) async {
      final controller = await _pumpLab(tester);
      await tester.ensureVisible(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.labChooseTitle), findsOneWidget);
      expect(controller.phase, LabPhase.idle);
      expect(controller.activeCustomScenarioKinds, isNull);
    });
  });

  group('Selección vacía no arranca (Fase 8, Sección 18)', () {
    testWidgets('sin ninguna área elegida, COMENZAR está deshabilitado y '
        'muestra el hint', (tester) async {
      final controller = await _pumpLab(tester);
      await tester.ensureVisible(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.labCustomEmptyHint), findsOneWidget);
      await tester.ensureVisible(find.text(AppStrings.labCustomStart));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.labCustomStart));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // No pasó nada: seguimos en idle, el controller nunca arrancó.
      expect(controller.phase, LabPhase.idle);
    });
  });

  group('Selección múltiple funciona (Fase 8, Sección 16/45)', () {
    testWidgets('elegir 2 áreas + cantidad e iniciar arranca con exactamente '
        'esas 2 y esa cantidad', (tester) async {
      final controller = await _pumpLab(tester);
      await tester.ensureVisible(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.labCustomLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Raise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3-Bet'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.labCustomSummary(2, 10)), findsOneWidget,
          reason: '10 es el default de cantidad');

      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.labCustomSummary(2, 20)), findsOneWidget);

      await tester.ensureVisible(find.text(AppStrings.labCustomStart));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.labCustomStart));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.phase, LabPhase.question);
      expect(controller.sessionLength, 20);
      expect(
        controller.activeCustomScenarioKinds!.toSet(),
        {PreflopScenarioKind.openRaise, PreflopScenarioKind.threeBet},
      );
      // Y el ejercicio que efectivamente cargó pertenece al conjunto
      // elegido — no a cualquiera de las 6 familias.
      expect(
        {PreflopScenarioKind.openRaise, PreflopScenarioKind.threeBet},
        contains(controller.newEngineScenario!.objective),
      );
    });
  });
}

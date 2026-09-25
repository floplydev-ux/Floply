import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/stats/stats_screen.dart';

Future<AcademyController> _loadedController() async {
  final controller = AcademyController(
    engine: PokerTrainerEngine(seed: 1),
    store: InMemoryAcademyStore(),
  );
  await controller.load();
  return controller;
}

Widget _harness(AcademyController controller) =>
    MaterialApp(home: StatsScreen(controller: controller));

void main() {
  testWidgets('muestra el progreso real de Academia: nivel, % y niveles',
      (tester) async {
    final controller = await _loadedController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.statsHeaderTitle), findsOneWidget);
    expect(find.text(AppStrings.statsAcademySection), findsOneWidget);
    expect(find.text(AppStrings.statsLevelsSection), findsOneWidget);

    final snapshot = controller.snapshot;
    expect(
      find.text(AppStrings.academyLevelLabel(
          snapshot.currentLevelNumber, snapshot.currentLevelTitle)),
      findsOneWidget,
    );
    // Los 13 niveles del currículo, uno por fila.
    expect(find.text(controller.levels.first.level.title), findsOneWidget);
    expect(find.text(controller.levels.last.level.title), findsOneWidget);
  });

  testWidgets('usuario nuevo: dominio por concepto vacío, sin inventar datos',
      (tester) async {
    final controller = await _loadedController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.statsConceptMasteryEmpty), findsOneWidget);
  });

  testWidgets(
      'con un concepto enseñado y practicado, aparece su barra de dominio',
      (tester) async {
    final controller = await _loadedController();
    // Simula lo que Academia haría al enseñar y evaluar un concepto real
    // — mismo UserKnowledge que ya usa el resto de la app, sin atajos.
    controller.knowledge.teach(ConceptIds.openingRange);
    controller.knowledge.recordAttempt(ConceptIds.openingRange, decisionCorrect: true);

    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.statsConceptMasteryEmpty), findsNothing);
    expect(
      find.text(controller.engine.concepts.byId(ConceptIds.openingRange).name),
      findsOneWidget,
    );
  });

  testWidgets(
      'Laboratorio muestra el estado vacío honesto (no hay historial persistido)',
      (tester) async {
    final controller = await _loadedController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.statsLabSection), findsOneWidget);
    expect(find.text(AppStrings.statsLabEmptyTitle), findsOneWidget);
  });

  testWidgets('responsive: sin overflow en anchos chicos y grandes',
      (tester) async {
    final controller = await _loadedController();
    controller.knowledge.teach(ConceptIds.openingRange);
    controller.knowledge.recordAttempt(ConceptIds.openingRange, decisionCorrect: true);

    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '${size.width}x${size.height}');
    }
  });
}

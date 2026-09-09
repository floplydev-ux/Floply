import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

void main() {
  testWidgets('la Academia abre, muestra el mapa y entra a un lesson',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = AcademyController(
      engine: PokerTrainerEngine(seed: 1),
      store: InMemoryAcademyStore(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ACADEMIA'), findsOneWidget);
    expect(find.text('FUNDAMENTOS'), findsOneWidget);

    // Abrir el primer lesson: es una lección interactiva sobre la mesa.
    await tester.tap(find.textContaining('Cómo se juega una mano').first);
    await tester.pumpAndSettle();

    expect(controller.phase, AcademyPhase.theory);
    expect(controller.isInteractiveTheory, isTrue);
    expect(find.text('1 / ${controller.tableStepCount}'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Avanzar un paso y volver.
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(controller.tableStep, 1);
    expect(find.text('ATRÁS'), findsOneWidget);

    await tester.tap(find.text('ATRÁS'));
    await tester.pumpAndSettle();
    expect(controller.tableStep, 0);

    // Recorrer el resto de los pasos.
    while (!controller.isLastTableStep) {
      controller.nextTableStep();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('PRACTICAR'), findsOneWidget);
    await tester.tap(find.text('PRACTICAR'));
    await tester.pumpAndSettle();
    expect(controller.phase, AcademyPhase.exercise);

    // El ejercicio también es interactivo sobre la mesa: elegir una opción.
    expect(controller.isInteractiveExercise, isTrue);
    final ex = controller.currentInteractive!;
    expect(find.text(controller.interactiveQuestionText!), findsOneWidget);
    await tester.tap(find.text(controller.resolveInteractive(ex.choices[ex.bestChoiceIndex].label)));
    await tester.pumpAndSettle();
    expect(controller.interactiveChoice, ex.bestChoiceIndex);
    expect(find.textContaining('CORRECTO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

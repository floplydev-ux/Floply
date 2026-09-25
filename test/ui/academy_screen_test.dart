import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
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
    await controller.load();
    // N1.1 y N1.2 son ambos: piloto de 3 bloques (teoría escrita → ejemplo
    // de mesa → ejercicios), sin guion de mesa legado ni clase de mentor.
    controller.progress = AcademyProgress()..entry('1.1').completed = true;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ACADEMIA'), findsOneWidget);
    expect(find.textContaining('Cómo funciona una mano'), findsWidgets);

    // Abrir un subnivel: ficha de teoría escrita primero (sin mesa).
    await tester.tap(find.textContaining('Ganar la mano').first);
    await tester.pumpAndSettle();

    expect(controller.phase, AcademyPhase.theory);
    expect(controller.isWrittenTheory, isTrue);
    expect(controller.isInteractiveTheory, isFalse);
    expect(find.text('CONTINUAR'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Avanzar un paso y volver.
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(controller.writtenTheoryStep, 1);
    expect(find.text('ATRÁS'), findsOneWidget);

    await tester.tap(find.text('ATRÁS'));
    await tester.pumpAndSettle();
    expect(controller.writtenTheoryStep, 0);

    // Recorrer el resto de las fichas de teoría escrita.
    while (controller.isWrittenTheory) {
      controller.nextWrittenTheory();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    // Tras la teoría viene el ejemplo de cierre (mesa + highlights, texto
    // siempre en el panel debajo, nunca en burbuja).
    expect(controller.isClosingExample, isTrue);
    var exampleGuard = 0;
    while (controller.isClosingExample && exampleGuard++ < 15) {
      final label = controller.closingExampleButtonLabel;
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
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

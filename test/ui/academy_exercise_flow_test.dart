import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

void main() {
  // Anchos representativos de celulares (dp lógicos).
  for (final width in <double>[320, 360, 390, 430]) {
    testWidgets('$width dp — la Academia recorre todo el currículo sin '
        'overflow ni excepciones', (tester) async {
      tester.view.physicalSize = Size(width * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final controller = AcademyController(
        engine: PokerTrainerEngine(seed: 5),
        store: InMemoryAcademyStore(),
      );
      await controller.load();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AcademyScreen(controller: controller)),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'mapa a $width dp');

      for (final lessonId in Curriculum.lessonOrder) {
        controller.openLesson(lessonId);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'abrir $lessonId');

        if (controller.phase == AcademyPhase.theory) {
          controller.startExercises();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'teoría→ejercicio $lessonId');
        }

        while (controller.phase == AcademyPhase.exercise ||
            controller.phase == AcademyPhase.feedback) {
          if (controller.phase == AcademyPhase.exercise) {
            final item = controller.currentItem!;
            if (item.isInteractive) {
              controller.answerInteractive(item.interactive!.bestChoiceIndex);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull,
                  reason: 'interactivo $lessonId respuesta');
              controller.advanceInteractive();
              await tester.pumpAndSettle();
              continue;
            }
            int choice;
            if (item.isEngine) {
              final ex = item.exercise!;
              final best = ex.strategy.primary;
              choice = ex.options.indexWhere(
                (o) =>
                    (o.action != null && o.action!.matches(best.action)) ||
                    (ex.correctValue != null && o.value == ex.correctValue),
              );
              if (choice < 0) choice = 0;
            } else {
              choice = item.check!.correctIndex;
            }
            controller.toggleOption(choice);
            await tester.pumpAndSettle();
            controller.confirm();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'feedback $lessonId #${controller.itemNumber}');
          } else {
            controller.nextItem();
            await tester.pumpAndSettle();
          }
        }

        expect(controller.phase, AcademyPhase.result, reason: lessonId);
        expect(tester.takeException(), isNull, reason: 'resultado $lessonId');
        controller.exitLesson();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('la evaluación desaprobada muestra recuperación sin overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = AcademyController(
      engine: PokerTrainerEngine(seed: 2),
      store: InMemoryAcademyStore(),
    );
    await controller.load();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: controller)),
    ));

    int bestOf(AcademyItem it) => it.isInteractive
        ? it.interactive!.bestChoiceIndex
        : it.check!.correctIndex;
    void answer(int choice) {
      final it = controller.currentItem!;
      if (it.isInteractive) {
        controller.answerInteractive(choice);
        controller.advanceInteractive();
      } else {
        controller.toggleOption(choice);
        controller.confirm();
      }
    }

    for (final id in ['1.1', '1.2', '1.3', '1.4']) {
      controller.openLesson(id);
      while (controller.phase == AcademyPhase.theory) {
        controller.isInteractiveTheory
            ? controller.nextTableStep()
            : controller.startExercises();
      }
      while (controller.phase != AcademyPhase.result) {
        if (controller.phase == AcademyPhase.exercise) {
          answer(bestOf(controller.currentItem!));
        } else {
          controller.nextItem();
        }
      }
      controller.exitLesson();
    }

    // Falla 1.5.
    controller.openLesson('1.5');
    while (controller.phase == AcademyPhase.theory) {
      controller.isInteractiveTheory
          ? controller.nextTableStep()
          : controller.startExercises();
    }
    while (controller.phase != AcademyPhase.result) {
      if (controller.phase == AcademyPhase.exercise) {
        final it = controller.currentItem!;
        answer((bestOf(it) + 1) % it.options.length);
      } else {
        controller.nextItem();
      }
    }
    await tester.pumpAndSettle();

    expect(controller.lastOutcome!.passed, isFalse);
    expect(find.text('REINTENTAR EVALUACIÓN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

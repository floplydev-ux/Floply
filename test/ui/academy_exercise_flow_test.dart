import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/playable_exercise.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

/// Elige, para un ítem `.playable` (`AcademyPlayableScripts` — Fase 6, ver
/// `docs/design/FLOPLY_PHASE_6_INTERACTIVE_TABLE.md` §37), la acción de
/// mejor rating (tamaño y razonamiento también, si el ejercicio los pide)
/// y confirma. Mismo criterio que la rama `.isInteractive` ya existente:
/// no valida corrección, solo que el recorrido completo (acción → tamaño
/// → razonamiento → devolución) no explote para ninguna de las 88
/// instancias reales del currículo.
void _answerPlayableBest(AcademyController c, PlayableTableExercise ex) {
  var actionIdx = ex.actions.indexWhere((a) => a.rating.name == 'best');
  if (actionIdx < 0) actionIdx = 0;
  c.choosePlayableAction(actionIdx);
  final action = ex.actions[actionIdx];
  if (c.needsPlayableSizing) {
    var sizeIdx = action.sizeOptions.indexWhere((s) => s.rating.name == 'best');
    if (sizeIdx < 0) sizeIdx = 0;
    c.choosePlayableSize(sizeIdx);
  }
  if (c.lastPlayableFeedback == null && action.reasoning.isNotEmpty) {
    var reasonIdx = action.reasoning.indexWhere((r) => r.rating.name == 'best');
    if (reasonIdx < 0) reasonIdx = 0;
    c.confirmPlayableReasoning(reasonIdx);
  }
}

void main() {
  // Anchos representativos de celulares (dp lógicos). El currículo completo
  // son 64 subniveles: se recorre en 2 anchos para acotar el tiempo de test.
  for (final width in <double>[360, 430]) {
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
            if (item.isPlayable) {
              _answerPlayableBest(controller, item.playable!);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull,
                  reason: 'playable $lessonId respuesta');
              controller.advancePlayable();
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

    // `wrong` fuerza una respuesta mala (para el checkpoint 1.4, más
    // abajo) — no tiene sentido para `.playable` (no hay un solo "índice"
    // que invertir entre acción/tamaño/razonamiento), así que ese caso
    // sigue resolviéndose con la mejor respuesta incluso cuando `wrong`
    // es true. Ninguna de 1.1-1.4 es `.playable` hoy (ver Hallazgo 1,
    // Fase 5/6), pero si alguna vez lo fuera, este helper no debe volver
    // a explotar como pasó con la rama `.engine`/`.check` original.
    void answer({bool wrong = false}) {
      final it = controller.currentItem!;
      if (it.isInteractive) {
        final best = it.interactive!.bestChoiceIndex;
        final choice =
            wrong ? (best + 1) % it.interactive!.choices.length : best;
        controller.answerInteractive(choice);
        controller.advanceInteractive();
      } else if (it.isPlayable) {
        _answerPlayableBest(controller, it.playable!);
        controller.advancePlayable();
      } else {
        final best = it.check!.correctIndex;
        final choice = wrong ? (best + 1) % it.options.length : best;
        controller.toggleOption(choice);
        controller.confirm();
      }
    }

    for (final id in ['1.1', '1.2', '1.3']) {
      controller.openLesson(id);
      // `advanceTheory()` ya sabe recorrer cualquier sub-fase de teoría
      // (guion legado, ejemplo de cierre, clase de mentor, ficha escrita)
      // y pasa a ejercicios en la última — 1.1/1.2 ya no tienen guion ni
      // mentor, así que el ternario viejo (interactiva vs. saltar directo)
      // se saltearía su teoría escrita y su ejemplo de cierre.
      while (controller.phase == AcademyPhase.theory) {
        controller.advanceTheory();
      }
      while (controller.phase != AcademyPhase.result) {
        if (controller.phase == AcademyPhase.exercise) {
          answer();
        } else {
          controller.nextItem();
        }
      }
      controller.exitLesson();
    }

    // Falla el checkpoint del Nivel 1 (1.4).
    controller.openLesson('1.4');
    while (controller.phase == AcademyPhase.theory) {
      controller.advanceTheory();
    }
    while (controller.phase != AcademyPhase.result) {
      if (controller.phase == AcademyPhase.exercise) {
        answer(wrong: true);
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

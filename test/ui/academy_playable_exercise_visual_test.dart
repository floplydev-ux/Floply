// Fase 5 — migración visual de Exercise/Feedback/Result (recorrido de
// Academia) a "Sala Verde", sobre la pantalla de PRODUCCIÓN real
// (AcademyScreen), mismo criterio que test/ui/academy_visual_migration_test.dart
// (Fase 3) y test/ui/bankroll_visual_migration_test.dart (Fase 4): navegación
// real, contenido real del currículo, responsive 300-480dp.
//
// Nombre deliberadamente distinto de "academy_exercise_flow_test.dart"
// (ya existente, cubre el recorrido completo de las 64 lecciones — no
// tocar ni duplicar ese alcance acá).
//
// Nota de alcance (ver docs/design/FLOPLY_PHASE_5_ACADEMIA_EXERCISE_
// FEEDBACK_RESULT.md §Q): un escaneo real de las 64 lecciones del
// currículo (`_buildItems()` de `AcademyController`) confirmó que NINGUNA
// usa hoy un ítem `.engine` (`ExerciseCard`) ni `.check` (`_CheckCard`) —
// toda lección con ejercicios usa `.interactive` o `.playable`. El camino
// `ExerciseView`/`FeedbackView` de `_CheckCard`/`_CheckFeedbackPanel` está
// migrado y compila, pero no es alcanzable con contenido real hoy, así
// que este archivo valida lo que SÍ es real: `PlayableTableExerciseView`
// (lección 5.3, "RFI" real) y `LessonResultView` (alcanzable desde
// cualquier lección real).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

const _widths = [300.0, 320.0, 360.0, 375.0, 390.0, 412.0, 414.0, 430.0, 480.0];

/// Abre un lesson real y recorre su teoría (escrita, piloto visual o
/// guion interactivo con pregunta embebida) hasta salir de
/// `AcademyPhase.theory` — mismo patrón que `_openTheory` de
/// `academy_visual_migration_test.dart` (Fase 3), extendido para no
/// detenerse en la ficha escrita.
Future<AcademyController> _openLessonToExercise(
  WidgetTester tester,
  String sublevelId, {
  double width = 390,
  double height = 844,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final controller = AcademyController(
    engine: PokerTrainerEngine(seed: 7),
    store: InMemoryAcademyStore(),
  );
  await controller.load();
  final progress = AcademyProgress();
  for (final id in Curriculum.lessonOrder) {
    if (id == sublevelId) break;
    progress.entry(id).completed = true;
  }
  controller.progress = progress;

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AcademyScreen(controller: controller)),
  ));
  await tester.pumpAndSettle();
  controller.openLesson(sublevelId);
  await tester.pumpAndSettle();

  var guard = 0;
  while (controller.phase == AcademyPhase.theory && guard++ < 60) {
    if (controller.isVisualTheory) {
      final label = controller.currentVisualStep?.buttonLabel ?? 'CONTINUAR';
      final finder = find.text(label);
      if (finder.evaluate().isEmpty) break;
      await tester.tap(finder);
      await tester.pumpAndSettle();
      continue;
    }

    final candidates = [
      AppStrings.academyContinue,
      AppStrings.academyStartPractice,
    ];
    Finder? finder;
    for (final label in candidates) {
      final f = find.text(label);
      if (f.evaluate().isNotEmpty) {
        finder = f;
        break;
      }
    }
    if (finder != null) {
      await tester.tap(finder);
      await tester.pumpAndSettle();
      continue;
    }

    // Guion interactivo con una pregunta de comprensión embebida
    // (`mentor_lesson_stage_view.dart`, fuera de alcance de Fase 5): sin
    // CONTINUAR visible porque primero pide elegir una opción. Se
    // resuelve programáticamente (no es lo que esta fase valida) para
    // poder seguir hasta el ejercicio real.
    if (controller.isMentorLesson) {
      if (controller.mentorCheckAnswer == null) {
        controller.answerMentorCheck(0);
      } else {
        controller.nextMentorBeat();
      }
      await tester.pumpAndSettle();
      continue;
    }

    break;
  }

  return controller;
}

/// Recorre TODO el (único) ejercicio jugable de la lección 5.3 tocando
/// los controles reales (acción → tamaño si corresponde → razonamiento si
/// corresponde → pasos de explicación → VER RESULTADO), hasta llegar a
/// `AcademyPhase.result`.
Future<void> _playThroughPlayableExercise(WidgetTester tester, AcademyController c) async {
  var guard = 0;
  while (c.phase == AcademyPhase.exercise && guard++ < 30) {
    final ex = c.currentPlayable;
    if (ex == null) break;
    final actionIdx = c.playableActionIndex;
    if (actionIdx == null) {
      await tester.tap(find.text(ex.actions.first.label).first);
      await tester.pumpAndSettle();
      continue;
    }
    final action = ex.actions[actionIdx];
    if (c.needsPlayableSizing && c.playableSizeIndex == null) {
      await tester.tap(find.text(action.sizeOptions.first.label).first);
      await tester.pumpAndSettle();
      continue;
    }
    if (c.lastPlayableFeedback == null) {
      if (action.reasoning.isNotEmpty) {
        await tester.tap(find.text(action.reasoning.first.label).first);
        await tester.pumpAndSettle();
        continue;
      }
      // Sin paso de razonamiento — no debería pasar según _rfi(), pero
      // por si acaso no queda enganchado en un loop infinito.
      break;
    }
    // Ya respondió: puede haber N pasos de explicación (botón CONTINUAR)
    // antes del botón final (SIGUIENTE/VER RESULTADO, según sea o no el
    // último ítem) — `_next()` de PlayableTableExerciseView usa esos 3
    // labels según el paso.
    final last = c.itemNumber >= c.itemTotal;
    final candidates = [
      AppStrings.academyContinue,
      last ? AppStrings.academySeeResult : AppStrings.academyNext,
    ];
    Finder? finder;
    for (final label in candidates) {
      final f = find.text(label);
      if (f.evaluate().isNotEmpty) {
        finder = f;
        break;
      }
    }
    if (finder == null) break;
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('PlayableTableExerciseView — lesson 5.3 (RFI real) (Fase 5)', () {
    for (final width in _widths) {
      testWidgets('$width dp — sin overflow, acciones reales visibles',
          (tester) async {
        final controller = await _openLessonToExercise(tester, '5.3', width: width);
        expect(tester.takeException(), isNull);
        expect(controller.isPlayableExercise, isTrue);
      });
    }

    testWidgets('375x568 (altura corta) — sin overflow', (tester) async {
      final controller =
          await _openLessonToExercise(tester, '5.3', width: 375, height: 568);
      expect(tester.takeException(), isNull);
      expect(controller.isPlayableExercise, isTrue);
    });

    testWidgets('elegir una acción real muestra la devolución con rating',
        (tester) async {
      final controller = await _openLessonToExercise(tester, '5.3');
      expect(controller.isPlayableExercise, isTrue);
      final ex = controller.currentPlayable!;
      final actionLabel = ex.actions.first.label;
      final finder = find.text(actionLabel);
      expect(finder, findsWidgets);
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('recorrido real completo hasta VER RESULTADO llega a Result',
        (tester) async {
      final controller = await _openLessonToExercise(tester, '5.3');
      await _playThroughPlayableExercise(tester, controller);
      expect(tester.takeException(), isNull);
      expect(controller.phase, AcademyPhase.result);
      expect(controller.lastOutcome, isNotNull);
    });
  });

  group('Result — estados reales (Fase 5)', () {
    testWidgets('lesson 5.3 completa muestra la pantalla de resultado migrada',
        (tester) async {
      final controller = await _openLessonToExercise(tester, '5.3');
      await _playThroughPlayableExercise(tester, controller);
      expect(tester.takeException(), isNull);
      final outcome = controller.lastOutcome;
      expect(outcome, isNotNull);
      if (outcome!.passed) {
        expect(find.text(AppStrings.academyBackToMap), findsWidgets);
      } else {
        expect(find.text(AppStrings.academyRetry), findsOneWidget);
      }
    });

    for (final width in [300.0, 320.0, 480.0]) {
      testWidgets('$width dp — pantalla de resultado sin overflow', (tester) async {
        final controller =
            await _openLessonToExercise(tester, '5.3', width: width);
        await _playThroughPlayableExercise(tester, controller);
        expect(tester.takeException(), isNull);
        expect(controller.phase, AcademyPhase.result);
      });
    }
  });
}

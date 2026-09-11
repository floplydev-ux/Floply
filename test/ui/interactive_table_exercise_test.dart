import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/table_exercise.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

AcademyProgress _progressUpTo(String target) {
  final p = AcademyProgress();
  for (final id in Curriculum.lessonOrder) {
    if (id == target) break;
    p.entry(id).completed = true;
  }
  return p;
}

Future<AcademyController> _open72(WidgetTester tester,
    {double width = 360}) async {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final controller = AcademyController(
    engine: PokerTrainerEngine(seed: 6),
    store: InMemoryAcademyStore(),
  );
  await controller.load();
  controller.progress = _progressUpTo('7.2');

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AcademyScreen(controller: controller)),
  ));
  await tester.pumpAndSettle();
  controller.openLesson('7.2');
  // 7.2 ahora tiene teoría redactada (N7, PASO 4): pasarla antes de los
  // ejercicios interactivos, igual que el resto de los tests de la suite.
  while (controller.phase == AcademyPhase.theory) {
    controller.advanceTheory();
  }
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  test('el lesson 7.2 (ex-5.4) tiene un set de ejercicios interactivos bien formado',
      () {
    final set = AcademyExerciseScripts.forLesson('7.2');
    expect(set, isNotNull);
    expect(set!.exercises.length, 3);
    for (final ex in set.exercises) {
      expect(ex.choices.length, inInclusiveRange(2, 3));
      expect(ex.choices.where((c) => c.rating == ExerciseRating.best).length, 1,
          reason: 'debe haber exactamente una "mejor" opción');
      expect(ex.bestChoiceIndex, isNonNegative);
      expect(ex.question.trim(), isNotEmpty);
      expect(ex.explanation, isNotEmpty);
      for (final c in ex.choices) {
        expect(c.feedback.trim(), isNotEmpty);
      }
      for (final s in ex.explanation) {
        expect(s.text.trim(), isNotEmpty);
      }
      expect(ex.situation.seats.length, 6);
    }
  });

  testWidgets('flujo completo: mesa → decisión → resultado → explicación → '
      'siguiente → resultado del lesson', (tester) async {
    final c = await _open72(tester);

    expect(c.phase, AcademyPhase.exercise);
    expect(c.isInteractiveExercise, isTrue);
    expect(c.currentInteractive, isNotNull);

    // Aparece la pregunta y los 3 botones.
    expect(find.text(c.interactiveQuestionText!), findsOneWidget);
    for (final ch in c.currentInteractive!.choices) {
      expect(find.text(ch.label), findsOneWidget);
    }

    var guard = 0;
    while (c.phase == AcademyPhase.exercise && guard++ < 40) {
      final ex = c.currentInteractive!;

      // 1) Elegir la mejor opción.
      await tester.tap(find.text(c.resolveInteractive(ex.choices[ex.bestChoiceIndex].label)));
      await tester.pumpAndSettle();

      // 2) Opciones bloqueadas: los botones de opción desaparecieron y
      //    volver a responder es un no-op.
      final lockedChoice = c.interactiveChoice;
      expect(lockedChoice, ex.bestChoiceIndex);
      for (final other in ex.choices) {
        if (other == ex.choices[ex.bestChoiceIndex]) continue;
        expect(find.text(other.label), findsNothing);
      }
      c.answerInteractive((lockedChoice! + 1) % ex.choices.length);
      await tester.pumpAndSettle();
      expect(c.interactiveChoice, lockedChoice);

      // 3) Se ve el resultado (chip) y el feedback de la opción elegida.
      expect(
        find.textContaining(ex.strategyDependent ? 'ELECCIÓN' : 'CORRECTO'),
        findsOneWidget,
      );
      expect(find.text(c.resolveInteractive(ex.choices[ex.bestChoiceIndex].feedback)), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4) Avanzar por las explicaciones.
      var steps = 0;
      while (c.phase == AcademyPhase.exercise &&
          c.interactiveChoice != null &&
          steps++ < 12) {
        final label = find.text('CONTINUAR').evaluate().isNotEmpty
            ? 'CONTINUAR'
            : (find.text('SIGUIENTE').evaluate().isNotEmpty
                ? 'SIGUIENTE'
                : 'VER RESULTADO');
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'avanzando explicación');
      }
    }

    expect(c.phase, AcademyPhase.result);
    expect(find.text('VOLVER AL MAPA'), findsOneWidget);
  });

  for (final width in <double>[320, 360, 390, 412]) {
    testWidgets('$width dp: sin overflow en toda la sesión interactiva',
        (tester) async {
      final c = await _open72(tester, width: width);
      var guard = 0;
      while (c.phase == AcademyPhase.exercise && guard++ < 60) {
        expect(tester.takeException(), isNull, reason: '$width dp');
        if (c.interactiveChoice == null) {
          final ex = c.currentInteractive!;
          await tester.tap(find.text(c.resolveInteractive(ex.choices[ex.bestChoiceIndex].label)));
        } else {
          final f = ['CONTINUAR', 'SIGUIENTE', 'VER RESULTADO']
              .map(find.text)
              .firstWhere((x) => x.evaluate().isNotEmpty);
          await tester.tap(f);
        }
        await tester.pumpAndSettle();
      }
      expect(c.phase, AcademyPhase.result);
      expect(tester.takeException(), isNull);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/mentor_lesson.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

AcademyProgress _upTo(String target) {
  final p = AcademyProgress();
  for (final id in Curriculum.lessonOrder) {
    if (id == target) break;
    p.entry(id).completed = true;
  }
  return p;
}

void main() {
  const level3 = ['3.1', '3.2', '3.3', '3.4', '3.5'];

  /// Índice de la opción correcta de un ítem (interactivo, motor o check).
  int best(AcademyItem it) {
    if (it.isInteractive) return it.interactive!.bestChoiceIndex;
    if (it.isEngine) {
      final ex = it.exercise!;
      final primary = ex.strategy.primary;
      final i = ex.options.indexWhere(
        (o) =>
            (o.action != null && o.action!.matches(primary.action)) ||
            (ex.correctValue != null && o.value == ex.correctValue),
      );
      return i < 0 ? 0 : i;
    }
    return it.check!.correctIndex;
  }

  Future<void> answer(WidgetTester tester, AcademyController c, int choice)
      async {
    final it = c.currentItem!;
    if (it.isInteractive) {
      c.answerInteractive(choice);
      await tester.pumpAndSettle();
      var guard = 0;
      while (c.interactiveChoice != null &&
          c.phase == AcademyPhase.exercise &&
          guard++ < 15) {
        final f = ['CONTINUAR', 'SIGUIENTE', 'VER RESULTADO']
            .map(find.text)
            .firstWhere((x) => x.evaluate().isNotEmpty);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }
    } else {
      c.toggleOption(choice);
      c.confirm();
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(RegExp('SIGUIENTE|VER RESULTADO')));
      await tester.pumpAndSettle();
    }
  }

  double heightFor(double width) => width <= 360 ? 640 : (width <= 390 ? 844 : 915);

  for (final width in <double>[320, 360, 390, 412, 430]) {
    testWidgets('$width dp — el Nivel 3 (posición) se recorre entero sin '
        'overflow y desbloquea el Nivel 4', (tester) async {
      tester.view.physicalSize = Size(width * 3, heightFor(width) * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final c = AcademyController(
        engine: PokerTrainerEngine(seed: 4),
        store: InMemoryAcademyStore(),
        userName: 'Dani',
      );
      await c.load();
      c.progress = _upTo('3.1');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AcademyScreen(controller: c)),
      ));
      await tester.pumpAndSettle();

      for (final id in level3) {
        c.openLesson(id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'abrir $id @ $width');

        // Teoría: guion de mesa (3.1, 3.3, 3.4) → clase de mentor (si
        // tiene, reemplaza la ficha) / fichas de teoría redactada.
        while (c.phase == AcademyPhase.theory) {
          if (c.isMentorLesson) {
            final beat = c.currentMentorBeat;
            final label = (beat is MentorCheckBeat && c.mentorCheckAnswer == null)
                ? beat.check.options.first.label
                : c.mentorContinueLabel;
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'teoría (mentor) $id @ $width');
            continue;
          }
          final last = c.isInteractiveTheory
              ? (c.isLastTableStep && !c.hasWrittenTheory)
              : c.isLastWrittenTheory;
          await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'teoría $id @ $width');
        }

        var guard = 0;
        while ((c.phase == AcademyPhase.exercise ||
                c.phase == AcademyPhase.feedback) &&
            guard++ < 40) {
          if (c.phase == AcademyPhase.feedback) {
            c.nextItem();
            await tester.pumpAndSettle();
            continue;
          }
          await answer(tester, c, best(c.currentItem!));
          expect(tester.takeException(), isNull,
              reason: 'ejercicio $id @ $width');
        }

        expect(c.phase, AcademyPhase.result, reason: '$id no terminó');
        expect(c.lastOutcome!.completed, isTrue, reason: '$id no completó');
        expect(tester.takeException(), isNull, reason: 'resultado $id @ $width');

        expect(find.text('VOLVER AL MAPA'), findsOneWidget);
        await tester.tap(find.text('VOLVER AL MAPA'));
        await tester.pumpAndSettle();
        expect(c.phase, AcademyPhase.map);
      }

      // Progreso, desbloqueo y mastery.
      expect(c.academy.stateOf('4.1', c.progress), LessonState.available);
      expect(c.knowledge.isTaught(ConceptIds.positionNames), isTrue);
      expect(c.knowledge.isTaught(ConceptIds.positionAdvantage), isTrue);
      expect(c.knowledge.masteryOf(ConceptIds.positionNames).attempts,
          greaterThan(0));
    });
  }

  testWidgets('en el Nivel 3, el usuario aparece sentado con su nombre y hay '
      'posiciones etiquetadas', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final c = AcademyController(
      engine: PokerTrainerEngine(seed: 2),
      store: InMemoryAcademyStore(),
      userName: 'Ivo',
    );
    await c.load();
    c.progress = _upTo('3.1');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: c)),
    ));
    await tester.pumpAndSettle();

    // 3.1 arranca en teoría interactiva sobre la mesa.
    c.openLesson('3.1');
    await tester.pumpAndSettle();
    expect(c.phase, AcademyPhase.theory);
    expect(c.isInteractiveTheory, isTrue);
    expect(find.text('Ivo'), findsWidgets);
    expect(find.text('HERO'), findsNothing);
    expect(find.text('TÚ'), findsNothing);

    // Pasar por el guion, la clase de mentor (si tiene) y las fichas de
    // teoría redactada.
    while (c.phase == AcademyPhase.theory) {
      if (c.isMentorLesson) {
        final beat = c.currentMentorBeat;
        final label = (beat is MentorCheckBeat && c.mentorCheckAnswer == null)
            ? beat.check.options.first.label
            : c.mentorContinueLabel;
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        continue;
      }
      final last = c.isInteractiveTheory
          ? (c.isLastTableStep && !c.hasWrittenTheory)
          : c.isLastWrittenTheory;
      await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
      await tester.pumpAndSettle();
    }
    expect(c.phase, AcademyPhase.exercise);
    expect(c.isInteractiveExercise, isTrue);
    expect(find.text('Ivo'), findsWidgets);
  });
}

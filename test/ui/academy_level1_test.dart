import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/mentor_lesson.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

void main() {
  // Nivel 1 en la estructura de 13 niveles: 4 subniveles (el 4º es el
  // checkpoint del nivel).
  const level1 = ['1.1', '1.2', '1.3', '1.4'];

  int best(AcademyItem it) => it.isInteractive
      ? it.interactive!.bestChoiceIndex
      : (it.isEngine ? 0 : it.check!.correctIndex);

  Future<void> answer(WidgetTester tester, AcademyController c, int choice)
      async {
    final it = c.currentItem!;
    if (it.isInteractive) {
      c.answerInteractive(choice);
      await tester.pumpAndSettle();
      // Recorrer la explicación tocando el botón que esté visible.
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
    testWidgets('$width dp — el Nivel 1 se recorre entero por la mesa, sin '
        'overflow, y desbloquea el Nivel 2', (tester) async {
      tester.view.physicalSize = Size(width * 3, heightFor(width) * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final c = AcademyController(
        engine: PokerTrainerEngine(seed: 9),
        store: InMemoryAcademyStore(),
      );
      await c.load();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AcademyScreen(controller: c)),
      ));
      await tester.pumpAndSettle();

      for (final id in level1) {
        c.openLesson(id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'abrir $id @ $width');

        // Teoría: guion de mesa (si tiene) → clase de mentor (si tiene,
        // reemplaza la ficha) / fichas de teoría redactada → ejemplo de
        // cierre del piloto de 3 bloques (si tiene, solo 1.1 por ahora).
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
          if (c.isClosingExample) {
            await tester.tap(find.text(c.closingExampleButtonLabel));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'teoría (ejemplo de cierre) $id @ $width');
            continue;
          }
          final bool last = c.isInteractiveTheory
              ? (c.isLastTableStep && !c.hasWrittenTheory)
              : (c.isLastWrittenTheory && !c.hasClosingExample);
          await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'teoría $id @ $width');
        }

        // Ejercicios.
        var guard = 0;
        while ((c.phase == AcademyPhase.exercise ||
                c.phase == AcademyPhase.feedback) &&
            guard++ < 30) {
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

        // Volver al mapa (flujo de resultados existente).
        expect(find.text('VOLVER AL MAPA'), findsOneWidget);
        await tester.tap(find.text('VOLVER AL MAPA'));
        await tester.pumpAndSettle();
        expect(c.phase, AcademyPhase.map);
      }

      // Progreso y mastery.
      expect(c.progress.completedCount, greaterThanOrEqualTo(4));
      expect(c.academy.stateOf('2.1', c.progress), LessonState.available);
      expect(c.knowledge.isTaught(ConceptIds.rules), isTrue);
      expect(c.knowledge.masteryOf(ConceptIds.rules).attempts, greaterThan(0));
      // No se enseñó nada adelantado.
      expect(c.knowledge.isTaught(ConceptIds.threeBet), isFalse);
    });
  }

  test('los subniveles del Nivel 2 existen en el currículo', () {
    for (final id in ['2.1', '2.2']) {
      expect(Curriculum.standard().lessonById(id), isNotNull);
    }
  });
}

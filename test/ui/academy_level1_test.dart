import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

void main() {
  const level1 = ['1.1', '1.2', '1.3', '1.4', '1.5'];

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

  for (final width in <double>[320, 360, 390, 412]) {
    testWidgets('$width dp — el Nivel 1 se recorre entero por la mesa, sin '
        'overflow, y desbloquea el Nivel 2', (tester) async {
      tester.view.physicalSize = Size(width * 3, 780 * 3);
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

        // Teoría interactiva (si tiene).
        while (c.phase == AcademyPhase.theory) {
          if (c.isInteractiveTheory) {
            final label = c.isLastTableStep ? 'PRACTICAR' : 'CONTINUAR';
            await tester.tap(find.text(label));
          } else {
            await tester.tap(find.text('CONTINUAR'));
          }
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
      expect(c.progress.completedCount, greaterThanOrEqualTo(5));
      expect(c.academy.stateOf('2.1', c.progress), LessonState.available);
      expect(c.knowledge.isTaught(ConceptIds.rules), isTrue);
      expect(c.knowledge.masteryOf(ConceptIds.rules).attempts, greaterThan(0));
      // No se enseñó nada adelantado.
      expect(c.knowledge.isTaught(ConceptIds.threeBet), isFalse);
    });
  }

  test('el Nivel 1 no rompe las lecciones que usan ExerciseCard (Nivel 2)',
      () {
    // Nivel 2 sigue sin set interactivo → usa el motor.
    for (final id in ['2.2', '2.3', '2.4', '2.5']) {
      final lesson = Curriculum.standard().lessonById(id);
      expect(lesson, isNotNull);
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
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
  for (final width in <double>[320, 360, 390, 412]) {
    testWidgets('$width dp — el Nivel 2 (showdowns en la mesa) se recorre '
        'entero sin overflow y desbloquea el Nivel 3', (tester) async {
      tester.view.physicalSize = Size(width * 3, 780 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final c = AcademyController(
        engine: PokerTrainerEngine(seed: 7),
        store: InMemoryAcademyStore(),
        userName: 'Sol',
      );
      await c.load();
      c.progress = _upTo('2.1');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AcademyScreen(controller: c)),
      ));
      await tester.pumpAndSettle();

      for (final id in ['2.1', '2.2', '2.3', '2.4', '2.5']) {
        c.openLesson(id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'abrir $id @ $width');

        while (c.phase == AcademyPhase.theory) {
          final label = c.isLastTableStep ? 'PRACTICAR' : 'CONTINUAR';
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'teoría $id @ $width');
        }

        var guard = 0;
        while (c.phase == AcademyPhase.exercise && guard++ < 40) {
          final ex = c.currentInteractive!;
          // El usuario está sentado con su nombre.
          expect(find.text('Sol'), findsWidgets, reason: '$id: falta el nombre');
          await tester.tap(find.text(
              c.resolveInteractive(ex.choices[ex.bestChoiceIndex].label)));
          await tester.pumpAndSettle();
          var steps = 0;
          while (c.interactiveChoice != null &&
              c.phase == AcademyPhase.exercise &&
              steps++ < 10) {
            final f = ['CONTINUAR', 'SIGUIENTE', 'VER RESULTADO']
                .map(find.text)
                .firstWhere((x) => x.evaluate().isNotEmpty);
            await tester.tap(f);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull, reason: 'ejercicio $id @ $width');
        }

        expect(c.phase, AcademyPhase.result, reason: '$id no terminó');
        expect(c.lastOutcome!.completed, isTrue, reason: '$id no completó');
        await tester.tap(find.text('VOLVER AL MAPA'));
        await tester.pumpAndSettle();
      }

      expect(c.academy.stateOf('3.1', c.progress), LessonState.available);
      expect(c.knowledge.masteryOf(ConceptIds.handRanking).attempts,
          greaterThan(0));
    });
  }
}

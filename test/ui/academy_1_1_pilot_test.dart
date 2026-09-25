import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/academy_closing_examples.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/academy_mentor_lessons.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';
import 'package:poker_trainer/screens/academy/widgets/poker_table_view.dart';

/// Piloto de 3 bloques del subnivel 1.1 (Fase 3.1): Bloque A (teoría
/// escrita, sin mesa/sin burbujas, mismo patrón que 4.1) → Bloque B
/// (ejemplo de mesa, texto siempre debajo, sin burbuja) → Bloque C
/// (ejercicios, mesa + pregunta). Recorre el subnivel entero por UI real,
/// sin excepciones/overflow, en varios anchos.
void main() {
  Future<AcademyController> open(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final c = AcademyController(
      engine: PokerTrainerEngine(seed: 7),
      store: InMemoryAcademyStore(),
      userName: 'Ada',
    );
    await c.load();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.openLesson('1.1');
    await tester.pumpAndSettle();
    return c;
  }

  test('1.1 ya no tiene guion de mesa legado ni clases de mentor para '
      'T001-T005; tiene ejemplo de cierre y ejercicios propios', () {
    expect(AcademyMentorLessons.has('T001'), isFalse);
    expect(AcademyMentorLessons.has('T005'), isFalse);
    expect(AcademyClosingExamples.has('1.1'), isTrue);
    final set = AcademyExerciseScripts.forLesson('1.1');
    expect(set, isNotNull);
    expect(set!.length, 8);
  });

  for (final width in <double>[360, 390, 430]) {
    testWidgets('$width dp — Bloque A → B → C se recorren enteros sin '
        'overflow', (tester) async {
      final c = await open(tester, width);

      // --- Bloque A: 5 fichas de teoría escrita, sin mesa, sin mentor. ---
      expect(c.phase, AcademyPhase.theory);
      expect(c.isInteractiveTheory, isFalse,
          reason: '1.1 ya no debería abrir con el guion de mesa legado');
      for (var i = 0; i < 5; i++) {
        expect(c.isWrittenTheory, isTrue, reason: 'ficha $i');
        expect(c.isMentorLesson, isFalse, reason: 'ficha $i');
        expect(find.byType(PokerTableView), findsNothing,
            reason: 'Bloque A no debería mostrar mesa (ficha $i)');
        final last = c.isLastWrittenTheory && !c.hasClosingExample;
        await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Bloque A ficha $i');
      }

      // --- Bloque B: ejemplo de mesa, 9 pasos, texto siempre en el panel. ---
      expect(c.isClosingExample, isTrue);
      var guard = 0;
      while (c.isClosingExample && guard++ < 15) {
        expect(find.byType(PokerTableView), findsOneWidget,
            reason: 'Bloque B paso $guard debería mostrar la mesa');
        await tester.tap(find.text(c.closingExampleButtonLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Bloque B paso $guard');
      }
      expect(guard, 9, reason: 'el ejemplo de cierre tiene 9 pasos');

      // --- Bloque C: 8 ejercicios interactivos (mesa + pregunta). ---
      expect(c.phase, AcademyPhase.exercise);
      var exGuard = 0;
      while ((c.phase == AcademyPhase.exercise ||
              c.phase == AcademyPhase.feedback) &&
          exGuard++ < 40) {
        if (c.phase == AcademyPhase.feedback) {
          c.nextItem();
          await tester.pumpAndSettle();
          continue;
        }
        final it = c.currentItem!;
        expect(it.isInteractive, isTrue);
        c.answerInteractive(it.interactive!.bestChoiceIndex);
        await tester.pumpAndSettle();
        var stepGuard = 0;
        while (c.interactiveChoice != null &&
            c.phase == AcademyPhase.exercise &&
            stepGuard++ < 15) {
          final next = ['CONTINUAR', 'SIGUIENTE', 'VER RESULTADO']
              .map(find.text)
              .firstWhere((f) => f.evaluate().isNotEmpty);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: 'ejercicio $exGuard');
      }

      expect(c.phase, AcademyPhase.result);
      expect(c.lastOutcome!.completed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}

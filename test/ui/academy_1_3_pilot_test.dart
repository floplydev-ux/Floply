import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/academy_closing_examples.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/academy_mentor_lessons.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';
import 'package:poker_trainer/screens/academy/widgets/poker_table_view.dart';

/// Piloto de 3 bloques del subnivel 1.3 (las 10 acciones): Bloque A (teoría
/// escrita, sin mesa/sin burbujas, mismo patrón que 4.1) → Bloque B (10
/// ejemplos de mesa, uno por acción, texto siempre debajo, sin burbuja) →
/// Bloque C (10 ejercicios, mesa + pregunta, opciones en orden aleatorio).
/// Recorre el subnivel entero por UI real, sin excepciones/overflow, en
/// varios anchos.
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
    c.progress = AcademyProgress()
      ..entry('1.1').completed = true
      ..entry('1.2').completed = true;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.openLesson('1.3');
    await tester.pumpAndSettle();
    return c;
  }

  test('1.3 ya no tiene guion de mesa legado ni clases de mentor para '
      'T033-T042; tiene ejemplo de cierre y ejercicios propios', () {
    for (final id in [
      'T033', 'T034', 'T035', 'T036', 'T037',
      'T038', 'T039', 'T040', 'T041', 'T042',
    ]) {
      expect(AcademyMentorLessons.has(id), isFalse, reason: id);
    }
    expect(AcademyClosingExamples.has('1.3'), isTrue);
    final set = AcademyExerciseScripts.forLesson('1.3');
    expect(set, isNotNull);
    expect(set!.length, 10);
  });

  test('los ejercicios de 1.3 no ponen siempre la mejor opción primera '
      '(orden aleatorio real, no A/B/C fijo)', () {
    final set = AcademyExerciseScripts.forLesson('1.3')!;
    final bestIndices = set.exercises.map((e) => e.bestChoiceIndex).toList();
    expect(bestIndices.any((i) => i != 0), isTrue,
        reason: 'todas las respuestas correctas cayeron en el índice 0: '
            'no parece haber shuffle real');
  });

  test('ningún ejercicio de 1.3 menciona categorías de mano (pareja/trío/'
      'etc.) o farol: todavía no se enseñaron ("BB" se usa solo como unidad '
      'de fichas, igual que en el resto de la Academia)', () {
    // Ojo: "póker" (el juego, "el póker") NO entra acá — aparece en frases
    // genéricas legítimas ("no en el póker..."); la categoría de mano
    // "póker" (four of a kind) se buscaría como "póker de" seguido de un
    // valor, que no aparece en ningún lado.
    final forbidden = ['pareja', 'trío', 'trio', 'full', 'escalera', 'color',
      'farol', 'farolear'];
    final set = AcademyExerciseScripts.forLesson('1.3')!;
    for (final ex in set.exercises) {
      final text = ([ex.question, ...ex.choices.map((c) => c.feedback),
            ...ex.choices.map((c) => c.label),
            ...ex.explanation.map((s) => s.text)])
          .join(' ')
          .toLowerCase();
      for (final word in forbidden) {
        expect(text.contains(word), isFalse,
            reason: '"$word" aparece en un ejercicio de 1.3');
      }
    }
  });

  for (final width in <double>[360, 390, 430]) {
    testWidgets('$width dp — Bloque A → B → C se recorren enteros sin '
        'overflow', (tester) async {
      final c = await open(tester, width);

      // --- Bloque A: 10 fichas de teoría escrita, sin mesa, sin mentor. ---
      expect(c.phase, AcademyPhase.theory);
      expect(c.isInteractiveTheory, isFalse,
          reason: '1.3 ya no debería abrir con el guion de mesa legado');
      for (var i = 0; i < 10; i++) {
        expect(c.isWrittenTheory, isTrue, reason: 'ficha $i');
        expect(c.isMentorLesson, isFalse, reason: 'ficha $i');
        expect(find.byType(PokerTableView), findsNothing,
            reason: 'Bloque A no debería mostrar mesa (ficha $i)');
        final last = c.isLastWrittenTheory && !c.hasClosingExample;
        await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Bloque A ficha $i');
      }

      // --- Bloque B: ejemplo de mesa, 12 pasos, texto siempre en el panel. ---
      expect(c.isClosingExample, isTrue);
      var guard = 0;
      while (c.isClosingExample && guard++ < 20) {
        expect(find.byType(PokerTableView), findsOneWidget,
            reason: 'Bloque B paso $guard debería mostrar la mesa');
        await tester.tap(find.text(c.closingExampleButtonLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Bloque B paso $guard');
      }
      expect(guard, 12, reason: 'el ejemplo de cierre tiene 12 pasos');

      // --- Bloque C: 10 ejercicios interactivos (mesa + pregunta). ---
      expect(c.phase, AcademyPhase.exercise);
      var exGuard = 0;
      while ((c.phase == AcademyPhase.exercise ||
              c.phase == AcademyPhase.feedback) &&
          exGuard++ < 60) {
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

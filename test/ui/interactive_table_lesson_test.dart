import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/mentor_lesson.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

/// Progreso con todos los lessons anteriores a [target] ya completados,
/// para poder abrir directamente un lesson interactivo en un test.
AcademyProgress _progressUpTo(String target) {
  final p = AcademyProgress();
  for (final id in Curriculum.lessonOrder) {
    if (id == target) break;
    p.entry(id).completed = true;
  }
  return p;
}

Future<AcademyController> _openInteractive(
  WidgetTester tester,
  String lessonId, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final engine = PokerTrainerEngine(seed: 4);
  final store = InMemoryAcademyStore();
  final controller = AcademyController(engine: engine, store: store);
  await controller.load();
  controller.progress = _progressUpTo(lessonId);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AcademyScreen(controller: controller)),
  ));
  await tester.pumpAndSettle();

  controller.openLesson(lessonId);
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  // Subniveles con teoría interactiva sobre la mesa Y ejercicios después.
  // (1.1, 1.2, 1.3 y 1.4 migraron al piloto de 3 bloques y ya no tienen
  // guion legado — ver `academy_1_1_pilot_test.dart` /
  // `academy_1_2_pilot_test.dart` / `academy_1_3_pilot_test.dart`; 1.4
  // todavía no tiene su propio test dedicado, pendiente, no bloquea esta
  // prueba.)
  for (final id in ['2.1', '3.1', '3.3']) {
    testWidgets('$id: la mesa interactiva se recorre sin overflow ni '
        'excepciones', (tester) async {
      final c = await _openInteractive(tester, id, width: 360);

      expect(c.isInteractiveTheory, isTrue);
      expect(find.text('CONTINUAR'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$id inicio');

      // 1.4 tiene 7 teorías con clase de mentor (varios turnos cada una):
      // el tope viejo (30) alcanzaba para 1.2 (3 teorías) pero no para esto.
      var guard = 0;
      while (c.phase == AcademyPhase.theory && guard++ < 200) {
        if (c.isInteractiveTheory) {
          expect(find.text(c.currentBubbleText!), findsOneWidget,
              reason: '$id paso ${c.tableStep + 1}');
          final last = c.isLastTableStep && !c.hasWrittenTheory;
          await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
        } else if (c.isMentorLesson) {
          // Clase de mentor (reemplaza la ficha escrita de esa teoría).
          final beat = c.currentMentorBeat;
          final label = (beat is MentorCheckBeat && c.mentorCheckAnswer == null)
              ? beat.check.options.first.label
              : c.mentorContinueLabel;
          await tester.tap(find.text(label));
        } else {
          // Fichas de teoría redactada (N1).
          await tester.tap(
              find.text(c.isLastWrittenTheory ? 'PRACTICAR' : 'CONTINUAR'));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$id avanzando');
      }

      expect(c.phase, AcademyPhase.exercise);
    });
  }

  testWidgets('ATRÁS retrocede pasos', (tester) async {
    final c = await _openInteractive(tester, '3.1');
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(c.tableStep, 2);
    await tester.tap(find.text('ATRÁS'));
    await tester.pumpAndSettle();
    expect(c.tableStep, 1);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
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
  for (final id in ['1.1', '3.1', '3.3', '4.1', '5.1']) {
    testWidgets('$id: la mesa interactiva se recorre sin overflow ni '
        'excepciones', (tester) async {
      final c = await _openInteractive(tester, id, width: id == '1.1' ? 320 : 360);

      expect(c.isInteractiveTheory, isTrue);
      expect(find.text('CONTINUAR'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$id inicio');

      var guard = 0;
      while (c.phase == AcademyPhase.theory && guard++ < 20) {
        expect(find.text(c.currentBubbleText!), findsOneWidget,
            reason: '$id paso ${c.tableStep + 1}');
        final label = c.isLastTableStep ? 'PRACTICAR' : 'CONTINUAR';
        await tester.tap(find.text(label));
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

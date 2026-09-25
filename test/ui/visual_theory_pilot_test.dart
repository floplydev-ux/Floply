import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

/// Piloto visual: T093 (set), T082 (proyectos), T098/T099 (nuts / cerca de
/// los nuts). Verifica que la experiencia visual se muestra, navega y cede
/// paso a la ficha escrita de la MISMA teoría, sin overflow en vertical.
void main() {
  AcademyProgress upTo(String target) {
    final p = AcademyProgress();
    for (final id in Curriculum.lessonOrder) {
      if (id == target) break;
      p.entry(id).completed = true;
    }
    return p;
  }

  Future<AcademyController> open(
    WidgetTester tester,
    String sublevelId, {
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final c = AcademyController(
      engine: PokerTrainerEngine(seed: 11),
      store: InMemoryAcademyStore(),
      userName: 'Ada',
    );
    await c.load();
    c.progress = upTo(sublevelId);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.openLesson(sublevelId);
    await tester.pumpAndSettle();
    return c;
  }

  /// Avanza la fase teoría (controller-driven, sin tocar la UI) hasta que
  /// la teoría redactada activa sea [theoryId].
  Future<void> fastForwardTo(
      WidgetTester tester, AcademyController c, String theoryId) async {
    var guard = 0;
    while (c.currentWrittenTheory?.id != theoryId && guard++ < 40) {
      c.advanceTheory();
      await tester.pump();
    }
    expect(c.currentWrittenTheory?.id, theoryId,
        reason: 'no llegó a $theoryId');
  }

  /// Recorre por UI (tocando el botón real) todos los pasos de la
  /// experiencia visual activa, verificando que no haya excepciones ni
  /// overflow, y que la burbuja tenga texto en cada paso.
  Future<void> walkVisualByUi(WidgetTester tester, AcademyController c) async {
    expect(c.isVisualTheory, isTrue);
    final total = c.visualStepCount;
    expect(total, greaterThan(0));

    var guard = 0;
    while (c.isVisualTheory && guard++ < total + 2) {
      final step = c.currentVisualStep!;
      expect(step.bubble, isNotEmpty);
      expect(find.text('${c.visualStep + 1} / ${c.visualStepCount}'),
          findsOneWidget);
      final label = step.buttonLabel ?? 'CONTINUAR';
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'paso visual $guard');
    }
  }

  for (final (name, size) in <(String, Size)>[
    ('320x640', const Size(320, 640)),
    ('390x844', const Size(390, 844)),
    ('430x932', const Size(430, 932)),
  ]) {
    testWidgets('$name — T093 (set): visual → ficha escrita, sin overflow',
        (tester) async {
      final c =
          await open(tester, '4.5', width: size.width, height: size.height);
      await fastForwardTo(tester, c, 'T093');

      expect(c.isVisualTheory, isTrue,
          reason: 'T093 debería abrir en modo visual');
      await walkVisualByUi(tester, c);

      // Terminada la experiencia visual, sigue la ficha escrita de T093.
      expect(c.isWrittenTheory, isTrue);
      expect(c.currentWrittenTheory?.id, 'T093');
      expect(find.textContaining('Set'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('T093 — ATRÁS retrocede un paso visual', (tester) async {
    final c = await open(tester, '4.5');
    await fastForwardTo(tester, c, 'T093');
    expect(c.visualStep, 0);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(c.visualStep, 1);

    expect(find.text('ATRÁS'), findsOneWidget);
    await tester.tap(find.text('ATRÁS'));
    await tester.pumpAndSettle();
    expect(c.visualStep, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('T082 (proyectos): distingue "todavía no" de "se completa"',
      (tester) async {
    final c = await open(tester, '4.4');
    await fastForwardTo(tester, c, 'T082');
    expect(c.isVisualTheory, isTrue);

    final bubbles = <String>[];
    var guard = 0;
    while (c.isVisualTheory && guard++ < 10) {
      bubbles.add(c.resolveText(
        c.currentVisualStep!.bubble,
        c.castTable(c.currentVisualStep!.table),
      ));
      await tester
          .tap(find.text(c.currentVisualStep!.buttonLabel ?? 'CONTINUAR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(bubbles.any((b) => b.toLowerCase().contains('todavía no')), isTrue,
        reason: 'debe marcar explícitamente que el proyecto no está hecho');
    expect(c.isWrittenTheory, isTrue);
    expect(c.currentWrittenTheory?.id, 'T082');
  });

  testWidgets('T098 → T099: los nuts y cerca de los nuts, mismo componente',
      (tester) async {
    final c = await open(tester, '4.6');
    await fastForwardTo(tester, c, 'T098');
    expect(c.isVisualTheory, isTrue);
    await walkVisualByUi(tester, c);
    expect(c.currentWrittenTheory?.id, 'T098');
    expect(find.textContaining('nuts'), findsWidgets);

    // Avanza (controller-driven) a través de la ficha escrita de T098 hasta
    // T099, que reutiliza el mismo VisualTheoryStageView.
    await fastForwardTo(tester, c, 'T099');
    expect(c.isVisualTheory, isTrue);
    await walkVisualByUi(tester, c);
    expect(c.currentWrittenTheory?.id, 'T099');
    expect(find.textContaining('Cerca de los nuts'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'la burbuja se ancla al elemento que señala cada paso (ya no vive en '
      'una banda fija): su posición cambia entre un paso anclado a las '
      'cartas del héroe y uno anclado al board', (tester) async {
    final c = await open(tester, '4.5');
    await fastForwardTo(tester, c, 'T093');
    expect(c.isVisualTheory, isTrue);

    // Paso 0 de T093: ancla en heroCards (abajo-centro).
    expect(c.currentVisualStep!.anchor, TableAnchor.heroCards);
    final bubbleAtHero =
        tester.getCenter(find.byIcon(Icons.chat_bubble_rounded));

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    // Paso 1: ancla en el board (centro de la mesa).
    expect(c.currentVisualStep!.anchor, TableAnchor.board);
    final bubbleAtBoard =
        tester.getCenter(find.byIcon(Icons.chat_bubble_rounded));

    expect(
      (bubbleAtHero.dy - bubbleAtBoard.dy).abs(),
      greaterThan(8),
      reason: 'la burbuja debería moverse verticalmente al cambiar de '
          'ancla, no quedarse fija en una banda superior',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('teorías sin piloto visual siguen yendo directo a la ficha',
      (tester) async {
    final c = await open(tester, '4.5');
    // T087 es la primera teoría de 4.5 y no tiene piloto visual.
    expect(c.currentWrittenTheory?.id, 'T087');
    expect(c.isVisualTheory, isFalse);
    expect(c.isWrittenTheory, isTrue);
    expect(c.hasVisualTheory, isFalse);
  });
}

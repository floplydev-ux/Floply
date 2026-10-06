import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/mentor_lesson.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';
import 'package:poker_trainer/screens/academy/widgets/educational_panel.dart';
import 'package:poker_trainer/screens/academy/widgets/poker_table_view.dart';
import 'package:poker_trainer/screens/academy/widgets/table_explanation_view.dart';

/// Tamaños reales de teléfonos verticales (dp lógicos).
const _phones = <(String, Size)>[
  ('320x640', Size(320, 640)),
  ('360x640', Size(360, 640)),
  ('390x844', Size(390, 844)),
  ('412x915', Size(412, 915)),
  ('430x932', Size(430, 932)),
];

AcademyProgress _allDone() {
  final p = AcademyProgress();
  for (final id in Curriculum.lessonOrder) {
    p.entry(id).completed = true;
  }
  return p;
}

Future<AcademyController> _mount(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final c = AcademyController(
    engine: PokerTrainerEngine(seed: 4),
    store: InMemoryAcademyStore(),
    userName: 'Dani',
  );
  await c.load();
  c.progress = _allDone();

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AcademyScreen(controller: c)),
  ));
  await tester.pumpAndSettle();
  return c;
}

Size _screen(WidgetTester tester) =>
    tester.view.physicalSize / tester.view.devicePixelRatio;

PokerTableView _tableWidget(WidgetTester tester) =>
    tester.widget<PokerTableView>(find.byType(PokerTableView));

RenderObject _tableRender(WidgetTester tester) =>
    tester.renderObject(find.byType(PokerTableView));

/// El texto educativo del paso está completo y dentro del panel (nunca
/// flotando sobre la mesa, nunca truncado).
void _expectExplanationInPanel(WidgetTester tester, String text, String why) {
  final panel = find.byKey(kAcademyEducationalPanelKey);
  expect(panel, findsOneWidget, reason: '$why: no hay panel educativo');
  final inPanel = find.descendant(of: panel, matching: find.text(text));
  expect(inPanel, findsOneWidget, reason: '$why: el texto no está en el panel');
  expect(tester.renderObject<RenderParagraph>(inPanel).didExceedMaxLines,
      isFalse,
      reason: '$why: el texto educativo se truncó');
}

void main() {
  // ---------------------------------------------------------------
  // Reparto vertical: depende del tamaño, no del contenido.
  // ---------------------------------------------------------------
  group('TableExplanationView.tableHeightFor', () {
    test('derivado del alto de pantalla, con piso/techo razonables', () {
      for (final (name, size) in _phones) {
        final h = TableExplanationView.tableHeightFor(size);
        expect(h, greaterThanOrEqualTo(230), reason: '$name mesa muy chica');
        // El área de la mesa no se dispara respecto del ancho.
        expect(h, lessThanOrEqualTo(size.width * 1.08),
            reason: '$name área desproporcionada');
        // Poco más de la mitad de la pantalla: deja sitio a panel +
        // controles (el panel se ajusta a su contenido).
        expect(h, lessThanOrEqualTo(size.height * 0.58),
            reason: '$name mesa se come la pantalla');
        // Determinista: no depende del contenido.
        expect(TableExplanationView.tableHeightFor(size), h);
      }
    });
  });

  // ---------------------------------------------------------------
  // Teoría: MISMA mesa entre pasos; cambia el foco y el texto.
  // ---------------------------------------------------------------
  for (final (name, size) in _phones) {
    testWidgets('$name — teoría: mesa persistente, foco y texto cambian',
        (tester) async {
      final c = await _mount(tester, size);

      // N1.1, N1.2, N1.3 y N1.4 ya no tienen guion de mesa legado (piloto
      // de 3 bloques: teoría escrita → ejemplo de mesa → ejercicios) — se
      // prueban aparte en `academy_1_1_pilot_test.dart` /
      // `academy_1_2_pilot_test.dart` / `academy_1_3_pilot_test.dart` (1.4
      // todavía no tiene su propio test dedicado — pendiente, no bloquea
      // esta prueba). Acá usamos 2.1/3.1/3.3/5.1, que sí siguen resolviendo
      // a un guion legado real.
      for (final id in ['2.1', '3.1', '3.3', '5.1']) {
        c.openLesson(id);
        await tester.pumpAndSettle();
        expect(c.isInteractiveTheory, isTrue, reason: '$name $id');

        RenderObject? prevRender;
        Size? prevSize;
        Set<TableAnchor>? prevHighlight;

        var guard = 0;
        // Recorre el guion de mesa; algunos subniveles tienen fichas de
        // teoría redactada después (sin mesa) que no interesan a este test.
        while (c.isInteractiveTheory && guard++ < 25) {
          final why = '$name $id paso ${c.tableStep + 1}';
          expect(tester.takeException(), isNull, reason: why);

          // La explicación vive en el panel, completa.
          _expectExplanationInPanel(tester, c.currentBubbleText!, why);
          // Nunca hay texto educativo suelto sobre la mesa.
          expect(
            find.descendant(
              of: find.byType(PokerTableView),
              matching: find.text(c.currentBubbleText!),
            ),
            findsNothing,
            reason: '$why: texto sobre la mesa',
          );

          final render = _tableRender(tester);
          final tableSize = tester.getSize(find.byType(PokerTableView));
          final highlight = _tableWidget(tester).highlight;

          if (prevRender != null) {
            // Misma instancia de mesa: no se reconstruyó ni se navegó.
            expect(identical(render, prevRender), isTrue,
                reason: '$why: la mesa se reconstruyó');
            // Tamaño estable: la mesa no salta.
            expect(tableSize, prevSize, reason: '$why: la mesa cambió de tamaño');
          }

          prevRender = render;
          prevSize = tableSize;
          prevHighlight = highlight;

          final last = c.isLastTableStep && !c.hasWrittenTheory;
          await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
          await tester.pumpAndSettle();
        }

        // Hubo al menos un paso donde el foco cambió respecto del anterior.
        expect(prevHighlight, isNotNull);
        c.exitLesson();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('el foco cambia entre pasos (3.1 recorre varias posiciones)',
      (tester) async {
    final c = await _mount(tester, const Size(390, 844));
    c.openLesson('3.1');
    await tester.pumpAndSettle();

    final seen = <Set<TableAnchor>>[];
    var guard = 0;
    while (c.isInteractiveTheory && guard++ < 25) {
      seen.add(_tableWidget(tester).highlight);
      final last = c.isLastTableStep && !c.hasWrittenTheory;
      await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
      await tester.pumpAndSettle();
    }
    // Al menos dos focos distintos a lo largo de la lección.
    final distinct = <String>{for (final s in seen) s.toString()};
    expect(distinct.length, greaterThan(1),
        reason: 'el foco no cambió nunca');
  });

  // ---------------------------------------------------------------
  // Nivel 2 showdown: hero + rival + board + ganador, misma mesa.
  // ---------------------------------------------------------------
  for (final (name, size) in _phones) {
    testWidgets('$name — showdown 2.1: cartas visibles, explicación completa',
        (tester) async {
      final c = await _mount(tester, size);
      c.openLesson('2.1');
      await tester.pumpAndSettle();

      RenderObject? prev;
      while (c.isInteractiveTheory) {
        final why = '$name 2.1 paso ${c.tableStep + 1}';
        _expectExplanationInPanel(tester, c.currentBubbleText!, why);
        expect(find.byKey(kAcademyTableBoardKey), findsOneWidget,
            reason: '$why: falta el board');
        final r = _tableRender(tester);
        if (prev != null) {
          expect(identical(r, prev), isTrue, reason: '$why: mesa reconstruida');
        }
        prev = r;
        final last = c.isLastTableStep && !c.hasWrittenTheory;
        await tester.tap(find.text(last ? 'PRACTICAR' : 'CONTINUAR'));
        await tester.pumpAndSettle();
      }
      // Clase de mentor de T051 (reemplaza su ficha) + fichas de teoría
      // redactada del resto de N2.1 (sin mesa): recorrer y salir.
      while (c.isMentorLesson || c.isWrittenTheory) {
        if (c.isMentorLesson) {
          final beat = c.currentMentorBeat;
          final label = (beat is MentorCheckBeat && c.mentorCheckAnswer == null)
              ? beat.check.options.first.label
              : c.mentorContinueLabel;
          await tester.tap(find.text(label));
        } else {
          await tester.tap(
              find.text(c.isLastWrittenTheory ? 'PRACTICAR' : 'CONTINUAR'));
        }
        await tester.pumpAndSettle();
      }

      // Ejercicio de showdown.
      expect(c.isInteractiveExercise, isTrue);
      final ex = c.currentInteractive!;
      _expectExplanationInPanel(
          tester, c.interactiveQuestionText!, '$name 2.1 pregunta');
      expect(find.byKey(kAcademyTableHeroCardsKey), findsOneWidget);
      expect(find.byKey(kAcademyTableBoardKey), findsOneWidget);

      await tester.tap(find.text(
          c.resolveInteractive(ex.choices[ex.bestChoiceIndex].label)));
      await tester.pumpAndSettle();
      _expectExplanationInPanel(
        tester,
        c.resolveInteractive(ex.choices[ex.bestChoiceIndex].feedback),
        '$name 2.1 feedback',
      );
      expect(tester.takeException(), isNull);
    });
  }

  // ---------------------------------------------------------------
  // Ejercicios: opciones largas enteras; feedback completo; misma mesa.
  // ---------------------------------------------------------------
  for (final (name, size) in _phones) {
    testWidgets('$name — 3.4 (ejercicios de posición): opciones largas '
        'enteras, feedback completo', (tester) async {
      final c = await _mount(tester, size);
      // El set 3.4 histórico (posición postflop, opciones de frase larga)
      // quedó re-anclado a N3.3, que arranca con teoría interactiva.
      c.openLesson('3.3');
      await tester.pumpAndSettle();
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
      expect(c.isInteractiveExercise, isTrue);

      var guard = 0;
      while (c.phase == AcademyPhase.exercise && guard++ < 30) {
        final ex = c.currentInteractive!;
        final why = '$name 3.3 ítem ${c.itemNumber}';
        final screen = _screen(tester);

        // Solo las opciones de frase larga (las cortas como "UTG" pueden
        // coincidir con etiquetas de la mesa y no corren riesgo de truncarse).
        for (final ch in ex.choices.where((x) => x.label.length > 14)) {
          final label = c.resolveInteractive(ch.label);
          final f = find.text(label);
          expect(f, findsOneWidget, reason: '$why: falta "$label"');
          expect(tester.renderObject<RenderParagraph>(f).didExceedMaxLines,
              isFalse,
              reason: '$why: opción truncada "$label"');
          expect(tester.getRect(f).bottom, lessThanOrEqualTo(screen.height + 1),
              reason: '$why: opción fuera de pantalla "$label"');
        }
        expect(tester.takeException(), isNull, reason: why);

        final beforeAnswer = _tableRender(tester);
        // Elegir la opción de label más largo (única, sin colisión con la mesa).
        var pick = 0;
        for (var i = 1; i < ex.choices.length; i++) {
          if (ex.choices[i].label.length > ex.choices[pick].label.length) {
            pick = i;
          }
        }
        await tester
            .tap(find.text(c.resolveInteractive(ex.choices[pick].label)));
        await tester.pumpAndSettle();

        // Tras responder: misma mesa, feedback en el panel.
        expect(identical(_tableRender(tester), beforeAnswer), isTrue,
            reason: '$why: la mesa se reconstruyó al responder');
        _expectExplanationInPanel(
          tester,
          c.resolveInteractive(ex.choices[pick].feedback),
          '$why feedback',
        );

        var steps = 0;
        while (c.interactiveChoice != null &&
            c.phase == AcademyPhase.exercise &&
            steps++ < 12) {
          final btn = ['CONTINUAR', 'SIGUIENTE', 'VER RESULTADO']
              .map(find.text)
              .firstWhere((x) => x.evaluate().isNotEmpty);
          await tester.tap(btn);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$why explicación');
        }
      }
      expect(c.phase, AcademyPhase.result);
    });
  }

  // ---------------------------------------------------------------
  // Panel con texto larguísimo: scroll interno, nunca truncado.
  // ---------------------------------------------------------------
  testWidgets('EducationalPanel: texto larguísimo => scrollea, no trunca',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final long = 'Esta es una explicación deliberadamente muy larga. ' * 14;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 150,
          child: EducationalPanel(text: long, stepNumber: 3),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final f = find.text(long);
    expect(f, findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(f).didExceedMaxLines, isFalse);
    expect(find.byType(Scrollable), findsWidgets);
  });
}

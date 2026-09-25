import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/scripts/table_builder.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/screens/academy/widgets/lesson_widgets.dart';
import 'package:poker_trainer/screens/academy/widgets/table_explanation_view.dart';

/// **Demo de validación de todo el sistema (Fase 14 del rework de mesa)**:
/// una mano completa de NL2 6-max — BTN A♠Q♠ vs BB — recorrida paso a paso
/// con la arquitectura real (`TableBuilder`, `TablePositions`,
/// `TableSnapshot`, `TableExplanationView`, `LessonNavControls`), sin
/// sistema paralelo alguno.
///
/// Demuestra a la vez: posiciones derivadas de [TablePositions] (no
/// tipeadas a mano), orden de acción real, sentido horario en pantalla,
/// hero, cartas, board progresivo, apuestas, pot, fold, winner, burbuja y
/// AVANZAR — sin overflow en los tres anchos de referencia.
void main() {
  final positions = TablePositions(0); // héroe en el botón

  const heroCards = ['As', 'Qs'];
  const flop = ['Qc', '7d', '2s'];

  // --- Los 6 pasos de la mano, construidos con la arquitectura real ---
  final utg = positions.slotOf(Position.utg);
  final hj = positions.slotOf(Position.hj);
  final co = positions.slotOf(Position.co);
  final btn = positions.slotOf(Position.btn); // == 0, el héroe
  final sb = positions.slotOf(Position.sb);
  final bb = positions.slotOf(Position.bb);

  List<SeatState> baseSeats({
    Set<int> folded = const {},
    Map<int, String> actions = const {},
    Map<int, double> bets = const {},
    List<String>? heroCardsOverride,
    bool bbCards = false,
    Set<int> winners = const {},
  }) {
    final seats = TableBuilder.seats(
      labels: positions.labels,
      heroSlot: btn,
      cards: {btn: heroCardsOverride ?? heroCards, if (bbCards) bb: heroCards},
      actions: actions,
      bets: bets,
      folded: folded,
    );
    return [
      for (final s in seats)
        winners.contains(s.slot) ? s.copyWith(winner: true) : s,
    ];
  }

  final steps = <(
    TableSnapshot table,
    String bubble,
    TableAnchor anchor,
    List<TableAnchor> highlight
  )>[
    (
      TableSnapshot(seats: baseSeats(), buttonSlot: btn),
      'Estás en el botón con A♠Q♠.',
      TableAnchor.heroCards,
      const [],
    ),
    (
      TableSnapshot(
          seats: baseSeats(folded: {utg}, actions: {utg: 'FOLD'}),
          buttonSlot: btn),
      'UTG se retira.',
      TableAnchor.seat(utg),
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(folded: {utg, hj}, actions: {utg: 'FOLD', hj: 'FOLD'}),
        buttonSlot: btn,
      ),
      'HJ también.',
      TableAnchor.seat(hj),
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(
            folded: {utg, hj, co},
            actions: {utg: 'FOLD', hj: 'FOLD', co: 'FOLD'}),
        buttonSlot: btn,
      ),
      'Y CO. La acción llega a vos.',
      TableAnchor.seat(co),
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(
          folded: {utg, hj, co},
          actions: {utg: 'FOLD', hj: 'FOLD', co: 'FOLD', btn: 'SUBE'},
          bets: {btn: 2.5},
        ),
        buttonSlot: btn,
        potBb: 2.5,
      ),
      'Subís a 2.5 BB.',
      TableAnchor.bet(btn),
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(
          folded: {utg, hj, co, sb},
          actions: {
            utg: 'FOLD',
            hj: 'FOLD',
            co: 'FOLD',
            sb: 'FOLD',
            bb: 'PAGA'
          },
          bets: {bb: 2.5},
          bbCards: true,
        ),
        buttonSlot: btn,
        potBb: 5,
      ),
      'SB se retira. La BB paga.',
      TableAnchor.seat(bb),
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(folded: {utg, hj, co, sb}, bbCards: true),
        board: flop,
        buttonSlot: btn,
        potBb: 5,
      ),
      'Flop: Q♣7♦2♠. Tenés pareja de reinas con as.',
      TableAnchor.board,
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(
          folded: {utg, hj, co, sb},
          actions: {bb: 'CHEQUEA'},
          bbCards: true,
        ),
        board: flop,
        buttonSlot: btn,
        potBb: 5,
      ),
      'La BB chequea.',
      TableAnchor.seat(bb),
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(
          folded: {utg, hj, co, sb},
          actions: {bb: 'CHEQUEA', btn: 'APUESTA'},
          bets: {btn: 3},
          bbCards: true,
        ),
        board: flop,
        buttonSlot: btn,
        potBb: 5,
      ),
      'Apostás 3 BB — tenés la mejor mano y querés valor.',
      TableAnchor.bet(btn),
      const [],
    ),
    (
      TableSnapshot(
        seats: baseSeats(
          folded: {utg, hj, co, sb, bb},
          actions: {bb: 'FOLD'},
          winners: {btn},
        ),
        board: flop,
        buttonSlot: btn,
        potBb: 8,
      ),
      'La BB se retira. Ganás el pote de 8 BB.',
      TableAnchor.seat(btn),
      [TableAnchor.seat(btn), TableAnchor.pot],
    ),
  ];

  Future<void> pumpDemo(WidgetTester tester, Size size) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: _DemoHarness(steps: steps),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  test(
      'las posiciones de la demo vienen de TablePositions, no tipeadas a '
      'mano — y coinciden con TableBuilder.btnHero', () {
    for (final e in TableBuilder.btnHero.entries) {
      expect(positions.positionOf(e.key).label, e.value);
    }
  });

  test(
      'el orden de folds de la demo (UTG, HJ, CO) respeta el orden real '
      'de preflop', () {
    final order = positions.order(Street.preflop);
    final utgIdx = order.indexOf(utg);
    final hjIdx = order.indexOf(hj);
    final coIdx = order.indexOf(co);
    final btnIdx = order.indexOf(btn);
    final sbIdx = order.indexOf(sb);
    expect(utgIdx < hjIdx && hjIdx < coIdx && coIdx < btnIdx && btnIdx < sbIdx,
        isTrue,
        reason: 'UTG→HJ→CO→BTN→SB debe respetarse en ese orden');
  });

  for (final (name, size) in <(String, Size)>[
    ('360x640', const Size(360, 640)),
    ('390x844', const Size(390, 844)),
    ('430x932', const Size(430, 932)),
  ]) {
    testWidgets(
        '$name — demo completa: BTN A♠Q♠ vs BB, preflop → flop → apuesta → '
        'fold → winner, sin overflow', (tester) async {
      await pumpDemo(tester, size);

      for (var i = 0; i < steps.length; i++) {
        expect(find.text(steps[i].$2), findsOneWidget, reason: 'paso $i');
        expect(tester.takeException(), isNull, reason: 'paso $i');
        if (i < steps.length - 1) {
          await tester.tap(find.text('AVANZAR'));
          await tester.pumpAndSettle();
        }
      }

      // Último paso: BTN es winner — el tratamiento de victoria es un
      // marcador con check (no un cartel de texto "GANÓ").
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ATRÁS retrocede en la demo sin romper nada', (tester) async {
    await pumpDemo(tester, const Size(390, 844));
    await tester.tap(find.text('AVANZAR'));
    await tester.pumpAndSettle();
    expect(find.text(steps[1].$2), findsOneWidget);

    await tester.tap(find.text('ATRÁS'));
    await tester.pumpAndSettle();
    expect(find.text(steps[0].$2), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Harness mínimo que reproduce exactamente el patrón de
/// `InteractiveTableLesson` (mesa + `TableExplanationView` +
/// `LessonNavControls`), sin pasar por `AcademyController` — no es un
/// sistema nuevo, es la misma composición que ya usa la Academia.
class _DemoHarness extends StatefulWidget {
  const _DemoHarness({required this.steps});

  final List<(TableSnapshot, String, TableAnchor, List<TableAnchor>)> steps;

  @override
  State<_DemoHarness> createState() => _DemoHarnessState();
}

class _DemoHarnessState extends State<_DemoHarness> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final (table, bubble, anchor, highlight) = widget.steps[_i];
    return Column(
      children: [
        Expanded(
          child: TableExplanationView(
            table: table,
            text: bubble,
            anchor: anchor,
            highlight: highlight,
            dimOthers: false,
            stepNumber: _i + 1,
            transitionTag: 'demo$_i',
          ),
        ),
        const SizedBox(height: 10),
        LessonNavControls(
          canGoBack: _i > 0,
          buttonLabel: 'AVANZAR',
          counter: '${_i + 1} / ${widget.steps.length}',
          onBack: () =>
              setState(() => _i = (_i - 1).clamp(0, widget.steps.length - 1)),
          onNext: () =>
              setState(() => _i = (_i + 1).clamp(0, widget.steps.length - 1)),
        ),
      ],
    );
  }
}

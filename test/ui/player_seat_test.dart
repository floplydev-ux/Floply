import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';
import 'package:poker_trainer/screens/academy/widgets/table/player_seat.dart';

Widget _harness(SeatState seat) => MaterialApp(
      home: Scaffold(
        body: Center(child: PlayerSeat(seat: seat, scale: 1)),
      ),
    );

const _base = SeatState(
  slot: 1,
  label: 'BTN',
  name: 'Rival',
  stackBb: 97,
  betBb: 0,
);

void main() {
  testWidgets('un asiento sin acción muestra el stack normalmente',
      (tester) async {
    await tester.pumpWidget(_harness(_base));
    await tester.pumpAndSettle();

    expect(find.textContaining('97'), findsOneWidget);
  });

  testWidgets('cuando SeatState.action cambia a RAISE, el asiento muestra '
      'RAISE + el monto en vez del stack (mismo dato que ya arma '
      'CoachTableSnapshot, sin estado paralelo)', (tester) async {
    await tester.pumpWidget(_harness(_base));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_harness(
      _base.copyWith(action: 'RAISE', betBb: 8, stackBb: 89),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('RAISE'), findsOneWidget);
    expect(find.text('8 BB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un asiento foldeado sigue mostrando su avatar con ✕ y panel '
      'gris — eso no depende del temporizador de acción', (tester) async {
    await tester.pumpWidget(_harness(_base));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_harness(
      _base.copyWith(action: 'FOLD', folded: true, cards: []),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

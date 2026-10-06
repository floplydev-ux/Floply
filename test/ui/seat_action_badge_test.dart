import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/screens/academy/widgets/table/seat_action_badge.dart';

const _stackText = 'STACK 97';

Widget _harness({required String? action, required double? amountBb}) {
  return MaterialApp(
    home: Scaffold(
      body: SeatActionBadge(
        action: action,
        amountBb: amountBb,
        stackLine: const Text(_stackText),
        scale: 1,
      ),
    ),
  );
}

void main() {
  testWidgets('al montar con una acción ya vigente (ciegas ya puestas), '
      'muestra el stack — nunca "revive" una acción vieja', (tester) async {
    await tester.pumpWidget(_harness(action: 'POST', amountBb: 0.5));
    await tester.pumpAndSettle();

    expect(find.text(_stackText), findsOneWidget);
    expect(find.text('POST'), findsNothing);
  });

  testWidgets('una acción nueva reemplaza el stack de inmediato', (tester) async {
    await tester.pumpWidget(_harness(action: null, amountBb: null));
    await tester.pumpAndSettle();
    expect(find.text(_stackText), findsOneWidget);

    await tester.pumpWidget(_harness(action: 'CALL', amountBb: 2));
    await tester.pump(); // dispara el cambio de estado
    await tester.pump(const Duration(milliseconds: 250)); // deja terminar la transición

    expect(find.text('CALL'), findsOneWidget);
    expect(find.text('2 BB'), findsOneWidget);
    expect(find.text(_stackText), findsNothing);
  });

  testWidgets('después de ~2.8s vuelve solo al stack', (tester) async {
    await tester.pumpWidget(_harness(action: null, amountBb: null));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_harness(action: 'BET', amountBb: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('BET'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600)); // todavía visible
    expect(find.text('BET'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300)); // ya pasaron los ~2.8s
    await tester.pump(const Duration(milliseconds: 250)); // transición de vuelta
    expect(find.text('BET'), findsNothing);
    expect(find.text(_stackText), findsOneWidget);
  });

  testWidgets('una segunda acción del mismo asiento mientras se muestra la '
      'primera actualiza de inmediato y reinicia el temporizador',
      (tester) async {
    await tester.pumpWidget(_harness(action: null, amountBb: null));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_harness(action: 'CALL', amountBb: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('CALL'), findsOneWidget);

    // 2s después (antes de que CALL se hubiera ocultado solo) llega RAISE.
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpWidget(_harness(action: 'RAISE', amountBb: 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('RAISE'), findsOneWidget);
    expect(find.text('8 BB'), findsOneWidget);
    expect(find.text('CALL'), findsNothing);

    // Otros 2s (4s desde el CALL original, pero solo 2s desde el RAISE):
    // el temporizador se reinició, así que RAISE sigue visible.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('RAISE'), findsOneWidget);

    // Completa los ~2.8s propios del RAISE.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('RAISE'), findsNothing);
    expect(find.text(_stackText), findsOneWidget);
  });

  testWidgets('CHECK/FOLD/ALL-IN se muestran sin monto (una sola línea)',
      (tester) async {
    for (final action in ['CHECK', 'FOLD', 'ALL-IN']) {
      await tester.pumpWidget(_harness(action: null, amountBb: null));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_harness(action: action, amountBb: null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text(action), findsOneWidget, reason: action);
      expect(find.textContaining('BB'), findsNothing, reason: action);
    }
  });

  testWidgets('repetir el mismo valor de acción no reinicia nada (no hay '
      'una acción "nueva" real)', (tester) async {
    await tester.pumpWidget(_harness(action: null, amountBb: null));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_harness(action: 'CALL', amountBb: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('CALL'), findsOneWidget);

    // 2.5s después, un rebuild con el MISMO valor de acción (p. ej. otro
    // asiento actuó y toda la mesa se re-renderiza) no debería reiniciar
    // el temporizador de este asiento.
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpWidget(_harness(action: 'CALL', amountBb: 2));
    await tester.pump();

    // 300ms más (2.8s totales desde el CALL original) alcanza para que
    // se oculte, aunque hubo un rebuild intermedio con el mismo valor.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('CALL'), findsNothing);
    expect(find.text(_stackText), findsOneWidget);
  });
}

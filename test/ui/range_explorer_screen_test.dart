import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/range_explorer_screen.dart';

Widget _harness() => const MaterialApp(home: RangeExplorerScreen());

void main() {
  testWidgets('muestra la grilla real para BTN por defecto', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Button'), findsOneWidget);
    // AA está en todos los rangos de apertura -> exactamente una celda.
    expect(find.text('AA'), findsOneWidget);
    expect(find.text(AppStrings.rangesTapHint), findsOneWidget);
  });

  testWidgets('tocar una posición cambia el rango mostrado', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('UTG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Under the Gun'), findsOneWidget);
  });

  testWidgets('la BB muestra el aviso en vez de la grilla', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('BB'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.rangesBbTitle), findsOneWidget);
    expect(find.text('AA'), findsNothing);
  });

  testWidgets('tocar una mano de la grilla muestra el detalle', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('AA'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // AA aparece dos veces: la celda de la grilla + el valor del detalle.
    expect(find.text('AA'), findsNWidgets(2));
    expect(find.text('100%'), findsOneWidget); // frecuencia
    expect(find.text('6'), findsOneWidget); // combos de un par
    expect(find.text(AppStrings.rangesTapHint), findsNothing);
  });

  testWidgets('cambiar de posición después de elegir una mano no rompe',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('AA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UTG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el botón de volver hace pop', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RangeExplorerScreen()),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(RangeExplorerScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(RangeExplorerScreen), findsNothing);
  });

  testWidgets('responsive: sin overflow en anchos chicos y grandes',
      (tester) async {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '${size.width}x${size.height}');
    }
  });
}

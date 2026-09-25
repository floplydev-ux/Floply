import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/pot_odds_calculator_screen.dart';

Widget _harness() =>
    const MaterialApp(home: PotOddsCalculatorScreen());

void main() {
  testWidgets('muestra un resultado real con los valores por defecto',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // pot=10, call=5 -> finalPot=15, requiredEquity=5/15=33.3%, ratio 2:1.
    expect(find.text('33.3%'), findsOneWidget);
    expect(find.text('15 BB'), findsOneWidget);
    expect(find.text('2 : 1'), findsOneWidget);
  });

  testWidgets('recalcula en vivo al cambiar los campos', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '20');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // pot=20, call=5 -> finalPot=25, requiredEquity=20%.
    expect(find.text('20.0%'), findsOneWidget);
    expect(find.text('25 BB'), findsOneWidget);
  });

  testWidgets('entrada inválida muestra el error y no rompe', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.potOddsInvalidInput), findsOneWidget);
  });

  testWidgets('valores negativos muestran el error (PotOddsEngine los '
      'rechaza)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '-5');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.potOddsInvalidInput), findsOneWidget);
  });

  testWidgets('el botón de volver hace pop', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PotOddsCalculatorScreen()),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(PotOddsCalculatorScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PotOddsCalculatorScreen), findsNothing);
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

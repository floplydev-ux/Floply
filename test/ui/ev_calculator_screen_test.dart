import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/tool_explainer_store.dart';
import 'package:poker_trainer/screens/tools/ev_calculator_screen.dart';

Widget _harness() => const MaterialApp(home: EvCalculatorScreen());

void main() {
  // Ver el mismo comentario en blocker_explorer_screen_test.dart: evita
  // la carrera del sistema de explicación contextual (Grupo 3).
  setUpAll(() async {
    await defaultToolExplainerStore.setDismissed('ev_calculator', true);
  });

  testWidgets('muestra un resultado real con los valores por defecto',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // pot=10, call=5 -> finalPot=15, requiredEquity=33.3%.
    // equity=40% -> EV = 0.4*15 - 5 = +1 BB (profitable).
    expect(find.text('+1 BB'), findsOneWidget);
    expect(find.text('33.3%'), findsOneWidget);
    expect(find.text(AppStrings.evProfitableLabel), findsOneWidget);
  });

  testWidgets('equity por debajo de la necesaria da EV negativo',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final equityField = find.byType(TextField).at(2);
    await tester.enterText(equityField, '10');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // equity=10% -> EV = 0.1*15 - 5 = -3.5 BB.
    expect(find.text('-3.5 BB'), findsOneWidget);
    expect(find.text(AppStrings.evLosingLabel), findsOneWidget);
  });

  testWidgets('equity exactamente igual a la necesaria da break-even',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // requiredEquity para pot=10/call=5 es 33.33...%
    final equityField = find.byType(TextField).at(2);
    await tester.enterText(equityField, '${100 / 3}');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.evBreakEvenLabel), findsOneWidget);
  });

  testWidgets('equity fuera de 0-100 muestra el error', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final equityField = find.byType(TextField).at(2);
    await tester.enterText(equityField, '150');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.evInvalidInput), findsOneWidget);
  });

  testWidgets('entrada no numérica muestra el error y no rompe', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'xyz');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.evInvalidInput), findsOneWidget);
  });

  testWidgets('precarga desde otra herramienta (Pot Odds / Equity)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EvCalculatorScreen(
        initialPotBb: 20,
        initialCallBb: 10,
        initialEquityPercent: 50,
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // finalPot=30, requiredEquity=33.3%; EV = 0.5*30 - 10 = +5 BB.
    expect(find.text('+5 BB'), findsOneWidget);
    expect(find.text('33.3%'), findsOneWidget);
  });

  testWidgets('el botón de volver hace pop', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EvCalculatorScreen()),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(EvCalculatorScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EvCalculatorScreen), findsNothing);
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

  group('modo "Apostar / subir" (V2)', () {
    testWidgets('con los valores por defecto muestra el EV y el aviso de '
        'la rama sin modelar', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.evModeBetLabel));
      await tester.pumpAndSettle();

      // pot=10, bet=5, fold=40%, call=50%, equity=45%.
      // finalPotIfCalled = 10 + 2*5 = 20.
      // evFold = 0.4*10 = 4; evCall = 0.5*(0.45*20 - 5) = 0.5*4 = 2.
      // evBb = 6. unmodeled = 100% - 40% - 50% = 10%.
      expect(tester.takeException(), isNull);
      expect(find.text('+6 BB'), findsOneWidget);
      expect(find.text('+4 BB'), findsOneWidget);
      expect(find.text('+2 BB'), findsOneWidget);
      expect(find.text(AppStrings.evProfitableLabel), findsOneWidget);
      expect(find.text(AppStrings.evBetUnmodeledWarning(10.0)), findsOneWidget);
    });

    testWidgets('fold% + call% = 100% no muestra el aviso de rama sin '
        'modelar', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.evModeBetLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(3), '60'); // % call
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // evFold = 4; evCall = 0.6*(0.45*20-5) = 0.6*4 = 2.4; evBb = 6.4.
      expect(find.text('+6.4 BB'), findsOneWidget);
      expect(find.textContaining('no está incluida en este cálculo'),
          findsNothing);
    });

    testWidgets('% fold + % call > 100 muestra el error', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.evModeBetLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(2), '70'); // % fold
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.evBetInvalidInput), findsOneWidget);
    });

    testWidgets('una apuesta de 0 muestra el error (eso es un check)',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.evModeBetLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '0'); // tu apuesta
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.evBetInvalidInput), findsOneWidget);
    });

    testWidgets('entrada no numérica en el modo apostar muestra el error',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.evModeBetLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'xyz');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.evBetInvalidInput), findsOneWidget);
    });
  });

  testWidgets('cambiar de modo no rompe nada y conserva el resultado de '
      'cada uno', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.evModeBetLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.evModeCallLabel));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // De vuelta en "Pagar un call": el resultado por defecto sigue ahí.
    expect(find.text('+1 BB'), findsOneWidget);
  });
}

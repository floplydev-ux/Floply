import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/tool_explainer_store.dart';
import 'package:poker_trainer/screens/tools/ev_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/pot_odds_calculator_screen.dart';

Widget _harness() =>
    const MaterialApp(home: PotOddsCalculatorScreen());

void main() {
  // Ver el mismo comentario en blocker_explorer_screen_test.dart: evita
  // la carrera del sistema de explicación contextual (Grupo 3).
  setUpAll(() async {
    await defaultToolExplainerStore.setDismissed('pot_odds', true);
  });

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

    // Índice 1 = campo "Lo que tenés que pagar" (0 = bote, 2 = tu equity
    // real, agregado después — no es parte del cálculo de PotOddsEngine).
    await tester.enterText(find.byType(TextField).at(1), '-5');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.potOddsInvalidInput), findsOneWidget);
  });

  testWidgets('el campo "Tu equity real" compara contra la necesaria sin '
      'decidir por el usuario', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // requiredEquity = 33.3%, tu equity 50% -> la supera.
    expect(
      find.text(AppStrings.potOddsEquityComparison(
        yourEquityPct: 50,
        requiredEquityPct: 100 / 3,
      )),
      findsOneWidget,
    );
    // Nunca un veredicto CALL/FOLD.
    expect(find.textContaining('CALL'), findsNothing);
    expect(find.textContaining('FOLD'), findsNothing);
  });

  testWidgets('vacío el campo de equity, no se muestra ninguna comparación',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Tu equity ('), findsNothing);
  });

  testWidgets('precarga desde otra herramienta (pot/call)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PotOddsCalculatorScreen(initialPotBb: 20, initialCallBb: 10),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // finalPot=30, requiredEquity=10/30=33.3%.
    expect(find.text('33.3%'), findsOneWidget);
    expect(find.text('30 BB'), findsOneWidget);
  });

  testWidgets('"Calcular EV" abre EV con pot/call/equity precargados',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.pumpAndSettle();
    final calcEv = find.text(AppStrings.potOddsCalculateEv);
    await tester.ensureVisible(calcEv);
    await tester.pumpAndSettle();
    await tester.tap(calcEv);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EvCalculatorScreen), findsOneWidget);
    // pot=10, call=5, equity=50% -> finalPot=15, EV = 0.5*15-5 = +2.5 BB.
    expect(find.text('+2.5 BB'), findsOneWidget);
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

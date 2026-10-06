import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/blocker_explorer_screen.dart';
import 'package:poker_trainer/screens/tools/combo_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/equity_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/ev_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/pot_odds_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/range/range_explorer_screen.dart';
import 'package:poker_trainer/screens/tools/tools_screen.dart';

void main() {
  testWidgets('muestra las 6 herramientas del hub', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.toolsPotOddsTitle), findsOneWidget);
    expect(find.text(AppStrings.toolsEquityTitle), findsOneWidget);
    expect(find.text(AppStrings.toolsEvTitle), findsOneWidget);
    expect(find.text(AppStrings.toolsComboTitle), findsOneWidget);
    expect(find.text(AppStrings.toolsRangesTitle), findsOneWidget);
    expect(find.text(AppStrings.toolsBlockerTitle), findsOneWidget);
  });

  testWidgets('tocar Pot Odds abre la calculadora real', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsPotOddsTitle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PotOddsCalculatorScreen), findsOneWidget);
  });

  testWidgets('tocar EV abre la calculadora real', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsEvTitle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EvCalculatorScreen), findsOneWidget);
  });

  testWidgets('tocar Equity abre la calculadora real', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsEquityTitle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EquityCalculatorScreen), findsOneWidget);
  });

  testWidgets('tocar Combos abre la calculadora real', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsComboTitle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ComboCalculatorScreen), findsOneWidget);
  });

  testWidgets('tocar Rangos abre la calculadora real', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsRangesTitle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(RangeExplorerScreen), findsOneWidget);
  });

  testWidgets('tocar Blockers abre la calculadora real', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsBlockerTitle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BlockerExplorerScreen), findsOneWidget);
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

      await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '${size.width}x${size.height}');
    }
  });
}

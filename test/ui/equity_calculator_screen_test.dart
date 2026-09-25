import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/equity_calculator_screen.dart';

Widget _harness() => const MaterialApp(home: EquityCalculatorScreen());

/// Toca "Calcular equity" y espera a que termine el cálculo real en el
/// isolate aparte que abre `compute()` (ver el doc-comment de
/// `EquityCalculatorScreen`). El pumping fake-async normal de
/// `pumpAndSettle` no destraba un `Future` que se resuelve desde otro
/// isolate — hace falta `runAsync` y sondear hasta que el spinner de
/// carga desaparezca (éxito o error, cualquiera de los dos apaga el
/// loading state).
Future<void> _tapCalculateAndWaitForIsolate(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.equityCalculateButtonLabel));
  await tester.pump();
  await tester.runAsync(() async {
    for (var i = 0; i < 300; i++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra un resultado real con los valores por defecto '
      '(AK vs AQ, dominación clara)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Mismo caso que EquityEngine ya prueba en el motor (equity_engine_
    // test.dart, "caso clásico de dominación"): hero muy favorito.
    expect(find.text(AppStrings.equityWinLabel), findsOneWidget);
    expect(find.text(AppStrings.equityTieLabel), findsOneWidget);
    expect(find.text(AppStrings.equityLoseLabel), findsOneWidget);
    // "EQUITY" aparece dos veces (título del header + label del stat) a
    // propósito — alcanza con confirmar que el resultado se muestra.
    expect(find.text('EQUITY'), findsNWidgets(2));
  });

  testWidgets('chop exacto (board de full house íntegro) da 50.0% justo',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '2c3d');
    await tester.enterText(fields.at(1), '6h7d');
    await tester.enterText(fields.at(2), '5s5d5c9h9d');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('50.0%'), findsWidgets); // equity, y gana/pierde en 0
    expect(find.text('100.0%'), findsOneWidget); // empatás siempre
  });

  testWidgets('notación de mano inválida muestra el error y no rompe',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'xyz');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.equityInvalidInput), findsOneWidget);
  });

  testWidgets('board con largo inválido (ni 3, 4 ni 5 cartas) muestra el '
      'error', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), '2c7d');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.equityInvalidInput), findsOneWidget);
  });

  testWidgets('carta repetida entre hero y villain muestra el error',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'AhKd');
    await tester.enterText(fields.at(1), 'AhQd');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.equityInvalidInput), findsOneWidget);
  });

  testWidgets('el botón de volver hace pop', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EquityCalculatorScreen()),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(EquityCalculatorScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EquityCalculatorScreen), findsNothing);
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

  group('modo mano vs rango (V2)', () {
    testWidgets('con los valores por defecto, calcular da un resultado real',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.equityModeHandVsRangeLabel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.equityRangeModeHint), findsOneWidget);

      await _tapCalculateAndWaitForIsolate(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('EQUITY'), findsNWidgets(2));
      expect(find.text(AppStrings.equityScenariosLabel), findsOneWidget);
      expect(find.text(AppStrings.equityRangeModeHint), findsNothing);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('rango del rival con notación inválida muestra el error '
        'específico de rangos', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.equityModeHandVsRangeLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'not a range');
      await tester.tap(find.text(AppStrings.equityCalculateButtonLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityRangeInvalidInput), findsOneWidget);
    });

    testWidgets('mano del héroe inválida muestra el error genérico',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.equityModeHandVsRangeLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'xyz');
      await tester.tap(find.text(AppStrings.equityCalculateButtonLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityInvalidInput), findsOneWidget);
    });
  });

  group('modo rango vs rango (V2)', () {
    testWidgets('con los valores por defecto (AA,KK vs QQ,JJ), calcular da '
        'un resultado real', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.equityModeRangeVsRangeLabel));
      await tester.pumpAndSettle();

      await _tapCalculateAndWaitForIsolate(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('EQUITY'), findsNWidgets(2));
      expect(find.text(AppStrings.equityScenariosLabel), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('rango del héroe con notación inválida muestra el error '
        'específico de rangos', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.equityModeRangeVsRangeLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '###');
      await tester.tap(find.text(AppStrings.equityCalculateButtonLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityRangeInvalidInput), findsOneWidget);
    });

    testWidgets('board con largo inválido muestra el error genérico',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.equityModeRangeVsRangeLabel));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(2), '2c7d');
      await tester.tap(find.text(AppStrings.equityCalculateButtonLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityInvalidInput), findsOneWidget);
    });
  });

  testWidgets('cambiar de modo no rompe nada y vuelve a mostrar los campos '
      'de cada uno', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.equityModeHandVsRangeLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.equityModeRangeVsRangeLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.equityModeHandVsHandLabel));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // De vuelta en mano vs mano: el resultado en vivo sigue ahí.
    expect(find.text('EQUITY'), findsNWidgets(2));
  });
}

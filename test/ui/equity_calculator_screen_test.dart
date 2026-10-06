import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/tool_explainer_store.dart';
import 'package:poker_trainer/screens/academy/widgets/table/playing_card.dart';
import 'package:poker_trainer/screens/tools/equity_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/widgets/card_picker.dart';

Widget _harness() => const MaterialApp(home: EquityCalculatorScreen());

/// Elige [card] en el picker de cartas (grilla de 52) que ya está abierto
/// — mismo mecanismo que usa el usuario real (ver
/// `blocker_explorer_screen_test.dart` para el mismo patrón).
Future<void> _chooseCard(WidgetTester tester, Card card) async {
  final target = find.text(card.pretty);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

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
  await _waitForIsolate(tester);
}

/// Igual que [_tapCalculateAndWaitForIsolate] pero sin el tap inicial —
/// para cuando el cálculo arranca solo (precarga desde otra herramienta,
/// ver el `postFrameCallback` del constructor con `initialHeroHand`/
/// `initialHeroRangeTokens`/etc).
Future<void> _waitForIsolate(WidgetTester tester) async {
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
  // Ver el mismo comentario en blocker_explorer_screen_test.dart: evita
  // la carrera del sistema de explicación contextual (Grupo 3).
  setUpAll(() async {
    await defaultToolExplainerStore.setDismissed('equity_calculator', true);
  });

  testWidgets('muestra un resultado real con los valores por defecto '
      '(AK vs AQ, dominación clara)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Mismo caso que EquityEngine ya prueba en el motor (equity_engine_
    // test.dart, "caso clásico de dominación"): hero muy favorito.
    // ToolResultStat muestra sus labels en mayúsculas (tool_widgets.dart)
    // — no son "Ganás", son "GANÁS".
    expect(find.text(AppStrings.equityWinLabel.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.equityTieLabel.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.equityLoseLabel.toUpperCase()), findsOneWidget);
    // "EQUITY" aparece dos veces (título del header + label del stat) a
    // propósito — alcanza con confirmar que el resultado se muestra.
    expect(find.text('EQUITY'), findsNWidgets(2));
  });

  testWidgets('chop exacto (board de full house íntegro) da 50.0% justo',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Arma hero=2c3d, villain=6h7d, board=5s5d5c9h9d reemplazando carta
    // por carta (mismo gesto real que el usuario: tocar una carta ya
    // puesta reabre el picker) — el board se reemplaza PRIMERO porque
    // sus valores por defecto (2c/7d/9h) chocan con lo que van a
    // necesitar hero/villain más abajo; nunca texto libre, ver
    // `CardGroupField`/`card_picker.dart`. Orden de `PlayingCard` en el
    // árbol: hero[0,1], villain[0,1], board[0,1,2].
    await tester.tap(find.byType(PlayingCard).at(4)); // board[0]: 2c
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.five, Suit.spades));
    await tester.tap(find.byType(PlayingCard).at(5)); // board[1]: 7d
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.five, Suit.diamonds));
    await tester.tap(find.byType(PlayingCard).at(6)); // board[2]: 9h
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.five, Suit.clubs));

    await tester.tap(find.byType(PlayingCard).at(0)); // hero[0]: Ah
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.two, Suit.clubs));
    await tester.tap(find.byType(PlayingCard).at(1)); // hero[1]: Kd
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.three, Suit.diamonds));

    await tester.tap(find.byType(PlayingCard).at(2)); // villain[0]: As
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.six, Suit.hearts));
    await tester.tap(find.byType(PlayingCard).at(3)); // villain[1]: Qd
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.seven, Suit.diamonds));

    // Board todavía tiene 3 cartas (5s5d5c) — agrega el turn y el river.
    await tester.tap(find.byType(DottedCardOutline));
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.nine, Suit.hearts));
    await tester.tap(find.byType(DottedCardOutline));
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.nine, Suit.diamonds));

    expect(tester.takeException(), isNull);
    expect(find.text('50.0%'), findsWidgets); // equity, y gana/pierde en 0
    expect(find.text('100.0%'), findsOneWidget); // empatás siempre
  });

  group('precarga desde otra herramienta', () {
    testWidgets('mano + rango rival -> arranca en modo mano vs rango y '
        'calcula solo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EquityCalculatorScreen(
          initialHeroHand: HoleCards.parse('AhKd'),
          initialVillainRangeTokens: const ['QQ+', 'AKs', 'AKo'],
          initialBoard: const [
            Card(Rank.two, Suit.clubs),
            Card(Rank.seven, Suit.diamonds),
            Card(Rank.nine, Suit.hearts),
          ],
        ),
      ));
      // Un solo `pump` (no `pumpAndSettle`): el cálculo arranca solo
      // desde el `postFrameCallback` y corre en un isolate aparte —
      // `pumpAndSettle` no puede destrabar ese `Future` real, hace falta
      // `_waitForIsolate` (mismo motivo que el flujo con botón).
      await tester.pump();
      await _waitForIsolate(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityModeHandVsRangeLabel), findsOneWidget);
      // Ya calculado sin tocar "Calcular equity".
      expect(find.text(AppStrings.toolsResultPrincipal.toUpperCase()), findsOneWidget);
      expect(find.text(AppStrings.equityScenariosLabel.toUpperCase()), findsOneWidget);
    });

    testWidgets('dos rangos -> arranca en modo rango vs rango, campos '
        'listos pero sin calcular solo (costo real, requiere el botón)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: EquityCalculatorScreen(
          initialHeroRangeTokens: ['AA', 'KK'],
          initialVillainRangeTokens: ['QQ', 'JJ'],
          initialBoard: [
            Card(Rank.two, Suit.clubs),
            Card(Rank.seven, Suit.diamonds),
            Card(Rank.nine, Suit.hearts),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityModeRangeVsRangeLabel), findsOneWidget);
      // Rango vs rango nunca calcula solo (puede ser costoso con rangos
      // reales anchos) — hace falta tocar "Calcular equity" a propósito.
      expect(find.text(AppStrings.toolsResultPrincipal.toUpperCase()), findsNothing);

      await _tapCalculateAndWaitForIsolate(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.toolsResultPrincipal.toUpperCase()), findsOneWidget);
    });

    testWidgets('dos manos concretas -> arranca en modo mano vs mano con '
        'resultado en vivo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EquityCalculatorScreen(
          initialHeroHand: HoleCards.parse('AhKd'),
          initialVillainHand: HoleCards.parse('QhQc'),
          initialBoard: const [
            Card(Rank.two, Suit.clubs),
            Card(Rank.seven, Suit.diamonds),
            Card(Rank.nine, Suit.hearts),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityModeHandVsHandLabel), findsOneWidget);
      expect(find.text(AppStrings.toolsResultPrincipal.toUpperCase()), findsOneWidget);
    });
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
      expect(find.text(AppStrings.equityScenariosLabel.toUpperCase()), findsOneWidget);
      expect(find.text(AppStrings.equityRangeModeHint), findsNothing);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('rango del rival con notación inválida muestra el error '
        'específico de rangos', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.equityModeHandVsRangeLabel));
      await tester.pumpAndSettle();

      // En este modo el único TextField real es el rango del rival —
      // hero y board se eligen con el picker de cartas.
      await tester.enterText(find.byType(TextField), 'not a range');
      await tester.tap(find.text(AppStrings.equityCalculateButtonLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.equityRangeInvalidInput), findsOneWidget);
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
      expect(find.text(AppStrings.equityScenariosLabel.toUpperCase()), findsOneWidget);
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

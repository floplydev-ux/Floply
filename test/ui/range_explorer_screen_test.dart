import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/tool_explainer_store.dart';
import 'package:poker_trainer/persistence/saved_range_store.dart';
import 'package:poker_trainer/screens/tools/blocker_explorer_screen.dart';
import 'package:poker_trainer/screens/tools/equity_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/range/range_explorer_controller.dart';
import 'package:poker_trainer/screens/tools/range/range_explorer_screen.dart';
import 'package:poker_trainer/screens/tools/widgets/card_picker.dart';

// Cada test arma su propio controller con un `InMemorySavedRangeStore`
// nuevo — el `defaultSavedRangeStore` real es un singleton por archivo:
// compartirlo entre tests haría que guardar un rango en un test se
// filtre a la lista "Mis Rangos" de otro.
Widget _harness() =>
    MaterialApp(home: RangeExplorerScreen(controller: RangeExplorerController(
      store: InMemorySavedRangeStore(),
    )));

/// Mismo helper que `blocker_explorer_screen_test.dart` — elige [card] en
/// el picker de 52 ya abierto.
Future<void> _chooseCard(WidgetTester tester, Card card) async {
  final target = find.text(card.pretty);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Cierra el bottom sheet de detalle tocando el scrim por encima de él
/// (un `showModalBottomSheet` no cubre toda la pantalla, así que el
/// borde superior sigue siendo la barrera modal).
Future<void> _closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await defaultToolExplainerStore.setDismissed('range_explorer', true);
    await defaultToolExplainerStore.setDismissed('blocker_explorer', true);
  });

  testWidgets('muestra la grilla real para BTN por defecto', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Button'), findsOneWidget);
    // AA está en todos los rangos de apertura -> exactamente una celda.
    expect(find.text('AA'), findsOneWidget);
    expect(find.text(AppStrings.rangesOfficialBadge), findsOneWidget);
  });

  testWidgets('tocar una posición cambia el rango mostrado', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('UTG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Under the Gun'), findsOneWidget);
  });

  testWidgets('la BB muestra el aviso en vez de la grilla (Explorar y Practicar)',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('BB'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.rangesBbTitle), findsOneWidget);
    expect(find.text('AA'), findsNothing);

    await tester.tap(find.text(AppStrings.rangesModePractice));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rangesBbTitle), findsOneWidget);
  });

  testWidgets('tocar una mano de la grilla abre el detalle con combos reales',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('AA'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // AA aparece dos veces: la celda de la grilla + el valor del detalle.
    expect(find.text('AA'), findsNWidgets(2));
    expect(find.text('100%'), findsOneWidget); // frecuencia
    expect(find.text('6'), findsOneWidget); // combos de un par
    expect(find.text(AppStrings.rangesAnalyzeBlockers), findsOneWidget);
  });

  testWidgets('"Analizar blockers" abre Blocker Explorer con la mano precargada',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('AA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.rangesAnalyzeBlockers));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BlockerExplorerScreen), findsOneWidget);
    // La mano de héroe ya viene completa (dos cartas de AA precargadas) —
    // Blocker Explorer arranca directo con resultado, no con el estado
    // "elegí tu mano".
    expect(find.text(AppStrings.toolsHandPickBoth), findsNothing);
  });

  testWidgets('cambiar de posición después de elegir una mano no rompe',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('AA'));
    await tester.pumpAndSettle();
    await _closeSheet(tester);
    await tester.tap(find.text('UTG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('un board cargado reduce los combos disponibles de la celda',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Board AsAhKd: dos de los 6 combos de AA quedan bloqueados.
    for (final card in const [
      Card(Rank.ace, Suit.spades),
      Card(Rank.ace, Suit.hearts),
      Card(Rank.king, Suit.diamonds),
    ]) {
      final outline = find.byType(DottedCardOutline);
      await tester.ensureVisible(outline);
      await tester.pumpAndSettle();
      await tester.tap(outline);
      await tester.pumpAndSettle();
      await _chooseCard(tester, card);
    }

    final aaCell = find.text('AA');
    await tester.ensureVisible(aaCell);
    await tester.pumpAndSettle();
    await tester.tap(aaCell);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // AA tiene 6 combos en total; As/Ah bloquean 5 de ellos (cualquier
    // combo que use alguna de esas dos cartas) y dejan 1 vivo (Ad-Ac).
    expect(find.text('1/6'), findsOneWidget);
  });

  testWidgets('los filtros se pueden expandir y activar', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rangesFiltersClear), findsNothing);

    await tester.tap(find.text(AppStrings.rangesFiltersTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pares'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.rangesFiltersClear), findsOneWidget);

    await tester.tap(find.text(AppStrings.rangesFiltersClear));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rangesFiltersClear), findsNothing);
  });

  testWidgets('Construir: partir del oficial, editar y guardar aparece en Mis Rangos',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.rangesModeBuild));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.rangesBuilderStartOfficial));
    await tester.pumpAndSettle();

    expect(find.text('BTN Open (editado)'), findsOneWidget);

    final aaCell = find.text('AA');
    await tester.ensureVisible(aaCell);
    await tester.pumpAndSettle();
    await tester.tap(aaCell);
    await tester.pumpAndSettle();

    final zeroChip = find.text('0%');
    await tester.ensureVisible(zeroChip);
    await tester.pumpAndSettle();
    await tester.tap(zeroChip);
    await tester.pumpAndSettle();

    final saveButton = find.text(AppStrings.rangesBuilderSave);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    // Un solo pump (no pumpAndSettle): el SnackBar de confirmación se
    // auto-oculta después de unos segundos — pumpAndSettle correría esa
    // animación entera y lo encontraría ya cerrado.
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.rangesBuilderSavedConfirmation), findsOneWidget);
    await tester.pumpAndSettle();
    // Vuelve a la pantalla de arranque del builder tras guardar.
    expect(find.text(AppStrings.rangesBuilderStartOfficial), findsOneWidget);

    await tester.tap(find.text(AppStrings.rangesModeExplore));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.rangesMyRangesTitle));
    await tester.pumpAndSettle();

    expect(find.text('BTN Open (editado)'), findsOneWidget);
  });

  testWidgets('Comparar: elegir un segundo rango muestra el resumen de diferencias',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rangesCompareEmpty), findsNothing);

    await tester.tap(find.text(AppStrings.rangesCompareTitle));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rangesCompareEmpty), findsOneWidget);

    await tester.tap(find.text('UTG Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.rangesCompareEmpty), findsNothing);
    // BTN abre bastante más ancho que UTG -> tiene que haber "agregadas".
    expect(find.textContaining(AppStrings.rangesCompareLegendAdded), findsOneWidget);
  });

  testWidgets('Comparar -> "Ver equity" lleva los dos rangos (y el board, '
      'si hay uno) a Equity', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Cargar un board en Explorar primero: el mismo `controller.board`
    // se comparte con Comparar, así que Equity recibe rango vs rango
    // CON board y calcula de una en vez de pedirlo.
    for (final card in const [
      Card(Rank.two, Suit.clubs),
      Card(Rank.seven, Suit.diamonds),
      Card(Rank.nine, Suit.hearts),
    ]) {
      final outline = find.byType(DottedCardOutline);
      await tester.ensureVisible(outline);
      await tester.pumpAndSettle();
      await tester.tap(outline);
      await tester.pumpAndSettle();
      await _chooseCard(tester, card);
    }

    final compareLink = find.text(AppStrings.rangesCompareTitle);
    await tester.ensureVisible(compareLink);
    await tester.pumpAndSettle();
    await tester.tap(compareLink);
    await tester.pumpAndSettle();

    final utgOpen = find.text('UTG Open');
    await tester.ensureVisible(utgOpen);
    await tester.pumpAndSettle();
    await tester.tap(utgOpen);
    await tester.pumpAndSettle();

    final viewEquity = find.text(AppStrings.blockerViewEquity);
    await tester.ensureVisible(viewEquity);
    await tester.pumpAndSettle();
    await tester.tap(viewEquity);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EquityCalculatorScreen), findsOneWidget);
    expect(find.text(AppStrings.equityModeRangeVsRangeLabel), findsOneWidget);
    // Rango vs rango nunca calcula solo (BTN Open vs UTG Open son rangos
    // reales anchos — el costo real, `heroCombos × villainCombos ×
    // runouts`, queda atrás del botón "Calcular equity" a propósito, ver
    // el doc-comment de `EquityEngine.rangeVsRange`): los campos llegan
    // listos, pero sin resultado todavía.
    expect(find.text(AppStrings.toolsResultPrincipal.toUpperCase()), findsNothing);
    expect(find.text(AppStrings.equityCalculateButtonLabel), findsOneWidget);
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

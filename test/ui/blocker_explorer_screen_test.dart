import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/tool_explainer_store.dart';
import 'package:poker_trainer/screens/academy/widgets/table/playing_card.dart';
import 'package:poker_trainer/screens/tools/blocker_explorer_screen.dart';
import 'package:poker_trainer/screens/tools/combo_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/equity_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/range/range_explorer_screen.dart';
import 'package:poker_trainer/screens/tools/widgets/card_picker.dart';

Widget _harness() => const MaterialApp(home: BlockerExplorerScreen());

/// Elige [card] en el picker de cartas (grilla de 52) que ya está abierto
/// — mismo mecanismo que usa el usuario real: tocar el texto de la carta
/// la confirma y cierra el panel en el mismo gesto (ver
/// `card_picker.dart`).
Future<void> _chooseCard(WidgetTester tester, Card card) async {
  final target = find.text(card.pretty);
  // La grilla de 52 cartas vive en un `SingleChildScrollView` propio (ver
  // `card_picker.dart`) — varias filas quedan fuera de la vista inicial,
  // así que hay que desplazarla antes de tocar.
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Espera a que termine un cálculo real de `EquityEngine` en el isolate
/// aparte que abre `compute()` (mismo motivo que
/// `equity_calculator_screen_test.dart`'s `_waitForIsolate`):
/// `pumpAndSettle` normal nunca destraba ese `Future`.
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
  // El sistema de explicación contextual (Grupo 3) espera de forma
  // asíncrona a leer el archivo real de "no volver a mostrar" antes de
  // decidir si abre un modal — un `pumpAndSettle()` normal no destraba
  // esa lectura, así que puede aparecer en cualquier punto de la
  // corrida y tapar el tap que el test quería hacer. Sembrar el toolId
  // como ya visto (en el mismo store singleton que usa la app real)
  // antes de correr nada elimina la carrera sin tocar la pantalla.
  setUpAll(() async {
    await defaultToolExplainerStore.setDismissed('blocker_explorer', true);
  });

  testWidgets(
      'muestra un resultado real con los valores por defecto '
      '(AhKd vs QQ+,AKs,AKo)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // QQ+ = QQ,KK,AA (18 combos) + AKs (4) + AKo (12) = 34 combos totales.
    // AhKd bloquea: KK 6->3, AA 6->3, AKs 4->2, AKo 12->7, QQ sin cambios.
    // Disponibles: 6+3+3+2+7 = 21. Bloqueados: 13.
    expect(find.text('34'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('QQ 6/6'), findsOneWidget);
    expect(find.text('KK 3/6'), findsOneWidget);
    expect(find.text('AA 3/6'), findsOneWidget);
    expect(find.text('AKs 2/4'), findsOneWidget);
    expect(find.text('AKo 7/12'), findsOneWidget);
  });

  testWidgets('una clase totalmente bloqueada (hero + board) muestra 0 '
      'disponibles', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Reemplaza la mano por defecto (AhKd) por QsKd: tocar una carta ya
    // puesta reabre el picker para reemplazarla (mismo gesto que el
    // usuario real usa en la mesa) — nunca texto libre, ver
    // `CardGroupField`/`card_picker.dart`.
    await tester.tap(find.byType(PlayingCard).first);
    await tester.pumpAndSettle();
    await _chooseCard(tester, const Card(Rank.queen, Suit.spades));

    // El rango sigue siendo el único campo de texto real de esta
    // pantalla — no son "las cartas del jugador".
    await tester.enterText(find.byType(TextField), 'QQ');
    await tester.pumpAndSettle();

    // Arma el board QhQd2c agregando una carta a la vez: el mismo
    // contorno punteado reaparece después de cada elección (hasta el
    // máximo de 5), nunca un campo de texto.
    for (final card in const [
      Card(Rank.queen, Suit.hearts),
      Card(Rank.queen, Suit.diamonds),
      Card(Rank.two, Suit.clubs),
    ]) {
      await tester.tap(find.byType(DottedCardOutline));
      await tester.pumpAndSettle();
      await _chooseCard(tester, card);
    }

    expect(tester.takeException(), isNull);
    // Board-only deja viva 1 combinación (QsQc); sumarle la Qs del héroe
    // como bloqueador también la elimina -> 0 disponibles.
    expect(find.text('1'), findsWidgets); // total y bloqueados
    expect(find.text('0'), findsOneWidget); // disponibles
    expect(find.text('QQ 0/1'), findsOneWidget);
  });

  testWidgets('rango inválido muestra el error específico de rangos',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not a range');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.blockerInvalidRange), findsOneWidget);
  });

  testWidgets('board vacío (análisis preflop) es una entrada válida',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // El board es opcional (min 0) y arranca vacío por defecto — no hace
    // falta ninguna interacción para que sea un análisis preflop válido.
    expect(tester.takeException(), isNull);
    expect(find.text('34'), findsOneWidget);
  });

  testWidgets('"Ver equity" abre Equity en modo mano vs rango con los '
      'mismos datos', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // EquityEngine no calcula preflop (board vacío) a propósito — para
    // ver un resultado real hace falta un board, igual que si el
    // usuario entrara directo a Equity en este modo.
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

    final viewEquity = find.text(AppStrings.blockerViewEquity);
    await tester.ensureVisible(viewEquity);
    await tester.pumpAndSettle();
    await tester.tap(viewEquity);
    // Dos pumps (no `pumpAndSettle`): uno para que la navegación monte
    // `EquityCalculatorScreen`, otro para que corra su primer
    // `postFrameCallback` — que dispara el cálculo solo, en un isolate
    // aparte que `pumpAndSettle` no puede destrabar.
    await tester.pump();
    await tester.pump();
    await _waitForIsolate(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EquityCalculatorScreen), findsOneWidget);
    // Con hero + rango + board ya completos, calcula solo (modo mano vs
    // rango no es en vivo, pero el postFrameCallback dispara el cálculo).
    expect(find.text(AppStrings.toolsResultPrincipal.toUpperCase()), findsOneWidget);
  });

  testWidgets('"Ver equity" sin board precargado deja a Equity pedirlo '
      '(preflop está fuera de alcance del motor)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final viewEquity = find.text(AppStrings.blockerViewEquity);
    await tester.ensureVisible(viewEquity);
    await tester.pumpAndSettle();
    await tester.tap(viewEquity);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EquityCalculatorScreen), findsOneWidget);
    // El mensaje aparece dos veces: el estado del propio `CardGroupField`
    // del board, y el `ToolErrorCard` del cálculo que se intentó solo.
    expect(find.text(AppStrings.toolsBoardMissing(3)), findsNWidgets(2));
  });

  testWidgets('"Ver este rango en Construir" abre Rangos con la matriz ya '
      'cargada', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final viewInBuilder = find.text(AppStrings.blockerViewRangeInBuilder);
    await tester.ensureVisible(viewInBuilder);
    await tester.pumpAndSettle();
    await tester.tap(viewInBuilder);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(RangeExplorerScreen), findsOneWidget);
    // El default 'QQ+,AKs,AKo' expandido incluye QQ -> la matriz editable
    // ya se ve directo (sin pedir "Partir del oficial/Empezar de cero").
    expect(find.text(AppStrings.rangesBuilderStartOfficial), findsNothing);
    expect(find.text('QQ'), findsOneWidget);
  });

  testWidgets('tocar un chip de clase abre Combos con esa notación y el '
      'board precargados', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final chip = find.text('QQ 6/6');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ComboCalculatorScreen), findsOneWidget);
    expect(find.text('6'), findsNWidgets(2)); // total y disponibles (QQ, sin board)
  });

  testWidgets('el botón de volver hace pop', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlockerExplorerScreen()),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(BlockerExplorerScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BlockerExplorerScreen), findsNothing);
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

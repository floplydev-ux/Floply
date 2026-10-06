import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/tool_explainer_store.dart';
import 'package:poker_trainer/screens/tools/combo_calculator_screen.dart';
import 'package:poker_trainer/screens/tools/widgets/card_picker.dart';

Widget _harness() => const MaterialApp(home: ComboCalculatorScreen());

/// Agrega [card] como carta muerta a través del picker real — mismo
/// mecanismo que usa el usuario (ver `blocker_explorer_screen_test.dart`
/// para el mismo patrón): tocar el contorno punteado abre la grilla de
/// 52, y tocar la carta la confirma.
Future<void> _addDeadCard(WidgetTester tester, Card card) async {
  await tester.tap(find.byType(DottedCardOutline));
  await tester.pumpAndSettle();
  final target = find.text(card.pretty);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  // Ver el mismo comentario en blocker_explorer_screen_test.dart: evita
  // la carrera del sistema de explicación contextual (Grupo 3).
  setUpAll(() async {
    await defaultToolExplainerStore.setDismissed('combo_calculator', true);
  });

  testWidgets('muestra un resultado real con los valores por defecto '
      '(AKs, sin cartas muertas: 4 combos)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // AKs es suited: 4 combos, ninguno bloqueado sin cartas muertas.
    expect(find.text('4'), findsNWidgets(2)); // totales y disponibles
    expect(find.text('0'), findsOneWidget); // bloqueados
  });

  testWidgets('un par (77) sin cartas muertas da 6 combos', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '77');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('6'), findsNWidgets(2));
  });

  testWidgets('cartas muertas bloquean combos concretos (AKs con As muerto: '
      '3 de 4 disponibles)', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Las cartas muertas se eligen con el picker real (grupo variable
    // 0..20, ver `CardGroupSpec` de `deadCards`), nunca texto libre.
    await _addDeadCard(tester, const Card(Rank.ace, Suit.spades));

    expect(tester.takeException(), isNull);
    expect(find.text('4'), findsOneWidget); // total
    expect(find.text('3'), findsOneWidget); // disponibles
    expect(find.text('1'), findsOneWidget); // bloqueados
  });

  testWidgets('cartas muertas que bloquean todos los combos muestra el '
      'aviso de "ninguno disponible"', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'AKs');
    await tester.pumpAndSettle();
    // Las 4 combinaciones de AKs son AsKs/AhKh/AdKd/AcKc (un palo por
    // combo) — matar los 4 ases bloquea las 4, ya que cada una necesita
    // su as específico.
    for (final card in const [
      Card(Rank.ace, Suit.spades),
      Card(Rank.ace, Suit.hearts),
      Card(Rank.ace, Suit.diamonds),
      Card(Rank.ace, Suit.clubs),
    ]) {
      await _addDeadCard(tester, card);
    }

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.comboNoneAvailable), findsOneWidget);
  });

  testWidgets('notación de clase de mano inválida muestra el error y no '
      'rompe', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'xyz');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.comboInvalidInput), findsOneWidget);
  });

  testWidgets('precarga desde otra herramienta (notación + cartas muertas)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ComboCalculatorScreen(
        initialNotation: 'QQ',
        initialDeadCards: [Card(Rank.queen, Suit.spades)],
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // QQ tiene 6 combos; matar Qs bloquea las 3 combinaciones que la
    // usan (Qs con cada otro palo), dejando 3 disponibles.
    expect(find.text('6'), findsOneWidget); // total
    expect(find.text('3'), findsNWidgets(2)); // disponibles y bloqueados
  });

  testWidgets('el botón de volver hace pop', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ComboCalculatorScreen()),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(ComboCalculatorScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ComboCalculatorScreen), findsNothing);
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

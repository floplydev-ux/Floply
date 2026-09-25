import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/blocker_explorer_screen.dart';

Widget _harness() => const MaterialApp(home: BlockerExplorerScreen());

void main() {
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

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'QsKd');
    await tester.enterText(fields.at(1), 'QQ');
    await tester.enterText(fields.at(2), 'QhQd2c');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Board-only deja viva 1 combinación (QsQc); sumarle la Qs del héroe
    // como bloqueador también la elimina -> 0 disponibles.
    expect(find.text('1'), findsWidgets); // total y bloqueados
    expect(find.text('0'), findsOneWidget); // disponibles
    expect(find.text('QQ 0/1'), findsOneWidget);
  });

  testWidgets('mano inválida muestra el error específico de mano',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'xyz');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.blockerInvalidHand), findsOneWidget);
  });

  testWidgets('rango inválido muestra el error específico de rangos',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'not a range');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.blockerInvalidRange), findsOneWidget);
  });

  testWidgets('board con largo inválido muestra el error específico de '
      'board', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), '2c7d');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.blockerInvalidBoard), findsOneWidget);
  });

  testWidgets('carta repetida entre la mano y el board muestra el error '
      'de board', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'AhKd');
    await tester.enterText(fields.at(2), 'Ah7d9h');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.blockerInvalidBoard), findsOneWidget);
  });

  testWidgets('board vacío (análisis preflop) es una entrada válida',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), '');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('34'), findsOneWidget);
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

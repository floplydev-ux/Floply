import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/screens/academy/widgets/poker_chip.dart';

void main() {
  group('kChipDenominations', () {
    test('tiene exactamente las 5 denominaciones de la escala inicial', () {
      final values = kChipDenominations.map((d) => d.value).toSet();
      expect(values, {1, 5, 10, 25, 100});
    });

    test('1 → blanca', () {
      final d = kChipDenominations.firstWhere((d) => d.value == 1);
      expect(d.displayName, 'Blanca');
      expect(d.color, const Color(0xFFF3EFE4));
    });

    test('5 → roja', () {
      final d = kChipDenominations.firstWhere((d) => d.value == 5);
      expect(d.displayName, 'Roja');
      expect(d.color, const Color(0xFFA5302E));
    });

    test('10 → azul', () {
      final d = kChipDenominations.firstWhere((d) => d.value == 10);
      expect(d.displayName, 'Azul');
      expect(d.color, const Color(0xFF1F3E78));
    });

    test('25 → verde', () {
      final d = kChipDenominations.firstWhere((d) => d.value == 25);
      expect(d.displayName, 'Verde');
      expect(d.color, const Color(0xFF1E7A4C));
    });

    test('100 → negra', () {
      final d = kChipDenominations.firstWhere((d) => d.value == 100);
      expect(d.displayName, 'Negra');
      expect(d.color, const Color(0xFF1C1C1E));
    });

    test('cada denominación tiene un accentColor definido (nunca null)', () {
      for (final d in kChipDenominations) {
        expect(d.accentColor, isNotNull);
      }
    });

    test(
        'la blanca tiene un accentColor propio, distinto del default '
        '(si no, se perdería el contraste cuerpo/muesca)', () {
      final white = kChipDenominations.firstWhere((d) => d.value == 1);
      final others = kChipDenominations
          .where((d) => d.value != 1)
          .map((d) => d.accentColor);
      expect(others.toSet().length, 1,
          reason: 'las demás denominaciones comparten el mismo accent default');
      expect(white.accentColor, isNot(others.first));
    });

    test('ChipDenomination con los mismos campos es == (comparación por valor)',
        () {
      const a = ChipDenomination(
          value: 25, displayName: 'Verde', color: Color(0xFF1E7A4C));
      const b = ChipDenomination(
          value: 25, displayName: 'Verde', color: Color(0xFF1E7A4C));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('calculateChipStack — denominación exacta', () {
    test('1 → [blanca]', () {
      final chips = calculateChipStack(1);
      expect(chips.map((c) => c.value).toList(), [1]);
    });

    test('5 → [roja]', () {
      final chips = calculateChipStack(5);
      expect(chips.map((c) => c.value).toList(), [5]);
    });

    test('10 → [azul]', () {
      final chips = calculateChipStack(10);
      expect(chips.map((c) => c.value).toList(), [10]);
    });

    test('25 → [verde]', () {
      final chips = calculateChipStack(25);
      expect(chips.map((c) => c.value).toList(), [25]);
    });

    test('100 → [negra]', () {
      final chips = calculateChipStack(100);
      expect(chips.map((c) => c.value).toList(), [100]);
    });
  });

  group('calculateChipStack — combinación de denominaciones', () {
    test('125 → [negra(100), verde(25)] — ejemplo del enunciado', () {
      final chips = calculateChipStack(125);
      expect(chips.map((c) => c.value).toList(), [100, 25]);
    });

    test(
        '150 → [negra, verde, verde] — la denominación más alta gana '
        'siempre que entre (2×25 es más eficiente que 5×5 para el '
        'remanente de 50, así que el goloso "mayor valor primero" da 3 '
        'fichas, no 7)', () {
      final chips = calculateChipStack(150);
      expect(chips.map((c) => c.value).toList(), [100, 25, 25]);
      expect(chips.length, 3);
    });

    test(
        'prioriza siempre la denominación más alta posible primero '
        '(la lista nunca sube de valor)', () {
      for (final total in [37, 88, 213, 461, 999]) {
        final chips = calculateChipStack(total);
        for (var i = 1; i < chips.length; i++) {
          expect(chips[i - 1].value, greaterThanOrEqualTo(chips[i].value),
              reason: 'total=$total debe venir ordenado de mayor a menor');
        }
      }
    });
  });

  group('calculateChipStack — valores límite', () {
    test('0 → sin fichas', () {
      expect(calculateChipStack(0), isEmpty);
    });

    test('valor negativo → sin fichas (no revienta)', () {
      expect(calculateChipStack(-50), isEmpty);
    });

    test(
        'valor chico no representable exacto (ej. 3) igual suma correcto '
        'usando fichas blancas', () {
      final chips = calculateChipStack(3);
      final sum = chips.fold<int>(0, (a, c) => a + c.value);
      expect(sum, 3);
      expect(chips.every((c) => c.value == 1), isTrue);
    });

    test(
        'valor grande: la suma de las fichas siempre reconstruye el total '
        'exacto', () {
      for (final total in [999, 4321, 9999, 123456]) {
        final chips = calculateChipStack(total);
        final sum = chips.fold<int>(0, (a, c) => a + c.value);
        expect(sum, total, reason: 'total=$total');
      }
    });

    test(
        'valor grande no genera una cantidad absurda de fichas — la escala '
        '1/5/10/25/100 es golosa-óptima', () {
      // Peor caso real para esta escala: remanente 99 → 3×25 + 2×10 + 4×1 = 9.
      final chips = calculateChipStack(99);
      expect(chips.length, lessThanOrEqualTo(9));
    });
  });

  group('limitVisibleChips', () {
    test('no recorta si ya está dentro del límite', () {
      final chips = calculateChipStack(125); // 2 fichas
      expect(limitVisibleChips(chips, 8), chips);
    });

    test('recorta al límite, conservando las de MAYOR valor primero', () {
      final chips = calculateChipStack(99); // 9 fichas: 25,25,25,10,10,1,1,1,1
      final limited = limitVisibleChips(chips, 8);
      expect(limited.length, 8);
      expect(limited, chips.sublist(0, 8));
      // Las que se recortan son siempre las de MENOR valor (al final).
      expect(limited.last.value, lessThanOrEqualTo(chips[7].value));
    });

    test(
        'el total real no cambia por el recorte visual — solo cambia '
        'cuántas fichas se dibujan, no cuánto vale la pila', () {
      final full = calculateChipStack(99);
      final limited = limitVisibleChips(full, 3);
      final fullSum = full.fold<int>(0, (a, c) => a + c.value);
      final limitedSum = limited.fold<int>(0, (a, c) => a + c.value);
      expect(limited.length, 3);
      expect(limitedSum, lessThan(fullSum),
          reason: 'la pila VISUAL recortada vale menos que el total real — '
              'el total real sigue viviendo en calculateChipStack/el texto '
              'aparte, no en la cantidad de fichas dibujadas');
    });
  });

  group('PokerChip / PokerChipStack — smoke tests de render', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.green,
          body: Center(child: child),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('PokerChip renderiza sin excepciones para cada denominación',
        (tester) async {
      for (final denom in kChipDenominations) {
        await pump(tester, PokerChip(denomination: denom));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'PokerChipStack(totalValue: 0) no renderiza fichas y no revienta',
        (tester) async {
      await pump(tester, const PokerChipStack(totalValue: 0));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('PokerChipStack(totalValue: 125) renderiza sin excepciones',
        (tester) async {
      await pump(tester, const PokerChipStack(totalValue: 125));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'PokerChipStack con un total que excede maxVisibleChips sigue '
        'renderizando sin overflow (la pila se recorta, no revienta)',
        (tester) async {
      await pump(
        tester,
        const PokerChipStack(totalValue: 999, maxVisibleChips: 8),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'maxVisibleChips más chico realmente reduce el alto de la '
        'pila (menos fichas apiladas ⇒ pila más baja)', (tester) async {
      await pump(
        tester,
        const PokerChipStack(totalValue: 999, maxVisibleChips: 8),
      );
      final tall = tester.getSize(find.byType(PokerChipStack)).height;

      await pump(
        tester,
        const PokerChipStack(totalValue: 999, maxVisibleChips: 2),
      );
      final short = tester.getSize(find.byType(PokerChipStack)).height;

      expect(short, lessThan(tall));
    });
  });
}

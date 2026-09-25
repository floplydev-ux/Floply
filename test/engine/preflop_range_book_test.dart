import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/strategy/hand_strength.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';
import 'package:poker_trainer/engine/strategy/preflop_range_book.dart';

void main() {
  group('PreflopRangeBook.anchorFor', () {
    test('devuelve una ancla real para BB vs CO (default de defenseVsOpen)', () {
      expect(PreflopRangeBook.anchorFor(Position.bb, Position.co), isNotNull);
    });

    test('devuelve una ancla real para BTN vs UTG (default de threeBet)', () {
      expect(PreflopRangeBook.anchorFor(Position.btn, Position.utg), isNotNull);
    });

    test('devuelve una ancla real para BTN vs CO (rango real de 3-bet de '
        'BTN, usado por facingThreeBet para samplear al 3-bettor)', () {
      expect(PreflopRangeBook.anchorFor(Position.btn, Position.co), isNotNull);
    });

    test('devuelve null para cualquier otro par (fallback explícito, no '
        'un rango inventado)', () {
      expect(PreflopRangeBook.anchorFor(Position.co, Position.btn), isNull);
      expect(PreflopRangeBook.anchorFor(Position.bb, Position.utg), isNull);
      expect(PreflopRangeBook.anchorFor(Position.sb, Position.btn), isNull);
    });
  });

  group('PreflopRangeBook.facingThreeBetAnchorFor', () {
    test('devuelve una ancla real para CO encarando un 3-bet de BTN '
        '(default de facingThreeBet)', () {
      expect(
          PreflopRangeBook.facingThreeBetAnchorFor(Position.co, Position.btn),
          isNotNull);
    });

    test('devuelve null para cualquier otro par', () {
      expect(
          PreflopRangeBook.facingThreeBetAnchorFor(Position.hj, Position.btn),
          isNull);
      expect(
          PreflopRangeBook.facingThreeBetAnchorFor(Position.btn, Position.utg),
          isNull);
    });

    test('el 4-bet de valor queda genuinamente adelante de la mediana del '
        'rango de 3-bet real de BTN', () {
      final anchor =
          PreflopRangeBook.facingThreeBetAnchorFor(Position.co, Position.btn)!;
      final threeBetterRange = PreflopRangeBook.anchorFor(Position.btn, Position.co)!;
      final merged = threeBetterRange.threeBetValueRange
          .merge(threeBetterRange.threeBetBluffRange);
      final classes = merged.classes.where((c) => merged.frequencyOf(c) > 0).toList();
      final percentiles = classes.map(HandStrength.percentile).toList()..sort();
      final median = percentiles[percentiles.length ~/ 2];

      for (final hc in anchor.fourBetValueRange.classes) {
        if (anchor.fourBetValueRange.frequencyOf(hc) <= 0) continue;
        expect(HandStrength.percentile(hc), lessThan(median),
            reason: '$hc (4-bet valor) debería ser más fuerte que la '
                'mediana del rango de 3-bet real de BTN');
      }
    });

    test('callRange y fourBetValueRange no se solapan', () {
      final anchor =
          PreflopRangeBook.facingThreeBetAnchorFor(Position.co, Position.btn)!;
      for (final hc in anchor.fourBetValueRange.classes) {
        if (anchor.fourBetValueRange.frequencyOf(hc) <= 0) continue;
        expect(anchor.callRange.frequencyOf(hc), 0);
      }
    });
  });

  group('PreflopRangeBook.shortStackAnchorFor', () {
    test('devuelve una ancla real para BB vs CO (default de '
        'shortStackFacingOpen)', () {
      expect(PreflopRangeBook.shortStackAnchorFor(Position.bb, Position.co),
          isNotNull);
    });

    test('devuelve null para cualquier otro par', () {
      expect(PreflopRangeBook.shortStackAnchorFor(Position.btn, Position.utg),
          isNull);
    });

    test('el rango de empuje es más ancho que el 3-bet de valor de 100bb '
        'para el mismo par (teoría de push/fold: a stack corto se empuja '
        'más ancho)', () {
      final shortStack = PreflopRangeBook.shortStackAnchorFor(Position.bb, Position.co)!;
      final deep = PreflopRangeBook.anchorFor(Position.bb, Position.co)!;
      expect(shortStack.shoveRange.comboCount,
          greaterThan(deep.threeBetValueRange.comboCount));
    });
  });

  for (final entry in {
    'BB vs CO': (hero: Position.bb, villain: Position.co),
    'BTN vs UTG': (hero: Position.btn, villain: Position.utg),
    'BTN vs CO': (hero: Position.btn, villain: Position.co),
  }.entries) {
    final label = entry.key;
    final hero = entry.value.hero;
    final villain = entry.value.villain;

    group('Ancla $label', () {
      final anchor = PreflopRangeBook.anchorFor(hero, villain)!;

      test('el 3-bet de valor queda genuinamente adelante de la mediana '
          'del rango de apertura real de $villain', () {
        final villainRange = OpeningRanges.forPosition(villain);
        final villainClasses =
            villainRange.classes.where((c) => villainRange.frequencyOf(c) > 0).toList();
        expect(villainClasses, isNotEmpty);

        final percentiles = villainClasses.map(HandStrength.percentile).toList()
          ..sort();
        final median = percentiles[percentiles.length ~/ 2];

        for (final hc in anchor.threeBetValueRange.classes) {
          if (anchor.threeBetValueRange.frequencyOf(hc) <= 0) continue;
          expect(
            HandStrength.percentile(hc),
            lessThan(median),
            reason: '$hc (3-bet valor de $label) debería ser más fuerte '
                'que la mediana del rango de apertura de $villain',
          );
        }
      });

      test('callRange y threeBetValueRange no se solapan', () {
        for (final hc in anchor.threeBetValueRange.classes) {
          if (anchor.threeBetValueRange.frequencyOf(hc) <= 0) continue;
          expect(anchor.callRange.frequencyOf(hc), 0,
              reason: '$hc no debería estar en ambos rangos a la vez');
        }
      });

      test('threeBetBluffRange nunca se solapa con threeBetValueRange', () {
        for (final hc in anchor.threeBetBluffRange.classes) {
          if (anchor.threeBetBluffRange.frequencyOf(hc) <= 0) continue;
          expect(anchor.threeBetValueRange.frequencyOf(hc), 0,
              reason: '$hc no debería ser a la vez valor y farol');
        }
      });

      test('ninguno de los 3 rangos está vacío', () {
        expect(anchor.callRange.comboCount, greaterThan(0));
        expect(anchor.threeBetValueRange.comboCount, greaterThan(0));
        expect(anchor.threeBetBluffRange.comboCount, greaterThan(0));
      });

      test('AA siempre es 3-bet de valor (nunca solo call ni farol)', () {
        expect(anchor.threeBetValueRange.contains('AA'), isTrue);
      });

      test('una mano claramente fuera de todo (72o) no aparece en ningún '
          'rango', () {
        expect(anchor.callRange.contains('72o'), isFalse);
        expect(anchor.threeBetValueRange.contains('72o'), isFalse);
        expect(anchor.threeBetBluffRange.contains('72o'), isFalse);
      });
    });
  }

  test('HoleCards de ejemplo caen donde se espera en BB vs CO', () {
    final anchor = PreflopRangeBook.anchorFor(Position.bb, Position.co)!;
    expect(anchor.threeBetValueRange.containsHand(HoleCards.parse('AsAd')), isTrue);
    expect(anchor.callRange.containsHand(HoleCards.parse('Ts9s')), isTrue);
    expect(anchor.threeBetBluffRange.containsHand(HoleCards.parse('Ah5h')), isTrue);
  });
}

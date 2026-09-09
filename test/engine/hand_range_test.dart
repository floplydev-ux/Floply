import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/strategy/hand_range.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';

void main() {
  group('HandRange.parse', () {
    test('expande pares con "+"', () {
      final range = HandRange.parse(const ['TT+']);
      expect(range.contains('TT'), isTrue);
      expect(range.contains('AA'), isTrue);
      expect(range.contains('99'), isFalse);
    });

    test('expande suited con "+" fijando la carta alta', () {
      final range = HandRange.parse(const ['ATs+']);
      expect(range.classes, containsAll(['ATs', 'AJs', 'AQs', 'AKs']));
      expect(range.contains('A9s'), isFalse);
    });

    test('expande rangos con guion', () {
      final range = HandRange.parse(const ['A5s-A2s']);
      expect(range.classes, containsAll(['A2s', 'A3s', 'A4s', 'A5s']));
      expect(range.contains('A6s'), isFalse);
    });

    test('lee frecuencias entre paréntesis', () {
      final range = HandRange.parse(const ['KQo(0.5)']);
      expect(range.frequencyOf('KQo'), 0.5);
      expect(range.contains('KQo'), isTrue);
    });

    test('comboCount y porcentaje son coherentes', () {
      final all = HandRange.parse(const ['22+']);
      // 13 pares * 6 combos = 78.
      expect(all.comboCount, 78);
    });
  });

  group('OpeningRanges', () {
    test('los rangos se ensanchan de UTG a BTN', () {
      final utg = OpeningRanges.forPosition(Position.utg).percentOfAllHands;
      final co = OpeningRanges.forPosition(Position.co).percentOfAllHands;
      final btn = OpeningRanges.forPosition(Position.btn).percentOfAllHands;
      expect(utg, lessThan(co));
      expect(co, lessThan(btn));
    });

    test('BB no tiene rango de apertura', () {
      expect(OpeningRanges.forPosition(Position.bb).classes, isEmpty);
    });

    test('manos premium están en todos los rangos de apertura', () {
      for (final pos in Position.openers) {
        expect(OpeningRanges.forPosition(pos).contains('AA'), isTrue,
            reason: 'AA debería abrirse desde $pos');
        expect(OpeningRanges.forPosition(pos).contains('AKs'), isTrue);
      }
    });

    test('72o no se abre desde ninguna posición', () {
      for (final pos in Position.openers) {
        expect(OpeningRanges.forPosition(pos).contains('72o'), isFalse);
      }
    });
  });
}

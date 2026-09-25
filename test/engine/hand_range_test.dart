import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/generation_exception.dart';
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

  group('HandRange.sample', () {
    test('la mano repartida siempre pertenece al rango pedido', () {
      final range = HandRange.parse(const ['TT+', 'AKs', 'AKo']);
      for (var seed = 0; seed < 30; seed++) {
        final hand = range.sample(Deck(Random(seed)));
        expect(range.contains(hand.notation), isTrue,
            reason: 'seed=$seed dio ${hand.notation}');
      }
    });

    test('nunca reparte la misma carta dos veces dentro de la mano', () {
      final range = HandRange.parse(const ['22+']);
      final hand = range.sample(Deck(Random(11)));
      expect(hand.high, isNot(hand.low));
    });

    test('un rango vacío lanza TemplateGenerationException', () {
      expect(
        () => HandRange.empty().sample(Deck(Random(1))),
        throwsA(isA<TemplateGenerationException>()),
      );
    });

    test('si la única clase del rango ya no tiene combos en el mazo, '
        'reintenta con otra en vez de fallar', () {
      final range = HandRange.parse(const ['AA', 'KK']);
      final deck = Deck(Random(5));
      // Bloqueo AA a propósito: saco los 4 ases del mazo.
      deck.remove(const [
        Card(Rank.ace, Suit.spades),
        Card(Rank.ace, Suit.hearts),
        Card(Rank.ace, Suit.diamonds),
        Card(Rank.ace, Suit.clubs),
      ]);
      final hand = range.sample(deck);
      expect(hand.notation, 'KK');
    });

    test('si NINGUNA clase del rango tiene combos disponibles, lanza '
        'TemplateGenerationException', () {
      final range = HandRange.parse(const ['AA']);
      final deck = Deck(Random(1))..remove(kFullDeck);
      expect(deck.remaining, 0);
      expect(
        () => range.sample(deck),
        throwsA(isA<TemplateGenerationException>()),
      );
    });

    test('distribución agregada: con muchas muestras, aparecen todas las '
        'clases del rango (nadie queda con probabilidad efectiva cero)', () {
      final range = HandRange.parse(const ['AA', 'KK', 'QQ']);
      final seen = <String>{};
      for (var seed = 0; seed < 100; seed++) {
        seen.add(range.sample(Deck(Random(seed))).notation);
      }
      expect(seen, {'AA', 'KK', 'QQ'});
    });
  });
}

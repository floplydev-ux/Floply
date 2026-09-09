import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';

void main() {
  group('Card', () {
    test('parsea y reimprime notación compacta', () {
      final card = Card.parse('As');
      expect(card.rank, Rank.ace);
      expect(card.suit, Suit.spades);
      expect(card.code, 'As');
    });

    test('la baraja completa tiene 52 cartas únicas', () {
      expect(kFullDeck.length, 52);
      expect(kFullDeck.toSet().length, 52);
    });
  });

  group('HoleCards', () {
    test('ordena alto-bajo y detecta clase', () {
      final hand = HoleCards.parse('KdAs');
      expect(hand.high.rank, Rank.ace);
      expect(hand.notation, 'AKo');
      expect(hand.isSuited, isFalse);
    });

    test('reconoce pares y suited', () {
      expect(HoleCards.parse('7h7c').notation, '77');
      expect(HoleCards.parse('Ts9s').notation, 'T9s');
      expect(HoleCards.parse('Ts9s').isSuited, isTrue);
    });

    test('rechaza dos cartas iguales', () {
      expect(() => HoleCards.parse('AsAs'), throwsA(anything));
    });
  });

  group('HandClass', () {
    test('hay exactamente 169 clases', () {
      final all = HandClass.all();
      expect(all.length, 169);
      expect(all.map((h) => h.notation).toSet().length, 169);
    });

    test('conteo de combos', () {
      expect(HandClass.parse('AA').combos, 6);
      expect(HandClass.parse('AKs').combos, 4);
      expect(HandClass.parse('AKo').combos, 12);
    });
  });

  group('Deck', () {
    test('reparte sin cartas duplicadas', () {
      final deck = Deck(Random(1));
      final dealt = <Card>{};
      for (var i = 0; i < 26; i++) {
        final hand = deck.dealHoleCards();
        expect(dealt.contains(hand.high), isFalse);
        expect(dealt.contains(hand.low), isFalse);
        dealt
          ..add(hand.high)
          ..add(hand.low);
      }
      expect(dealt.length, 52);
    });

    test('dealHandOfClass devuelve la clase pedida', () {
      final deck = Deck(Random(7));
      final hand = deck.dealHandOfClass('AKs');
      expect(hand, isNotNull);
      expect(hand!.notation, 'AKs');
    });

    test('misma semilla => misma secuencia', () {
      List<String> run() {
        final deck = Deck(Random(42));
        return [for (var i = 0; i < 5; i++) deck.dealHoleCards().toString()];
      }

      expect(run(), run());
    });
  });
}

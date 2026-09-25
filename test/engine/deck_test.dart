import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/deck.dart';

/// Todas del mismo palo: ~5.2% de probabilidad por intento sobre un mazo
/// completo — con 5000 intentos, prácticamente seguro de encontrar una
/// para cualquier semilla (no depende de tener suerte con una semilla
/// puntual).
bool _sameSuit(List<Card> cards) =>
    cards.map((c) => c.suit).toSet().length == 1;

void main() {
  group('Deck.tryDealMatching', () {
    test('devuelve cartas que cumplen el predicado', () {
      final deck = Deck(Random(1));
      final result = deck.tryDealMatching(3, _sameSuit, maxAttempts: 5000);
      expect(result, isNotNull);
      expect(_sameSuit(result!), isTrue);
      expect(result.length, 3);
    });

    test('un predicado imposible agota los intentos y devuelve null, sin '
        'mutar el mazo', () {
      final deck = Deck(Random(2));
      final before = deck.remaining;
      final result = deck.tryDealMatching(3, (cards) => false, maxAttempts: 20);
      expect(result, isNull);
      expect(deck.remaining, before, reason: 'un intento fallido no consume cartas');
    });

    test('al tener éxito, saca exactamente esas cartas del mazo (y no '
        'otras)', () {
      final deck = Deck(Random(3));
      final before = deck.remaining;
      final result = deck.tryDealMatching(3, _sameSuit, maxAttempts: 5000)!;
      expect(deck.remaining, before - 3);
      // Las cartas devueltas ya no están disponibles para un reparto
      // posterior.
      final remainingDealt = deck.dealCards(deck.remaining);
      expect(remainingDealt.toSet().intersection(result.toSet()), isEmpty);
    });

    test('si el mazo tiene menos cartas que las pedidas, devuelve null '
        'de inmediato', () {
      final deck = Deck(Random(4));
      deck.remove(deck.dealCards(50)); // deja 2 cartas
      expect(deck.remaining, 2);
      expect(deck.tryDealMatching(3, (cards) => true), isNull);
    });

    test('determinismo: misma semilla, mismo resultado', () {
      List<Card> run(int seed) {
        final deck = Deck(Random(seed));
        return deck.tryDealMatching(3, _sameSuit, maxAttempts: 5000)!;
      }
      expect(run(42), run(42));
    });
  });

  group('Deck.dealCard — agotamiento', () {
    test('repartir las 52 cartas y una más lanza StateError real, no un '
        'crash desde otro lado', () {
      final deck = Deck(Random(5));
      for (var i = 0; i < 52; i++) {
        deck.dealCard();
      }
      expect(deck.remaining, 0);
      expect(() => deck.dealCard(), throwsStateError);
    });

    test('dealCards pide de más y también lanza StateError, sin repartir '
        'cartas duplicadas antes de fallar', () {
      final deck = Deck(Random(6));
      final dealt = deck.dealCards(50);
      expect(dealt.toSet().length, 50);
      expect(deck.remaining, 2);
      expect(() => deck.dealCards(3), throwsStateError);
    });
  });
}

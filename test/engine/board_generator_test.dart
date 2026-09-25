import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/board_generator.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/generation_exception.dart';

bool _isPaired(List<Card> board) {
  final ranks = board.map((c) => c.rank).toList();
  return ranks.toSet().length < ranks.length;
}

int _suitCount(List<Card> board) => board.map((c) => c.suit).toSet().length;

void main() {
  group('BoardGenerator.flop — cada textura cumple su propia definición', () {
    test('paired: siempre hay dos cartas del mismo rango', () {
      for (var seed = 0; seed < 20; seed++) {
        final board =
            BoardGenerator.flop(Deck(Random(seed)), texture: BoardTexture.paired);
        expect(board.length, 3);
        expect(_isPaired(board), isTrue, reason: 'seed=$seed dio $board');
      }
    });

    test('monotone: los tres palos son iguales', () {
      for (var seed = 0; seed < 20; seed++) {
        final board = BoardGenerator.flop(Deck(Random(seed)),
            texture: BoardTexture.monotone);
        expect(_suitCount(board), 1, reason: 'seed=$seed dio $board');
      }
    });

    test('twoTone: exactamente dos palos distintos', () {
      for (var seed = 0; seed < 20; seed++) {
        final board =
            BoardGenerator.flop(Deck(Random(seed)), texture: BoardTexture.twoTone);
        expect(_suitCount(board), 2, reason: 'seed=$seed dio $board');
      }
    });

    test('rainbow: tres palos distintos', () {
      for (var seed = 0; seed < 20; seed++) {
        final board =
            BoardGenerator.flop(Deck(Random(seed)), texture: BoardTexture.rainbow);
        expect(_suitCount(board), 3, reason: 'seed=$seed dio $board');
      }
    });

    test('any: siempre reparte 3 cartas sin más restricción', () {
      final board = BoardGenerator.flop(Deck(Random(7)));
      expect(board.length, 3);
      expect(board.toSet().length, 3, reason: 'sin cartas repetidas');
    });
  });

  group('BoardGenerator.flop — falla explícita, no fallback silencioso', () {
    test('una textura imposible con lo que queda en el mazo lanza '
        'TemplateGenerationException', () {
      final deck = Deck(Random(1));
      // Dejo en el mazo solo cartas de un único palo: monotone sigue
      // siendo posible, pero twoTone/rainbow ya no lo son (no hay un
      // segundo palo disponible).
      final onlyClubs = kFullDeck.where((c) => c.suit != Suit.clubs).toList();
      deck.remove(onlyClubs);
      expect(deck.remaining, 13);

      expect(
        () => BoardGenerator.flop(deck, texture: BoardTexture.rainbow, maxAttempts: 50),
        throwsA(isA<TemplateGenerationException>()),
      );
    });
  });

  group('BoardGenerator.flop — determinismo', () {
    test('la misma semilla da siempre el mismo flop', () {
      List<Card> run(int seed) =>
          BoardGenerator.flop(Deck(Random(seed)), texture: BoardTexture.paired);
      expect(run(99), run(99));
    });
  });
}

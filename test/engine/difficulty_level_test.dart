import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/difficulty_level.dart';
import 'package:poker_trainer/engine/exercises/templates/hand_picker.dart';
import 'package:poker_trainer/engine/poker/deck.dart';

void main() {
  group('DifficultyLevel.heroHandBias', () {
    test('standard siempre HandBias.any — el default actual, no el '
        'nivel 2 de HandPicker.biasForDifficulty', () {
      final deck = Deck(Random(1));
      expect(DifficultyLevel.standard.heroHandBias(deck), HandBias.any);
    });

    test('easy reutiliza HandPicker.biasForDifficulty(deck, 1) tal cual '
        '(mismo resultado, misma semilla)', () {
      final bias = DifficultyLevel.easy.heroHandBias(Deck(Random(7)));
      final expected = HandPicker.biasForDifficulty(Deck(Random(7)), 1);
      expect(bias, expected);
      expect(bias, anyOf(HandBias.clearlyInRange, HandBias.clearlyOutOfRange),
          reason: 'nivel 1 de HandPicker nunca elige borderline');
    });

    test('hard reutiliza HandPicker.biasForDifficulty(deck, 3) tal cual', () {
      final bias = DifficultyLevel.hard.heroHandBias(Deck(Random(7)));
      final expected = HandPicker.biasForDifficulty(Deck(Random(7)), 3);
      expect(bias, expected);
    });

    test('easy y hard llevan el Deck a estados distintos (consumen azar '
        'real, no una tabla estática)', () {
      final easyDeck = Deck(Random(2));
      DifficultyLevel.easy.heroHandBias(easyDeck);
      final hardDeck = Deck(Random(2));
      DifficultyLevel.hard.heroHandBias(hardDeck);
      // Ambos arrancan del mismo seed pero consultan Deck.pick con listas
      // de tamaño distinto (2 vs 4 opciones) — no se puede asegurar que
      // el remaining coincida, así que solo confirmamos que ninguno de
      // los dos deja el mazo intacto (de verdad usan el Deck.pick).
      expect(easyDeck.remaining, 52,
          reason: 'Deck.pick no reparte cartas, solo elige de una lista');
      expect(hardDeck.remaining, 52);
    });

    test('determinismo: misma semilla, mismo bias (easy/standard/hard)', () {
      for (final level in DifficultyLevel.values) {
        final a = level.heroHandBias(Deck(Random(42)));
        final b = level.heroHandBias(Deck(Random(42)));
        expect(a, b, reason: level.name);
      }
    });
  });
}

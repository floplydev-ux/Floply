import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/exercise_template.dart';
import 'package:poker_trainer/engine/exercises/templates/hand_picker.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';

void main() {
  group('HandPicker.forBias — sesgo correcto', () {
    test('clearlyInRange siempre da una mano con frecuencia alta en el '
        'rango de la posición', () {
      final range = OpeningRanges.forPosition(Position.utg);
      for (var seed = 0; seed < 20; seed++) {
        final deck = Deck(Random(seed));
        final hand =
            HandPicker.forBias(deck, Position.utg, HandBias.clearlyInRange);
        expect(range.frequencyOf(hand.notation), greaterThanOrEqualTo(0.9),
            reason: 'seed=$seed dio ${hand.notation}');
      }
    });

    test('clearlyOutOfRange siempre da una mano fuera del rango', () {
      final range = OpeningRanges.forPosition(Position.utg);
      for (var seed = 0; seed < 20; seed++) {
        final deck = Deck(Random(seed));
        final hand = HandPicker.forBias(
            deck, Position.utg, HandBias.clearlyOutOfRange);
        expect(range.frequencyOf(hand.notation), 0.0,
            reason: 'seed=$seed dio ${hand.notation}');
      }
    });

    test('nunca reparte la misma carta dos veces dentro de la mano', () {
      final deck = Deck(Random(7));
      final hand = HandPicker.forBias(deck, Position.btn, HandBias.any);
      expect(hand.high, isNot(hand.low));
    });
  });

  group('HandPicker.forBias — falla explícita, no fallback silencioso', () {
    test(
        'si el mazo no tiene cartas para la clase elegida, lanza '
        'TemplateGenerationException en vez de devolver una mano fuera '
        'de sesgo sin avisar', () {
      // Mazo completamente vacío: cualquier notación que _randomNotation
      // elija (con HandBias.any, que matchea en el primer intento sin
      // mirar el mazo) va a fallar al repartirse — determinístico, sin
      // depender de qué notación puntual haya salido.
      final deck = Deck(Random(1))..remove(kFullDeck);
      expect(deck.remaining, 0);

      expect(
        () => HandPicker.forBias(deck, Position.btn, HandBias.any),
        throwsA(isA<TemplateGenerationException>()),
      );
    });
  });
}

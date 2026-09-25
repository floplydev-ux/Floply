import '../../poker/deck.dart';
import '../../poker/hole_cards.dart';
import '../../poker/position.dart';
import '../../strategy/hand_strength.dart';
import '../../strategy/opening_ranges.dart';
import '../exercise_template.dart' show TemplateGenerationException;

/// Cómo de "clara" queremos que sea la mano respecto del rango de
/// apertura de una posición.
enum HandBias {
  /// Claramente dentro del rango (decisión fácil: abrir).
  clearlyInRange,

  /// Claramente fuera del rango (decisión fácil: foldear).
  clearlyOutOfRange,

  /// En la frontera: mixta o casi.
  borderline,

  /// Cualquiera.
  any,
}

/// Elige manos concretas para los templates, con sesgo controlado según
/// la dificultad. Nunca devuelve cartas duplicadas (usa la baraja).
class HandPicker {
  const HandPicker._();

  /// Devuelve una mano acorde a [bias] para [position]. Reintenta unas
  /// cuantas veces sorteando notación y luego repartiendo cartas.
  static HoleCards forBias(Deck deck, Position position, HandBias bias) {
    final range = OpeningRanges.forPosition(position);

    String? chosenNotation;
    for (var attempt = 0; attempt < 40; attempt++) {
      final notation = _randomNotation(deck);
      final freq = range.frequencyOf(notation);
      final matches = switch (bias) {
        HandBias.clearlyInRange => freq >= 0.9,
        HandBias.clearlyOutOfRange => freq == 0.0 &&
            HandStrength.percentile(notation) > 0.55,
        HandBias.borderline => freq > 0.0 && freq < 0.9 ||
            (freq == 0.0 && _isJustOutside(position, notation)),
        HandBias.any => true,
      };
      if (matches) {
        chosenNotation = notation;
        break;
      }
    }
    if (chosenNotation == null) {
      throw TemplateGenerationException(
          'HandPicker: no se encontró ninguna notación que cumpla bias='
          '$bias para $position tras 40 intentos.');
    }

    final hand = deck.dealHandOfClass(chosenNotation);
    if (hand == null) {
      throw TemplateGenerationException(
          'HandPicker: la clase $chosenNotation ya no tiene combos '
          'disponibles en el mazo (bloqueada por cartas ya repartidas).');
    }
    return hand;
  }

  /// Bias recomendado para una dificultad dada.
  static HandBias biasForDifficulty(Deck deck, int difficulty) {
    switch (difficulty) {
      case 1:
        return deck.pick(
            const [HandBias.clearlyInRange, HandBias.clearlyOutOfRange]);
      case 2:
        return deck.pick(const [
          HandBias.clearlyInRange,
          HandBias.clearlyOutOfRange,
          HandBias.borderline,
        ]);
      default:
        return deck.pick(const [
          HandBias.borderline,
          HandBias.borderline,
          HandBias.clearlyInRange,
          HandBias.clearlyOutOfRange,
        ]);
    }
  }

  static String _randomNotation(Deck deck) {
    final ranks = 'AKQJT98765432'.split('');
    final a = deck.pick(ranks);
    final b = deck.pick(ranks);
    if (a == b) return '$a$b';
    // Ordenar alto-bajo.
    final ai = ranks.indexOf(a);
    final bi = ranks.indexOf(b);
    final hi = ai < bi ? a : b;
    final lo = ai < bi ? b : a;
    final suited = deck.pick(const [true, false]);
    return '$hi$lo${suited ? 's' : 'o'}';
  }

  static bool _isJustOutside(Position position, String notation) {
    final range = OpeningRanges.forPosition(position);
    final score = HandStrength.chenScore(notation);
    var weakest = 99.0;
    for (final entry in range.frequencies.entries) {
      if (entry.value < 0.5) continue;
      final s = HandStrength.chenScore(entry.key);
      if (s < weakest) weakest = s;
    }
    return (weakest - score) <= 1.5;
  }
}

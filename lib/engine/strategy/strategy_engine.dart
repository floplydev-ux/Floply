import '../concepts/concept_ids.dart';
import '../exercises/poker_situation.dart';
import '../poker/poker_action.dart';
import '../poker/position.dart';
import '../poker/street.dart';
import 'hand_range.dart';
import 'hand_strength.dart';
import 'opening_ranges.dart';
import 'strategy.dart';

/// Conoce la estrategia razonable para una situación concreta.
///
/// Puede usar conceptos avanzados internamente para construir una
/// estrategia coherente; es el motor pedagógico (no éste) el que decide
/// qué se le puede exigir al usuario.
///
/// Alcance actual: decisiones preflop de apertura (RFI) y su tamaño.
class StrategyEngine {
  const StrategyEngine();

  /// Estrategia para la decisión de abrir o no (situación "first in").
  Strategy openRaiseStrategy(PokerSituation situation) {
    assert(situation.street == Street.preflop);
    assert(situation.isFirstIn, 'openRaiseStrategy espera una situación first-in');

    final position = situation.heroPosition;
    final notation = situation.heroCards.notation;
    final range = OpeningRanges.forPosition(position);
    final freq = range.frequencyOf(notation);
    final raiseSize = _openSize(situation, position);
    final raiseAction = PokerAction.raiseTo(raiseSize);

    final concepts = [
      ConceptIds.openRaise,
      ConceptIds.openingRange,
      ConceptIds.positionAdvantage,
    ];

    // Mano claramente en rango.
    if (freq >= 0.75) {
      return Strategy(
        [
          StrategyOption(
            action: raiseAction,
            frequency: 1.0,
            rating: StrategicRating.optimal,
            justifyingConcepts: concepts,
            rationaleKey: 'open.raise.in_range',
          ),
          const StrategyOption(
            action: PokerAction.fold,
            frequency: 0.0,
            rating: StrategicRating.bad,
            justifyingConcepts: [ConceptIds.openingRange],
            rationaleKey: 'open.fold.too_strong',
          ),
        ],
        summaryKey: 'open.summary.in_range',
      );
    }

    // Mano en la frontera: estrategia mixta.
    if (freq > 0.0) {
      return Strategy(
        [
          StrategyOption(
            action: raiseAction,
            frequency: freq,
            rating:
                freq >= 0.4 ? StrategicRating.veryGood : StrategicRating.viable,
            justifyingConcepts: [...concepts, ConceptIds.mixedStrategies],
            rationaleKey: 'open.raise.frontier',
          ),
          StrategyOption(
            action: PokerAction.fold,
            frequency: 1 - freq,
            rating: freq >= 0.4
                ? StrategicRating.viable
                : StrategicRating.veryGood,
            justifyingConcepts: [ConceptIds.openingRange],
            rationaleKey: 'open.fold.frontier',
          ),
        ],
        summaryKey: 'open.summary.frontier',
      );
    }

    // Mano fuera de rango: ¿qué tan lejos?
    final distance = _distanceOutsideRange(position, notation);
    final raiseRating =
        distance <= 1.6 ? StrategicRating.dubious : StrategicRating.bad;

    return Strategy(
      [
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 1.0,
          rating: StrategicRating.optimal,
          justifyingConcepts: [ConceptIds.openingRange, ConceptIds.openRaise],
          rationaleKey: 'open.fold.out_of_range',
        ),
        StrategyOption(
          action: raiseAction,
          frequency: 0.0,
          rating: raiseRating,
          justifyingConcepts: [
            ConceptIds.openingRange,
            ConceptIds.positionAdvantage,
          ],
          rationaleKey: raiseRating == StrategicRating.dubious
              ? 'open.raise.borderline_out'
              : 'open.raise.out_of_range',
        ),
      ],
      summaryKey: 'open.summary.out_of_range',
    );
  }

  /// Estrategia sobre el tamaño de apertura, asumiendo que abrir es
  /// correcto.
  Strategy openSizingStrategy(PokerSituation situation, List<double> sizes) {
    final position = situation.heroPosition;
    final ideal = OpeningRanges.sizingFor(position);

    final options = <StrategyOption>[];
    for (final size in sizes) {
      options.add(StrategyOption(
        action: PokerAction.raiseTo(size),
        frequency: (size - ideal).abs() < 0.01 ? 1.0 : 0.0,
        rating: _sizingRating(position, size, ideal),
        justifyingConcepts: const [ConceptIds.openSizing, ConceptIds.openRaise],
        rationaleKey: _sizingRationale(position, size, ideal),
      ));
    }
    return Strategy(options, summaryKey: 'open.sizing.summary');
  }

  StrategicRating _sizingRating(Position position, double size, double ideal) {
    final diff = (size - ideal).abs();
    if (diff < 0.01) return StrategicRating.optimal;
    if (diff <= 0.5 && OpeningRanges.isReasonableSizing(position, size)) {
      return StrategicRating.viable;
    }
    if (size < 2.0) return StrategicRating.bad; // limp / min-raise
    if (size >= ideal + 1.5) return StrategicRating.dubious;
    return OpeningRanges.isReasonableSizing(position, size)
        ? StrategicRating.viable
        : StrategicRating.dubious;
  }

  String _sizingRationale(Position position, double size, double ideal) {
    final diff = size - ideal;
    if (diff.abs() < 0.01) return 'sizing.ideal';
    if (size < 2.0) return 'sizing.too_small';
    if (diff >= 1.5) return 'sizing.too_big';
    return diff > 0 ? 'sizing.slightly_big' : 'sizing.slightly_small';
  }

  double _openSize(PokerSituation situation, Position position) {
    if (situation.availableRaiseSizes.isNotEmpty) {
      final ideal = OpeningRanges.sizingFor(position);
      return situation.availableRaiseSizes.reduce(
        (a, b) => (a - ideal).abs() <= (b - ideal).abs() ? a : b,
      );
    }
    return OpeningRanges.sizingFor(position);
  }

  /// Aproxima qué tan lejos (en puntos de Chen) está una mano del borde
  /// del rango de apertura de la posición.
  double _distanceOutsideRange(Position position, String notation) {
    final range = OpeningRanges.forPosition(position);
    final handScore = HandStrength.chenScore(notation);
    var weakestInRange = double.infinity;
    for (final entry in range.frequencies.entries) {
      if (entry.value < 0.5) continue;
      final score = HandStrength.chenScore(entry.key);
      if (score < weakestInRange) weakestInRange = score;
    }
    if (weakestInRange == double.infinity) return 99;
    return weakestInRange - handScore;
  }

  /// Rango de apertura de una posición (fachada para templates).
  HandRange openingRange(Position position) =>
      OpeningRanges.forPosition(position);
}

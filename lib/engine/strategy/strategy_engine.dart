import '../concepts/concept_ids.dart';
import '../exercises/poker_situation.dart';
import '../poker/poker_action.dart';
import '../poker/position.dart';
import '../poker/street.dart';
import 'hand_range.dart';
import 'hand_strength.dart';
import 'opening_ranges.dart';
import 'preflop_authoring.dart';
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
    if (situation.street != Street.preflop) {
      throw ArgumentError.value(situation.street, 'situation.street',
          'openRaiseStrategy solo evalúa situaciones preflop');
    }
    if (!situation.isFirstIn) {
      throw ArgumentError.value(situation, 'situation',
          'openRaiseStrategy espera una situación first-in');
    }

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

    // Mano claramente en rango: el tamaño ideal de la posición es
    // "óptimo", pero cualquier otro tamaño dentro de la banda defendible
    // de verdad (`OpeningRanges.reasonableSizingBounds`) sigue siendo una
    // apertura correcta — nunca un único tamaño exacto marcando como
    // error cualquier otro (ver `AnswerEvaluator.optionForSized`, que
    // además cubre cualquier tamaño que ni siquiera esté en esta lista).
    if (freq >= 0.75) {
      // El ideal real de la posición — nunca `raiseSize`/`_openSize`:
      // esa función puede devolver otra cosa si `situation.
      // availableRaiseSizes` trae candidatos propios (vestigio del
      // sistema de templates viejo), y `openSizingStrategy` siempre
      // califica "óptimo" contra `OpeningRanges.sizingFor(position)` —
      // usar un valor distinto acá dejaría a veces sin ninguna opción en
      // frecuencia 1.0 (ningún tamaño "coincide" con el ideal real).
      final ideal = OpeningRanges.sizingFor(position);
      final (minReasonable, maxReasonable) = OpeningRanges.reasonableSizingBounds(position);
      // Reutiliza `openSizingStrategy` (ya calificaba tamaños de verdad,
      // Fase 0.5, pero solo lo llamaba el sistema de templates viejo) con
      // los bordes YA curados de `OpeningRanges` — nunca un tamaño
      // inventado ni un segundo cálculo de calidad de tamaño en paralelo.
      final sizingOptions = openSizingStrategy(
        situation,
        ({minReasonable, ideal, maxReasonable}.toList()..sort()),
      ).options;
      return Strategy(
        [
          ...sizingOptions,
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

    // Mano en la frontera: estrategia mixta real (ambas acciones tienen
    // frecuencia > 0 en el rango de referencia). Desde "FLOPly — Fase
    // 0.5": las dos son igual de defendibles ('viable') — la calidad NO
    // se deriva de la frecuencia exacta dentro de la frontera (antes acá
    // había un umbral freq >= 0.4 que subía una a 'veryGood', el error de
    // diseño que esa fase corrigió). [frequency] sigue guardando el dato
    // real para el texto informativo ("esto pasa ~X% de las veces");
    // simplemente deja de decidir la calidad.
    if (freq > 0.0) {
      return Strategy(
        [
          StrategyOption(
            action: raiseAction,
            frequency: freq,
            rating: StrategicRating.viable,
            justifyingConcepts: [...concepts, ConceptIds.mixedStrategies],
            rationaleKey: 'open.raise.frontier',
          ),
          StrategyOption(
            action: PokerAction.fold,
            frequency: 1 - freq,
            rating: StrategicRating.viable,
            justifyingConcepts: [ConceptIds.openingRange],
            rationaleKey: 'open.fold.frontier',
          ),
        ],
        summaryKey: 'open.summary.frontier',
      );
    }

    // Mano fuera de rango: ¿qué tan lejos?
    final distance = _distanceOutsideRange(position, notation);
    final borderline = distance <= 1.6;
    final raiseRating =
        borderline ? StrategicRating.dubious : StrategicRating.bad;

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
          rationaleKey: borderline
              ? 'open.raise.borderline_out'
              : 'open.raise.out_of_range',
          // Justo por fuera del rango de referencia ("forzar un poco la
          // situación", ver el rationale) es defendible o no según qué
          // tan pasiva/explotable sea la mesa — una variable que el
          // ejercicio no le muestra al alumno. Bien fuera de rango es
          // simplemente un error, sin ese matiz.
          contextSensitivity: borderline
              ? ContextSensitivity.dependent([ContextFactor.opponentProfile])
              : const ContextSensitivity.stable(),
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

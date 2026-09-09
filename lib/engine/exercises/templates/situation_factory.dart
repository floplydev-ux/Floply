import '../../poker/deck.dart';
import '../../poker/hole_cards.dart';
import '../../poker/poker_action.dart';
import '../../poker/position.dart';
import '../../poker/street.dart';
import '../poker_situation.dart';

/// Utilidades para armar [PokerSituation] preflop coherentes a partir de
/// la baraja sembrada. Centraliza la construcción del historial de folds
/// para que ningún template lo arme mal.
class SituationFactory {
  const SituationFactory._();

  /// Situación "todos foldean hasta el héroe" (open raise first in).
  static PokerSituation firstIn({
    required Position heroPosition,
    required HoleCards heroCards,
    required double effectiveStackBb,
    List<double> availableRaiseSizes = const [],
  }) {
    final history = [
      for (final pos in heroPosition.earlierPositions)
        PriorAction(pos, PokerAction.fold),
    ];
    return PokerSituation(
      heroPosition: heroPosition,
      heroCards: heroCards,
      street: Street.preflop,
      effectiveStackBb: effectiveStackBb,
      actionHistory: history,
      potBb: 1.5,
      toCallBb: 1.0,
      availableRaiseSizes: availableRaiseSizes,
    );
  }

  /// Elige un stack efectivo según la dificultad: fácil = 100bb; más
  /// difícil = a veces stacks no estándar (que igual no cambian la
  /// estrategia de apertura, pero agregan variables).
  static double stackForDifficulty(Deck deck, int difficulty) {
    if (difficulty <= 2) return 100;
    return deck.pick(const [60.0, 75.0, 100.0, 100.0, 120.0, 150.0, 40.0]);
  }

  /// Posiciones de apertura permitidas según dificultad.
  static List<Position> openerPoolForDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        return const [Position.utg, Position.btn];
      case 2:
        return const [Position.utg, Position.hj, Position.co, Position.btn];
      default:
        return Position.openers;
    }
  }
}

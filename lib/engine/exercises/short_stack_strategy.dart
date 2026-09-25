import '../concepts/concept_ids.dart';
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/poker_action.dart';
import '../strategy/preflop_authoring.dart';
import '../strategy/preflop_range_book.dart';
import '../strategy/strategy.dart';

/// Reemplazo real (Fase 1 del rediseño del motor preflop del
/// Laboratorio) de la rama "encarar una apertura a stack corto" de la
/// vieja `PreflopStrategy._facingRaiseStrategy`: en vez del mismo
/// percentil de Chen que usa el resto de decisiones a 100bb, aplica un
/// rango real de empuje-o-fold ([PreflopShortStackAnchor]) — teoría
/// estándar de push/fold, donde flatear desde un stack corto suele ser
/// peor que jugarse todo o retirarse.
///
/// **Alcance deliberado**: una sola profundidad de stack (ver el
/// doc-comment de [PreflopShortStackAnchor]) — no hay tiers todavía.
/// Solo cubre los pares con una ancla real; `PreflopStrategy.forDecision`
/// decide cuándo llamar acá y cuándo caer de vuelta a la heurística
/// vieja.
class ShortStackStrategy {
  const ShortStackStrategy._();

  static const List<String> _concepts = [
    ConceptIds.call,
    ConceptIds.bbDefense,
  ];

  static Strategy forDecision(
      GameState state, int heroSlot, PreflopShortStackAnchor anchor) {
    final hero = state.seatAt(heroSlot);
    final notation = hero.holeCards!.notation;
    final shoveAction = _shoveAction(state);

    if (anchor.shoveRange.contains(notation)) {
      return Strategy([
        StrategyOption(
          action: shoveAction,
          frequency: 1.0,
          rating: StrategicRating.optimal,
          role: StrategyRole.jamValue,
          justifyingConcepts: _concepts,
          rationaleKey: 'short_stack.shove.value',
        ),
        StrategyOption(
          action: const PokerAction(ActionType.call),
          frequency: 0.0,
          rating: StrategicRating.dubious,
          justifyingConcepts: _concepts,
          rationaleKey: 'short_stack.call.surrenders_fold_equity',
          // Pagar sin ir all-in a este stack renuncia a la fold equity
          // sin ganar nada a cambio — defendible en algún contexto
          // (inducir, jugar postflop con ventaja de rango), pero eso
          // depende de info que el ejercicio no muestra.
          contextSensitivity: ContextSensitivity.dependent(
            [ContextFactor.stackDepth, ContextFactor.opponentProfile],
          ),
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          role: StrategyRole.fold,
          justifyingConcepts: _concepts,
          rationaleKey: 'short_stack.fold.value',
        ),
      ]);
    }

    return Strategy([
      const StrategyOption(
        action: PokerAction.fold,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        role: StrategyRole.fold,
        justifyingConcepts: _concepts,
        rationaleKey: 'short_stack.fold.out_of_range',
      ),
      const StrategyOption(
        action: PokerAction(ActionType.call),
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: _concepts,
        rationaleKey: 'short_stack.call.out_of_range',
      ),
      StrategyOption(
        action: shoveAction,
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: _concepts,
        rationaleKey: 'short_stack.shove.out_of_range',
      ),
    ]);
  }

  /// Todo el stack — el máximo legal, siempre (nunca un tamaño
  /// intermedio: empuje-o-fold es, por definición, jugarse todo).
  static PokerAction _shoveAction(GameState state) =>
      PokerAction.raiseTo(LegalActionEngine.maxRaiseToBb(state));
}

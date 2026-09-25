import '../concepts/concept_ids.dart';
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/poker_action.dart';
import '../strategy/preflop_authoring.dart';
import '../strategy/preflop_range_book.dart';
import '../strategy/strategy.dart';

/// Reemplazo real (Fase 1 del rediseño del motor preflop del
/// Laboratorio) de la rama "encarar un 3-bet" de la vieja
/// `PreflopStrategy._facingRaiseStrategy`: el héroe ya fue el agresor
/// preflop y ahora decide fold/call/4-bet contra un 3-bet real
/// (sampleado de [PreflopRangeBook], ver `ExerciseScenarioBuilder.
/// facingThreeBet`), en vez del mismo percentil de Chen que usa
/// [DefenseVsOpenStrategy] para una situación distinta.
///
/// **Alcance deliberado**: solo modela fold/call/4-bet de valor — nunca
/// un 4-bet como farol (deuda reconocida, no silenciada; ver
/// `PreflopFacingThreeBetAnchor`). Solo cubre los pares con una
/// [PreflopFacingThreeBetAnchor] real — `PreflopStrategy.forDecision`
/// decide cuándo llamar acá y cuándo caer de vuelta a la heurística
/// vieja.
class FacingThreeBetStrategy {
  const FacingThreeBetStrategy._();

  static const List<String> _valueConcepts = [
    ConceptIds.call,
    ConceptIds.threeBet,
    ConceptIds.threeBetValue,
  ];

  static const List<String> _standardConcepts = [
    ConceptIds.call,
    ConceptIds.threeBet,
  ];

  static Strategy forDecision(
      GameState state, int heroSlot, PreflopFacingThreeBetAnchor anchor) {
    final hero = state.seatAt(heroSlot);
    final notation = hero.holeCards!.notation;
    final fourBetAction = _fourBetSizeAction(state);

    if (anchor.fourBetValueRange.contains(notation)) {
      return Strategy([
        StrategyOption(
          action: fourBetAction,
          frequency: 1.0,
          rating: StrategicRating.optimal,
          role: StrategyRole.fourBetValue,
          justifyingConcepts: _valueConcepts,
          rationaleKey: 'facing_three_bet.raise.value',
        ),
        const StrategyOption(
          action: PokerAction(ActionType.call),
          frequency: 0.0,
          rating: StrategicRating.viable,
          role: StrategyRole.defend,
          justifyingConcepts: _standardConcepts,
          rationaleKey: 'facing_three_bet.call.value_flat',
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          role: StrategyRole.fold,
          justifyingConcepts: _standardConcepts,
          rationaleKey: 'facing_three_bet.fold.value',
        ),
      ]);
    }

    if (anchor.callRange.contains(notation)) {
      return Strategy([
        const StrategyOption(
          action: PokerAction(ActionType.call),
          frequency: 1.0,
          rating: StrategicRating.optimal,
          role: StrategyRole.defend,
          justifyingConcepts: _standardConcepts,
          rationaleKey: 'facing_three_bet.call.standard',
        ),
        StrategyOption(
          action: fourBetAction,
          frequency: 0.0,
          rating: StrategicRating.bad,
          justifyingConcepts: const [ConceptIds.threeBet],
          rationaleKey: 'facing_three_bet.raise.no_merit',
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          role: StrategyRole.fold,
          justifyingConcepts: _standardConcepts,
          rationaleKey: 'facing_three_bet.fold.standard',
        ),
      ]);
    }

    return Strategy([
      const StrategyOption(
        action: PokerAction.fold,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        role: StrategyRole.fold,
        justifyingConcepts: _standardConcepts,
        rationaleKey: 'facing_three_bet.fold.out_of_range',
      ),
      const StrategyOption(
        action: PokerAction(ActionType.call),
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: _standardConcepts,
        rationaleKey: 'facing_three_bet.call.out_of_range',
      ),
      StrategyOption(
        action: fourBetAction,
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: const [ConceptIds.threeBet],
        rationaleKey: 'facing_three_bet.raise.out_of_range',
      ),
    ]);
  }

  /// ~2.2x el 3-bet actual, clampeado a lo legal — un incremento más
  /// chico que el 3x de `DefenseVsOpenStrategy`: ya hay más plata en el
  /// medio, así que el mismo múltiplo sería desproporcionado.
  static PokerAction _fourBetSizeAction(GameState state) {
    final desired = state.round.currentBetBb * 2.2;
    final min = LegalActionEngine.minRaiseToBb(state);
    final max = LegalActionEngine.maxRaiseToBb(state);
    final clamped = desired < min ? min : (desired > max ? max : desired);
    return PokerAction.raiseTo(clamped);
  }
}

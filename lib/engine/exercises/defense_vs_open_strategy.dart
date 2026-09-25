import '../concepts/concept_ids.dart';
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/poker_action.dart';
import '../strategy/preflop_authoring.dart';
import '../strategy/preflop_range_book.dart';
import '../strategy/strategy.dart';

/// Reemplazo real (Fase 1 del rediseño del motor preflop del
/// Laboratorio) de la rama "encarar una apertura" de la vieja
/// `PreflopStrategy._facingRaiseStrategy`: en vez de un único percentil
/// de Chen para toda decisión de "enfrentar una subida" (ignorando
/// posición, rango real del rival y sizing), consulta una tabla real
/// por par de posiciones ([PreflopRangeBook]).
///
/// Solo cubre los pares de posición con una [PreflopRangeAnchor] real
/// — `PreflopStrategy.forDecision` es quien decide cuándo llamar acá y
/// cuándo caer de vuelta a la heurística vieja (ver su doc-comment).
class DefenseVsOpenStrategy {
  const DefenseVsOpenStrategy._();

  static const List<String> _valueConcepts = [
    ConceptIds.call,
    ConceptIds.bbDefense,
    ConceptIds.threeBet,
    ConceptIds.threeBetValue,
  ];

  static const List<String> _bluffConcepts = [
    ConceptIds.call,
    ConceptIds.bbDefense,
    ConceptIds.threeBet,
    ConceptIds.threeBetBluff,
    ConceptIds.blockers,
  ];

  static const List<String> _standardConcepts = [
    ConceptIds.call,
    ConceptIds.bbDefense,
  ];

  /// La estrategia para [heroSlot] en [state], usando [anchor] — el
  /// caller (`PreflopStrategy.forDecision`) ya resolvió que [anchor]
  /// corresponde de verdad a la posición del héroe y la del rival que
  /// abrió.
  static Strategy forDecision(GameState state, int heroSlot, PreflopRangeAnchor anchor) {
    final hero = state.seatAt(heroSlot);
    final notation = hero.holeCards!.notation;
    final raiseAction = _threeBetSizeAction(state);

    if (anchor.threeBetValueRange.contains(notation)) {
      return Strategy([
        StrategyOption(
          action: raiseAction,
          frequency: 1.0,
          rating: StrategicRating.optimal,
          role: StrategyRole.value,
          justifyingConcepts: _valueConcepts,
          rationaleKey: 'defense_vs_open.raise.value',
        ),
        const StrategyOption(
          action: PokerAction(ActionType.call),
          frequency: 0.0,
          rating: StrategicRating.viable,
          role: StrategyRole.defend,
          justifyingConcepts: _standardConcepts,
          rationaleKey: 'defense_vs_open.call.value_flat',
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          role: StrategyRole.fold,
          justifyingConcepts: _standardConcepts,
          rationaleKey: 'defense_vs_open.fold.value',
        ),
      ]);
    }

    if (anchor.threeBetBluffRange.contains(notation)) {
      return Strategy([
        const StrategyOption(
          action: PokerAction(ActionType.call),
          frequency: 1.0,
          rating: StrategicRating.optimal,
          role: StrategyRole.defend,
          justifyingConcepts: _bluffConcepts,
          rationaleKey: 'defense_vs_open.call.bluff_candidate',
        ),
        StrategyOption(
          action: raiseAction,
          frequency: 0.0,
          rating: StrategicRating.dubious,
          role: StrategyRole.bluff,
          justifyingConcepts: _bluffConcepts,
          rationaleKey: 'defense_vs_open.raise.bluff',
          // El 3-bet acá no tiene respaldo de valor — que sea
          // defendible depende del rango de apertura real del rival y
          // de cuánto se retira ante un 3-bet, ninguna de las dos
          // visible para el alumno en el ejercicio.
          contextSensitivity: ContextSensitivity.dependent(
            [ContextFactor.opponentProfile, ContextFactor.villainRange],
          ),
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          role: StrategyRole.fold,
          justifyingConcepts: _bluffConcepts,
          rationaleKey: 'defense_vs_open.fold.bluff_candidate',
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
          rationaleKey: 'defense_vs_open.call.standard',
        ),
        StrategyOption(
          action: raiseAction,
          frequency: 0.0,
          rating: StrategicRating.bad,
          justifyingConcepts: const [ConceptIds.threeBet],
          rationaleKey: 'defense_vs_open.raise.no_merit',
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          role: StrategyRole.fold,
          justifyingConcepts: _standardConcepts,
          rationaleKey: 'defense_vs_open.fold.standard',
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
        rationaleKey: 'defense_vs_open.fold.out_of_range',
      ),
      const StrategyOption(
        action: PokerAction(ActionType.call),
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: _standardConcepts,
        rationaleKey: 'defense_vs_open.call.out_of_range',
      ),
      StrategyOption(
        action: raiseAction,
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: const [ConceptIds.threeBet],
        rationaleKey: 'defense_vs_open.raise.out_of_range',
      ),
    ]);
  }

  /// Mismo cálculo que la vieja `_facingRaiseStrategy`: 3x la apuesta
  /// actual, clampeado a lo legal — no se reinventa el sizing acá.
  static PokerAction _threeBetSizeAction(GameState state) {
    final desired = state.round.currentBetBb * 3;
    final min = LegalActionEngine.minRaiseToBb(state);
    final max = LegalActionEngine.maxRaiseToBb(state);
    final clamped = desired < min ? min : (desired > max ? max : desired);
    return PokerAction.raiseTo(clamped);
  }
}

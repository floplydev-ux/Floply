import '../concepts/concept_ids.dart';
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/poker_action.dart';
import '../strategy/hand_strength.dart';
import '../strategy/opening_ranges.dart';
import '../strategy/preflop_authoring.dart';
import '../strategy/preflop_range_book.dart';
import '../strategy/strategy.dart';
import '../strategy/strategy_engine.dart';
import 'defense_vs_open_strategy.dart';
import 'facing_three_bet_strategy.dart';
import 'poker_situation.dart';
import 'short_stack_strategy.dart';

/// Debajo de esta profundidad (BB), las tablas de [PreflopRangeBook]
/// pensadas para ~100bb dejan de aplicar — ver [ShortStackStrategy].
const double _shortStackThresholdBb = 20;

/// La estrategia "ground truth" (graduada, no binaria) para una decisión
/// preflop concreta — la pieza pensada para poder reemplazarse después
/// por algo más sofisticado sin que [ExerciseScenario] ni
/// [DecisionContext] se enteren: ninguno de los dos conoce esta clase,
/// solo [AnswerEvaluator].
///
/// Reutiliza [StrategyEngine.openRaiseStrategy] para la decisión que ya
/// cubre (first-in real); para las dos situaciones que no cubre — abrir
/// sobre limpers y enfrentar una subida — usa las mismas piezas de más
/// bajo nivel ([OpeningRanges], [HandStrength]) con reglas simples y
/// explícitas, documentadas como tales (no GTO).
class PreflopStrategy {
  const PreflopStrategy._();

  static const StrategyEngine _engine = StrategyEngine();

  /// La estrategia para la decisión del jugador en turno ([heroSlot]) en
  /// [state].
  ///
  /// **Fase 1 del rediseño (ver la memoria del proyecto
  /// `laboratorio-motor-preflop`)**: "encarar una subida" ahora consulta
  /// [PreflopRangeBook] cuando existe una tabla real para la situación
  /// exacta — reemplazo real de la vieja heurística de un único
  /// percentil de Chen para [_facingRaiseStrategy], que sigue existiendo
  /// solo como fallback para lo que ninguna tabla cubre todavía. Tres
  /// situaciones distintas, cada una con su propia clase y su propio
  /// tipo de ancla (nunca reutilizadas entre sí — ver el doc-comment de
  /// cada una):
  ///  * el héroe ya fue agresor esta calle y encara una re-subida real
  ///    → [FacingThreeBetStrategy] (fold/call/4-bet, nunca "3-bet" —
  ///    concepto distinto);
  ///  * el stack inicial de la mano es corto (< [_shortStackThresholdBb])
  ///    → [ShortStackStrategy] (empuje-o-fold, tablas de 100bb no
  ///    aplican);
  ///  * si no, encarar una apertura ajena → [DefenseVsOpenStrategy].
  /// Sin ancla real para la situación exacta, cualquiera de los tres
  /// casos cae de vuelta a [_facingRaiseStrategy] — nunca se inventa un
  /// rango sin fuente.
  static Strategy forDecision(GameState state, int heroSlot) {
    final facingRaise = state.round.currentBetBb > state.bigBlindBb;

    if (!facingRaise) {
      final trueFirstIn =
          state.round.log.every((entry) => entry.action.type == ActionType.fold);
      if (trueFirstIn) {
        return _engine.openRaiseStrategy(_toPokerSituation(state, heroSlot));
      }
      // StrategyEngine.openRaiseStrategy exige `isFirstIn` (que TODA
      // acción previa haya sido fold) — "abrir sobre limpers" no
      // cumple eso, así que no hay nada que reutilizar ahí. Mismo
      // criterio (OpeningRanges/HandStrength), expresado directo.
      return _openOverLimpersStrategy(state, heroSlot);
    }

    final villainSlot = state.round.lastAggressorSlot;
    final villainPosition = villainSlot == null ? null : state.positionOf(villainSlot);
    final heroPosition = state.positionOf(heroSlot);
    final heroAlreadyRaised = state.round.log
        .any((entry) => entry.slot == heroSlot && entry.action.type.isAggressive);

    if (heroAlreadyRaised) {
      final anchor = villainPosition == null
          ? null
          : PreflopRangeBook.facingThreeBetAnchorFor(heroPosition, villainPosition);
      if (anchor != null) {
        return FacingThreeBetStrategy.forDecision(state, heroSlot, anchor);
      }
      return _facingRaiseStrategy(state, heroSlot);
    }

    final hero = state.seatAt(heroSlot);
    final startingStackBb = hero.stackBb + hero.investedTotalBb;
    if (startingStackBb < _shortStackThresholdBb) {
      final anchor = villainPosition == null
          ? null
          : PreflopRangeBook.shortStackAnchorFor(heroPosition, villainPosition);
      if (anchor != null) {
        return ShortStackStrategy.forDecision(state, heroSlot, anchor);
      }
      return _facingRaiseStrategy(state, heroSlot);
    }

    final anchor =
        villainPosition == null ? null : PreflopRangeBook.anchorFor(heroPosition, villainPosition);
    if (anchor != null) {
      return DefenseVsOpenStrategy.forDecision(state, heroSlot, anchor);
    }

    return _facingRaiseStrategy(state, heroSlot);
  }

  static PokerSituation _toPokerSituation(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    return PokerSituation(
      heroPosition: state.positionOf(heroSlot),
      heroCards: hero.holeCards!,
      street: state.street,
      effectiveStackBb: hero.stackBb,
      board: state.board,
      actionHistory: [
        for (final entry in state.round.log)
          PriorAction(state.positionOf(entry.slot), entry.action),
      ],
      potBb: state.pot.totalBb,
      toCallBb: state.round.currentBetBb - hero.investedThisStreetBb,
    );
  }

  static Strategy _openOverLimpersStrategy(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final hand = hero.holeCards!;
    final position = state.positionOf(heroSlot);
    final range = OpeningRanges.forPosition(position);
    final freq = range.frequencyOf(hand.notation);
    final raiseAction = PokerAction.raiseTo(OpeningRanges.sizingFor(position));
    const concepts = [
      ConceptIds.positionAdvantage,
      ConceptIds.openingRange,
      ConceptIds.openRaise,
    ];

    if (freq >= 0.75) {
      return Strategy([
        StrategyOption(
          action: raiseAction,
          frequency: 1.0,
          rating: StrategicRating.optimal,
          justifyingConcepts: concepts,
          rationaleKey: 'open_over_limpers.raise.in_range',
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          justifyingConcepts: [ConceptIds.openingRange],
          rationaleKey: 'open_over_limpers.fold.too_strong',
        ),
      ]);
    }

    if (freq > 0.0) {
      // Frontera: mismo criterio que `StrategyEngine.openRaiseStrategy`
      // desde "FLOPly — Fase 0.5" — ambas acciones son igual de
      // defendibles ('viable'), la calidad no se deriva del umbral de
      // frecuencia que había acá antes (freq >= 0.4).
      return Strategy([
        StrategyOption(
          action: raiseAction,
          frequency: freq,
          rating: StrategicRating.viable,
          justifyingConcepts: concepts,
          rationaleKey: 'open_over_limpers.raise.frontier',
        ),
        StrategyOption(
          action: const PokerAction(ActionType.fold),
          frequency: 1 - freq,
          rating: StrategicRating.viable,
          justifyingConcepts: const [ConceptIds.openingRange],
          rationaleKey: 'open_over_limpers.fold.frontier',
        ),
      ]);
    }

    return Strategy([
      const StrategyOption(
        action: PokerAction.fold,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: [ConceptIds.openingRange],
        rationaleKey: 'open_over_limpers.fold.out_of_range',
      ),
      StrategyOption(
        action: raiseAction,
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: concepts,
        rationaleKey: 'open_over_limpers.raise.out_of_range',
      ),
    ]);
  }

  /// Enfrentando una subida (el primer raise, un 3-bet, o más — esta
  /// pasada no distingue entre esos casos, misma regla simple para
  /// todos). Por percentil de [HandStrength] (0 = la mejor mano de las
  /// 169), mismo criterio de referencia que usa `OpponentPolicy`.
  static Strategy _facingRaiseStrategy(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final hand = hero.holeCards!;
    final percentile = HandStrength.percentile(hand.notation);
    final desiredRaise = state.round.currentBetBb * 3;
    final minRaise = LegalActionEngine.minRaiseToBb(state);
    final maxRaise = LegalActionEngine.maxRaiseToBb(state);
    final clampedRaise =
        desiredRaise < minRaise ? minRaise : (desiredRaise > maxRaise ? maxRaise : desiredRaise);
    final raiseAction = PokerAction.raiseTo(clampedRaise);

    if (percentile <= 0.06) {
      return Strategy([
        StrategyOption(
          action: raiseAction,
          frequency: 1.0,
          rating: StrategicRating.optimal,
          justifyingConcepts: const [ConceptIds.threeBet, ConceptIds.threeBetValue],
          rationaleKey: 'facing_raise.raise.premium',
          role: StrategyRole.value,
        ),
        const StrategyOption(
          action: PokerAction(ActionType.call),
          frequency: 0.0,
          rating: StrategicRating.viable,
          justifyingConcepts: [ConceptIds.call],
          rationaleKey: 'facing_raise.call.premium_flat',
          role: StrategyRole.defend,
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          justifyingConcepts: [ConceptIds.bbDefense],
          rationaleKey: 'facing_raise.fold.premium',
          role: StrategyRole.fold,
        ),
      ]);
    }

    if (percentile <= 0.35) {
      return Strategy([
        const StrategyOption(
          action: PokerAction(ActionType.call),
          frequency: 1.0,
          rating: StrategicRating.optimal,
          justifyingConcepts: [ConceptIds.call, ConceptIds.bbDefense],
          rationaleKey: 'facing_raise.call.defend',
          role: StrategyRole.defend,
        ),
        StrategyOption(
          action: raiseAction,
          frequency: 0.0,
          rating: StrategicRating.dubious,
          justifyingConcepts: const [ConceptIds.threeBet],
          rationaleKey: 'facing_raise.raise.light',
          role: StrategyRole.bluff,
          // Un 3-bet liviano acá no tiene el respaldo de valor de la
          // banda premium — que sea defendible o no depende del rango de
          // apertura real del rival y de qué tan seguido se retira ante
          // un 3-bet, dos variables que el ejercicio no le muestra al
          // alumno (ve su propia mano y la acción, no el perfil del
          // rival). Distinto del call/fold de esta misma banda, que son
          // correctos sin importar esas variables.
          contextSensitivity: ContextSensitivity.dependent(
            [ContextFactor.opponentProfile, ContextFactor.villainRange],
          ),
        ),
        const StrategyOption(
          action: PokerAction.fold,
          frequency: 0.0,
          rating: StrategicRating.bad,
          justifyingConcepts: [ConceptIds.bbDefense],
          rationaleKey: 'facing_raise.fold.defendable',
          role: StrategyRole.fold,
        ),
      ]);
    }

    return Strategy(const [
      StrategyOption(
        action: PokerAction.fold,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: [ConceptIds.bbDefense],
        rationaleKey: 'facing_raise.fold.weak',
        role: StrategyRole.fold,
      ),
      StrategyOption(
        action: PokerAction(ActionType.call),
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: [ConceptIds.call],
        rationaleKey: 'facing_raise.call.weak',
        role: StrategyRole.defend,
      ),
    ]);
  }
}

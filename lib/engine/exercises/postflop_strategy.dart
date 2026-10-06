import '../concepts/concept_ids.dart';
import '../poker/card.dart';
import '../poker/equity/equity_engine.dart';
import '../poker/game/game_state.dart';
import '../poker/hole_cards.dart';
import '../poker/poker_action.dart';
import '../poker/position.dart';
import '../poker/street.dart';
import '../strategy/decision_math.dart';
import '../strategy/hand_range.dart';
import '../strategy/opening_ranges.dart';
import '../strategy/preflop_authoring.dart';
import '../strategy/preflop_range_book.dart';
import '../strategy/strategy.dart';

/// La estrategia "ground truth" para decisiones POSTFLOP — hermana de
/// `PreflopStrategy` (`preflop_strategy.dart`), nunca la reemplaza ni la
/// extiende: preflop (169 clases de mano, tabla fija) y postflop (board
/// concreto, texturas casi infinitas) son problemas de autoría
/// distintos, así que viven en clases separadas desde el arranque en
/// vez de forzar el nombre "preflop" a cubrir algo que no es. Ver
/// `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md` para la justificación
/// completa de diseño.
///
/// **Alcance de esta pasada — cuatro situaciones reales, cada una
/// definida con precisión** (nunca "postflop en general"): la decisión
/// de c-apostar el flop siendo el agresor ([_cbetStrategy], la familia
/// original), encarar una apuesta real en el turn siendo el defensor
/// ([_facingCbetStrategy] — el flop que la precede es de guion, ver el
/// doc-comment de `ExerciseScenarioBuilder.facingCbet` sobre por qué
/// esta decisión vive en el turn y no en el flop), y decidir un
/// segundo/tercer barril en turn/river siendo el agresor
/// ([_barrelStrategy], compartida por `turnBarrel`/`riverBarrel` — la
/// pregunta es idéntica un board más adelante). Cualquier otra
/// situación postflop lanza [UnsupportedError] — mismo criterio de
/// honestidad que ya usa `OpponentPolicy` (que decide no fingir cubrir
/// postflop en vez de inventar una regla sin fundamento): esta clase es
/// honesta sobre cubrir solo estas situaciones, no "postflop en
/// general".
///
/// **Fundamento real, no heurística inventada**: las tres decisiones
/// nuevas ([_facingCbetStrategy]/[_barrelStrategy]) se resuelven con
/// equity real (`EquityEngine.handVsRange`) contra el rango de apertura
/// preflop del rival (`OpeningRanges.forPosition`) — la misma
/// simplificación ya documentada en otras partes del motor (usar el
/// rango de apertura como proxy de "lo que el rival puede tener" cuando
/// no existe una tabla más específica, ver `HandPicker.forBias`/
/// `_facingRaiseStrategy`). Es una sobreestimación deliberadamente
/// conservadora del rango real del rival (que en la práctica ya se
/// achicó al pagar una apuesta), así que la equity calculada acá nunca
/// exagera a favor del héroe.
class PostflopStrategy {
  const PostflopStrategy._();

  /// Memoiza `EquityEngine.handVsRange` por [GameState] — pura
  /// optimización, ningún cambio de resultado: `ExerciseScenarioAdapter.
  /// adapt` (que no se toca en esta pasada) llama a
  /// `AnswerEvaluator.evaluate` una vez por cada acción legal más una
  /// vez más para elegir tamaños de subida — hasta 4 veces la MISMA
  /// equity, sobre el MISMO estado, en una sola carga de ejercicio. Con
  /// un rango de apertura ancho (BTN, ~600 combos) cada cálculo real de
  /// equity en el turn puede tardar más de un segundo; sin esta cache,
  /// una sola carga de ejercicio pagaría ese costo 4 veces. Clave por
  /// identidad de [GameState] (cada escenario arma un `GameState` nuevo,
  /// nunca reutiliza uno viejo) — se limpia sola si crece de más para no
  /// acumular memoria indefinidamente en una sesión larga.
  static final Map<int, double> _equityCache = {};

  static double _equityVsRange(GameState state, int aggressorOrVillainSlot,
      HoleCards heroHand, HandRange range, List<Card> board) {
    if (_equityCache.length > 64) _equityCache.clear();
    final key = Object.hash(identityHashCode(state), aggressorOrVillainSlot);
    return _equityCache.putIfAbsent(
        key, () => EquityEngine.handVsRange(heroHand, range, board).equity);
  }

  /// Margen sobre el cual una diferencia entre equity real y pot odds
  /// necesarias se considera "clara" en vez de "al filo" — mismo criterio
  /// en las tres decisiones nuevas, para no inventar un número distinto
  /// por familia sin motivo.
  static const double _clearMarginEquity = 0.08;

  /// Piso de equity contra el rango de apertura del rival a partir del
  /// cual seguir apostando (barril) es la línea de valor — por debajo,
  /// controlar el bote con un check es la línea más sólida. Simplificado
  /// y citable a propósito (ver el doc-comment de la clase): no es un
  /// solve, es "¿tu mano le sigue ganando, en promedio, al rango de
  /// apertura del rival?".
  static const double _barrelEquityFloor = 0.55;

  /// La estrategia para la decisión del jugador en turno ([heroSlot]) en
  /// [state]. Lanza [UnsupportedError] si [state] no es exactamente una
  /// de las situaciones que esta pasada cubre.
  static Strategy forDecision(GameState state, int heroSlot) {
    if (state.street == Street.flop && _isCbetSpot(state, heroSlot)) {
      return _cbetStrategy(state, heroSlot);
    }
    if (state.street == Street.turn) {
      if (_isFacingCbetSpot(state, heroSlot)) {
        return _facingCbetStrategy(state, heroSlot);
      }
      if (_isBarrelSpot(state, heroSlot)) return _barrelStrategy(state, heroSlot);
    }
    if (state.street == Street.river && _isBarrelSpot(state, heroSlot)) {
      return _barrelStrategy(state, heroSlot);
    }
    throw UnsupportedError(
        'PostflopStrategy: esta situación (street: ${state.street}) no es '
        'ninguna de las que esta pasada cubre — ver el doc-comment de la '
        'clase para el alcance exacto.');
  }

  // ==================================================================
  // C-bet (agresor) — familia original
  // ==================================================================

  static bool _isCbetSpot(GameState state, int heroSlot) {
    if (state.streetHistory.isEmpty ||
        state.streetHistory.last.lastAggressorSlot != heroSlot) {
      return false;
    }
    final log = state.round.log;
    return log.length == 1 &&
        log.single.action.type == ActionType.check &&
        boardFavorsAggressor(state.board);
  }

  static Strategy _cbetStrategy(GameState state, int heroSlot) {
    return Strategy([
      // Sin `sizeBb`: la lección de esta familia es "hay que c-apostar",
      // no "con qué tamaño exacto" — cualquier tamaño de apuesta que
      // ofrezca la UI (ver `ExerciseScenarioAdapter._recommendedSizes`)
      // tiene que calificar igual de bien (`PokerAction.matches` trata
      // `sizeBb: null` como "cualquier tamaño sirve").
      const StrategyOption(
        action: PokerAction(ActionType.bet),
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: [
          ConceptIds.cbet,
          ConceptIds.boardTexture,
          ConceptIds.rangeAdvantage,
        ],
        rationaleKey: 'cbet.bet',
      ),
      const StrategyOption(
        action: PokerAction(ActionType.check),
        frequency: 0.0,
        rating: StrategicRating.dubious,
        justifyingConcepts: [
          ConceptIds.cbet,
          ConceptIds.boardTexture,
          ConceptIds.rangeAdvantage,
        ],
        rationaleKey: 'cbet.check',
      ),
    ]);
  }

  /// Heurística deliberadamente simple y citable de cuándo un flop
  /// favorece lo bastante al rango del agresor preflop como para
  /// justificar una c-bet de rango completo — el ejemplo más repetido
  /// en teoría de póker introductoria: un flop sin pares, sin proyecto
  /// de color (rainbow) y con la carta más alta As o Rey (p. ej.
  /// K♠7♦2♣). No es una clasificación general de texturas de board —
  /// boards conectados, con proyecto, o sin carta alta quedan fuera de
  /// lo que esta pasada sabe evaluar a propósito, no por descuido. Ver
  /// `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md` §3/§10 para el alcance
  /// deliberado y sus límites.
  static bool boardFavorsAggressor(List<Card> board) {
    if (board.length != 3) return false;
    final ranks = board.map((c) => c.rank).toSet();
    final suits = board.map((c) => c.suit).toSet();
    final isUnpaired = ranks.length == board.length;
    final isRainbow = suits.length == board.length;
    final hasHighCard = board.any((c) => c.rank == Rank.ace || c.rank == Rank.king);
    return isUnpaired && isRainbow && hasHighCard;
  }

  // ==================================================================
  // Encarar continuación real en el turn (defensor con posición) — nueva
  // ==================================================================

  /// `true` si, en el turn, el héroe (que pagó un flop de guion, ver
  /// `ExerciseScenarioBuilder.facingCbet`) encara una apuesta real de
  /// quien fue agresor tanto en el flop como preflop.
  static bool _isFacingCbetSpot(GameState state, int heroSlot) {
    final log = state.round.log;
    if (log.length != 1) return false;
    final entry = log.single;
    if (entry.action.type != ActionType.bet && entry.action.type != ActionType.raise) {
      return false;
    }
    if (entry.slot == heroSlot) return false;
    // Quien apostó tiene que ser el mismo que fue agresor en el flop —
    // si no, es una situación distinta (p. ej. un check-raise de un
    // tercero) que esta pasada no contempla.
    return state.streetHistory.isNotEmpty &&
        state.streetHistory.last.lastAggressorSlot == entry.slot;
  }

  static Strategy _facingCbetStrategy(GameState state, int heroSlot) {
    final aggressorSlot = state.round.log.single.slot;
    final hero = state.seatAt(heroSlot);
    final heroHand = hero.holeCards!;
    final aggressorRange = OpeningRanges.forPosition(state.positionOf(aggressorSlot));

    final equity =
        _equityVsRange(state, aggressorSlot, heroHand, aggressorRange, state.board);

    final toCallBb = state.round.currentBetBb - hero.investedThisStreetBb;
    final potBb = state.pot.totalBb;
    final requiredEquity = toCallBb / (potBb + toCallBb);
    final edge = equity - requiredEquity;

    const concepts = [ConceptIds.potOdds, ConceptIds.equity, ConceptIds.call];
    final math = DecisionMath(
      equityPct: equity * 100,
      requiredEquityPct: requiredEquity * 100,
      edgePct: edge * 100,
      potBb: potBb,
      toCallBb: toCallBb,
      stackBb: hero.stackBb,
    );

    StrategyOption call;
    StrategyOption fold;
    if (edge > _clearMarginEquity) {
      call = StrategyOption(
        action: const PokerAction(ActionType.call),
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: concepts,
        rationaleKey: 'facing_cbet.call.value',
        math: math,
      );
      fold = StrategyOption(
        action: PokerAction.fold,
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: concepts,
        rationaleKey: 'facing_cbet.fold.mistake',
        math: math,
      );
    } else if (edge < -_clearMarginEquity) {
      call = StrategyOption(
        action: const PokerAction(ActionType.call),
        frequency: 0.0,
        rating: StrategicRating.bad,
        justifyingConcepts: concepts,
        rationaleKey: 'facing_cbet.call.mistake',
        math: math,
      );
      fold = StrategyOption(
        action: PokerAction.fold,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: concepts,
        rationaleKey: 'facing_cbet.fold.value',
        math: math,
      );
    } else {
      // Al filo: la equity real está a menos de `_clearMarginEquity` de
      // lo necesario — ambas líneas son defendibles, ninguna es
      // claramente un error.
      call = StrategyOption(
        action: const PokerAction(ActionType.call),
        frequency: 0.5,
        rating: StrategicRating.viable,
        justifyingConcepts: concepts,
        rationaleKey: 'facing_cbet.call.close',
        math: math,
      );
      fold = StrategyOption(
        action: PokerAction.fold,
        frequency: 0.5,
        rating: StrategicRating.viable,
        justifyingConcepts: concepts,
        rationaleKey: 'facing_cbet.fold.close',
        math: math,
      );
    }

    // Re-subir (farol o valor) depende de la frecuencia de fold del
    // rival — un dato que este ejercicio no le muestra al alumno (no hay
    // ningún `OpponentPolicy` postflop que la modele, ver el doc-comment
    // de esa clase), así que nunca se marca como claramente correcta ni
    // claramente incorrecta: es honestamente `dependent` salvo con
    // equity ya muy alta, donde re-subir por valor es al menos una línea
    // razonable.
    final raiseAction = PokerAction.raiseTo(_valueRaiseSizeBb(state));
    final raise = equity >= 0.65
        ? StrategyOption(
            action: raiseAction,
            frequency: 0.0,
            rating: StrategicRating.viable,
            justifyingConcepts: const [ConceptIds.equity, ConceptIds.valueBet],
            rationaleKey: 'facing_cbet.raise.value',
            math: math,
          )
        : StrategyOption(
            action: raiseAction,
            frequency: 0.0,
            rating: StrategicRating.dubious,
            justifyingConcepts: const [ConceptIds.bluff],
            rationaleKey: 'facing_cbet.raise.bluff',
            contextSensitivity: ContextSensitivity.dependent(
              const [ContextFactor.opponentProfile, ContextFactor.villainRange],
            ),
            math: math,
          );

    return Strategy([call, fold, raise]);
  }

  static double _valueRaiseSizeBb(GameState state) {
    final desired = state.round.currentBetBb * 2.5;
    final slot = state.toActSlot!;
    final player = state.seatAt(slot);
    final max = player.investedThisStreetBb + player.stackBb;
    return desired > max ? max : desired;
  }

  // ==================================================================
  // Segundo/tercer barril (agresor en turn o river) — nueva
  // ==================================================================

  /// `true` si la calle anterior terminó en apuesta del héroe + pago del
  /// rival (de guion, ver `ExerciseScenarioBuilder.turnBarrel`/
  /// `riverBarrel`) y en la calle actual el rival ya checkeó — el mismo
  /// patrón que [_isCbetSpot], un paso más adelante en la mano. Mira
  /// solo las ÚLTIMAS dos entradas de la calle anterior (no exige que
  /// sean las únicas): el héroe tiene posición sobre el rival, así que
  /// esa calle arranca con el check del rival ANTES del bet del héroe —
  /// tres entradas en total, no dos.
  static bool _isBarrelSpot(GameState state, int heroSlot) {
    if (state.streetHistory.isEmpty) return false;
    final previous = state.streetHistory.last;
    if (previous.lastAggressorSlot != heroSlot) return false;
    final previousLog = previous.log;
    if (previousLog.length < 2) return false;
    final betEntry = previousLog[previousLog.length - 2];
    final callEntry = previousLog[previousLog.length - 1];
    final betOk = betEntry.slot == heroSlot && betEntry.action.type == ActionType.bet;
    final callOk = callEntry.slot != heroSlot && callEntry.action.type == ActionType.call;
    if (!betOk || !callOk) return false;

    final log = state.round.log;
    return log.length == 1 && log.single.action.type == ActionType.check;
  }

  /// El rango del rival contra el que medir equity: la tabla real de
  /// [PreflopRangeBook] (rango de DEFENSA, no de apertura — más preciso
  /// para un villano que está pagando, no abriendo) cuando existe una
  /// ancla para el par exacto; si no, el rango de apertura de
  /// [villainPosition] como proxy (misma simplificación documentada en
  /// el doc-comment de la clase). Nunca `OpeningRanges.forPosition(bb)`
  /// a secas: está vacío por definición (la BB nunca abre) — sin ancla
  /// real para ese par, `ScenarioRandomizer` ya evita generar la
  /// combinación en primer lugar (ver su doc-comment).
  static HandRange _villainRangeFor(Position villainPosition, Position heroPosition) =>
      PreflopRangeBook.anchorFor(villainPosition, heroPosition)?.callRange ??
      OpeningRanges.forPosition(villainPosition);

  static Strategy _barrelStrategy(GameState state, int heroSlot) {
    final villainSlot = state.round.log.single.slot;
    final hero = state.seatAt(heroSlot);
    final heroHand = hero.holeCards!;
    final villainRange =
        _villainRangeFor(state.positionOf(villainSlot), state.positionOf(heroSlot));

    final equity =
        _equityVsRange(state, villainSlot, heroHand, villainRange, state.board);

    final concepts = [
      ConceptIds.valueBet,
      ConceptIds.equity,
      if (state.street == Street.river) ConceptIds.ev,
    ];
    final math = DecisionMath(
      equityPct: equity * 100,
      potBb: state.pot.totalBb,
      stackBb: hero.stackBb,
    );

    final betsForValue = equity >= _barrelEquityFloor;
    return Strategy([
      StrategyOption(
        action: const PokerAction(ActionType.bet),
        frequency: betsForValue ? 1.0 : 0.0,
        rating: betsForValue ? StrategicRating.optimal : StrategicRating.dubious,
        justifyingConcepts: concepts,
        rationaleKey: betsForValue ? 'barrel.bet.value' : 'barrel.bet.mistake',
        math: math,
      ),
      StrategyOption(
        action: const PokerAction(ActionType.check),
        frequency: betsForValue ? 0.0 : 1.0,
        rating: betsForValue ? StrategicRating.dubious : StrategicRating.optimal,
        justifyingConcepts: concepts,
        rationaleKey: betsForValue ? 'barrel.check.mistake' : 'barrel.check.control',
        math: math,
      ),
    ]);
  }
}

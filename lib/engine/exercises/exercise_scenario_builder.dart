import '../concepts/concept_ids.dart';
import '../pedagogy/table_position.dart';
import '../poker/card.dart';
import '../poker/deck.dart';
import '../poker/game/action_resolver.dart';
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/game/opponent_policy.dart';
import '../poker/game/scenario_builder.dart';
import '../poker/generation_exception.dart';
import '../poker/hole_cards.dart';
import '../poker/poker_action.dart';
import '../poker/sizing/bet_sizing_engine.dart';
import '../strategy/opening_ranges.dart';
import '../strategy/preflop_range_book.dart';
import 'decision_context.dart';
import 'exercise_scenario.dart';
import 'postflop_strategy.dart';
import 'templates/hand_picker.dart';

/// Genera [ExerciseScenario]s preflop reales — orquesta el motor
/// existente (`ScenarioBuilder`, `ActionResolver`, `OpponentPolicy`)
/// hasta el punto exacto donde le toca decidir al héroe. Nunca toca
/// `stack`/`pot`/`currentBet`/etc. a mano: cada jugador "de fondo" (que
/// no es parte de la decisión pedagógica) se foldea con una acción real
/// vía `ActionResolver`, no con un atajo por fuera del motor.
class ExerciseScenarioBuilder {
  const ExerciseScenarioBuilder._();

  static const List<String> _openRaiseConcepts = [
    ConceptIds.positionAdvantage,
    ConceptIds.openingRange,
    ConceptIds.openRaise,
  ];

  static const List<String> _facingRaiseConcepts = [
    ConceptIds.call,
    ConceptIds.bbDefense,
    ConceptIds.threeBet,
    ConceptIds.threeBetValue,
  ];

  /// Tipo A — bote sin abrir: el héroe es el primero en entrar
  /// voluntariamente. `heroPosition == bb` no es una decisión de
  /// apertura real (si todos foldean, la BB gana el bote sin jugar) y
  /// lanza [ArgumentError].
  static ExerciseScenario openRaise({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.btn,
    HoleCards? heroHand,
    double stackBb = 100,
    OpponentProfile opponentProfile = OpponentProfile.balanced,
    HandBias heroHandBias = HandBias.any,
  }) {
    if (heroPosition == Position.bb) {
      throw ArgumentError(
          'openRaise: la BB no tiene una decisión de apertura real (si '
          'todos foldean, gana el bote sin jugar) — usá defenseVsOpen.');
    }
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final hand = heroHand ?? HandPicker.forBias(deck, heroPosition, heroHandBias);

    var state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: buttonSlot,
      stackBb: stackBb,
      explicitHandBySlot: {heroSlot: hand},
    );
    state = _resolveBackgroundActors(state, heroSlot, opponentProfile);

    return _finish(state, heroSlot, PreflopScenarioKind.openRaise, _openRaiseConcepts);
  }

  /// Tipo B — un rival abrió; el héroe decide fold/call/3-bet.
  static ExerciseScenario defenseVsOpen({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.bb,
    Position openerPosition = Position.co,
    HoleCards? heroHand,
    double stackBb = 100,
    OpponentProfile opponentProfile = OpponentProfile.balanced,
    HandBias heroHandBias = HandBias.any,
  }) =>
      _facingOpenScenario(
        deck: deck,
        buttonSlot: buttonSlot,
        heroPosition: heroPosition,
        openerPosition: openerPosition,
        heroHand: heroHand,
        stackBb: stackBb,
        kind: PreflopScenarioKind.defenseVsOpen,
        opponentProfile: opponentProfile,
        heroHandBias: heroHandBias,
      );

  /// Tipo C — mismo mecanismo que [defenseVsOpen]: la diferencia es
  /// pedagógica (posiciones por defecto), no de generación.
  static ExerciseScenario threeBet({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.btn,
    Position openerPosition = Position.utg,
    HoleCards? heroHand,
    double stackBb = 100,
    OpponentProfile opponentProfile = OpponentProfile.balanced,
    HandBias heroHandBias = HandBias.any,
  }) =>
      _facingOpenScenario(
        deck: deck,
        buttonSlot: buttonSlot,
        heroPosition: heroPosition,
        openerPosition: openerPosition,
        heroHand: heroHand,
        stackBb: stackBb,
        kind: PreflopScenarioKind.threeBet,
        opponentProfile: opponentProfile,
        heroHandBias: heroHandBias,
      );

  /// Tipo E — mismo mecanismo que [defenseVsOpen], con el stack del
  /// héroe forzado corto. La diferencia en las acciones legales sale
  /// sola de `LegalActionEngine`: no se agrega ninguna regla nueva.
  static ExerciseScenario shortStackFacingOpen({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.bb,
    Position openerPosition = Position.co,
    HoleCards? heroHand,
    double heroStackBb = 8,
    OpponentProfile opponentProfile = OpponentProfile.balanced,
    HandBias heroHandBias = HandBias.any,
  }) =>
      _facingOpenScenario(
        deck: deck,
        buttonSlot: buttonSlot,
        heroPosition: heroPosition,
        openerPosition: openerPosition,
        heroHand: heroHand,
        stackBb: heroStackBb,
        kind: PreflopScenarioKind.shortStack,
        opponentProfile: opponentProfile,
        heroHandBias: heroHandBias,
      );

  static ExerciseScenario _facingOpenScenario({
    required Deck deck,
    required int buttonSlot,
    required Position heroPosition,
    required Position openerPosition,
    required HoleCards? heroHand,
    required double stackBb,
    required PreflopScenarioKind kind,
    required OpponentProfile opponentProfile,
    required HandBias heroHandBias,
  }) {
    if (heroPosition == openerPosition) {
      throw ArgumentError('heroPosition y openerPosition no pueden ser la misma.');
    }
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final openerSlot = TablePositions(buttonSlot).slotOf(openerPosition);
    _requireActsBefore(buttonSlot, openerSlot, heroSlot,
        'defenseVsOpen/threeBet: openerPosition ($openerPosition) tiene que '
        'actuar antes que heroPosition ($heroPosition) preflop.');

    final hand = heroHand ?? HandPicker.forBias(deck, heroPosition, heroHandBias);
    // clearlyInRange garantiza que OpponentPolicy realmente suba acá —
    // sin esto, el rival podría foldear y el escenario dejaría de ser
    // lo que dice ser.
    final openerHand = HandPicker.forBias(deck, openerPosition, HandBias.clearlyInRange);

    var state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: buttonSlot,
      stackBb: stackBb,
      explicitHandBySlot: {heroSlot: hand, openerSlot: openerHand},
    );
    state = _resolveBackgroundActors(state, openerSlot, opponentProfile);
    state = ActionResolver.apply(state, OpponentPolicy.decide(state, profile: opponentProfile));
    state = _resolveBackgroundActors(state, heroSlot, opponentProfile);

    return _finish(state, heroSlot, kind, _facingRaiseConcepts,
        metadata: {'openerSlot': openerSlot, 'openerPosition': openerPosition.abbreviation});
  }

  /// Tipo D — el héroe abre primero (acción mecánica de armado, no
  /// evaluada), un rival re-sube; el héroe decide.
  static ExerciseScenario facingThreeBet({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.co,
    Position threeBettorPosition = Position.btn,
    HoleCards? heroHand,
    double stackBb = 100,
    OpponentProfile opponentProfile = OpponentProfile.balanced,
    HandBias heroHandBias = HandBias.any,
  }) {
    if (heroPosition == threeBettorPosition) {
      throw ArgumentError('heroPosition y threeBettorPosition no pueden ser la misma.');
    }
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final threeBettorSlot = TablePositions(buttonSlot).slotOf(threeBettorPosition);
    _requireActsBefore(buttonSlot, heroSlot, threeBettorSlot,
        'facingThreeBet: heroPosition ($heroPosition) tiene que actuar '
        'antes que threeBettorPosition ($threeBettorPosition) preflop.');

    final hand = heroHand ?? HandPicker.forBias(deck, heroPosition, heroHandBias);
    // `hand` puede venir de `heroHand` (nunca tocó `deck`) o de
    // `HandPicker` (ya la sacó del mazo) — de cualquier forma, hay que
    // garantizar que está afuera del mazo ANTES de samplear la mano del
    // 3-bettor más abajo, o ese sample podría pisarla (`Deck.remove` es
    // un no-op seguro si ya estaba afuera).
    deck.remove(hand.cards);

    // El rango real de 3-bet del rival (`PreflopRangeBook`, si existe
    // ancla para este par) reemplaza la mano fija `{AA,KK,AKs}` de
    // antes — ver el informe de diseño ("el rival samplea su mano de
    // PreflopRangeBook real, nunca un fijo sin relación con ningún
    // rango"). Sin ancla para el par, cae al fijo de siempre: ningún
    // comportamiento nuevo para combinaciones no cubiertas todavía.
    final threeBettorAnchor =
        PreflopRangeBook.anchorFor(threeBettorPosition, heroPosition);
    final threeBettorRange = threeBettorAnchor?.threeBetValueRange
        .merge(threeBettorAnchor.threeBetBluffRange);
    final threeBettorHand = threeBettorRange?.sample(deck) ?? _fixedPremiumHand(deck);

    var state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: buttonSlot,
      stackBb: stackBb,
      explicitHandBySlot: {heroSlot: hand, threeBettorSlot: threeBettorHand},
    );
    state = _resolveBackgroundActors(state, heroSlot, opponentProfile);
    state = ActionResolver.apply(
        state, PokerAction.raiseTo(OpeningRanges.sizingFor(heroPosition)));
    state = _resolveBackgroundActors(state, threeBettorSlot, opponentProfile);
    // Con ancla real, la mano ya se sampleó DE ese rango — el 3-bet es
    // mecánico (garantizado por construcción), nunca vuelve a pasar por
    // `OpponentPolicy` (que decidiría con sus propios umbrales de
    // percentil, potencialmente en desacuerdo con el rango que se
    // acaba de usar para elegir la mano). Sin ancla, sigue exactamente
    // como antes.
    state = threeBettorRange != null
        ? ActionResolver.apply(state, _threeBetSizeAction(state, heroPosition))
        : ActionResolver.apply(state, OpponentPolicy.decide(state, profile: opponentProfile));
    state = _resolveBackgroundActors(state, heroSlot, opponentProfile);

    return _finish(state, heroSlot, PreflopScenarioKind.facingThreeBet, _facingRaiseConcepts,
        metadata: {
          'threeBettorSlot': threeBettorSlot,
          'threeBettorPosition': threeBettorPosition.abbreviation,
        });
  }

  /// 3x la apertura del héroe, clampeado a lo legal — mismo cálculo que
  /// ya usan `PreflopStrategy`/`DefenseVsOpenStrategy` para sugerir un
  /// tamaño de 3-bet, reutilizado acá para el 3-bet mecánico del rival.
  static PokerAction _threeBetSizeAction(GameState state, Position heroPosition) {
    final desired = OpeningRanges.sizingFor(heroPosition) * 3;
    final min = LegalActionEngine.minRaiseToBb(state);
    final max = LegalActionEngine.maxRaiseToBb(state);
    final clamped = desired < min ? min : (desired > max ? max : desired);
    return PokerAction.raiseTo(clamped);
  }

  /// Tipo F — postflop: el héroe fue el agresor preflop y decide si
  /// c-apuesta en un flop que favorece a su rango
  /// ([PostflopStrategy.boardFavorsAggressor]), antes de cualquier
  /// apuesta en esta calle. Primera familia postflop del Laboratorio —
  /// ver `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md` para la
  /// justificación y el alcance deliberado.
  ///
  /// **Sin `opponentProfile`**: a diferencia de las 5 familias
  /// anteriores, acá nadie con parte en la decisión pedagógica consulta
  /// [OpponentPolicy]. El villano paga preflop y checkea el flop **de
  /// guion** (acción mecánica, no evaluada — mismo criterio que ya usa
  /// [facingThreeBet] para la subida del héroe): esta familia no
  /// necesita, y deliberadamente no modela, ninguna frecuencia de
  /// fold/call/raise postflop del rival — ver el punto 4 del informe de
  /// diseño sobre por qué inventar esa frecuencia sin fuente estaría
  /// prohibido.
  static ExerciseScenario cbetDecision({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.btn,
    Position villainPosition = Position.bb,
    HoleCards? heroHand,
    double stackBb = 100,
    HandBias heroHandBias = HandBias.any,
  }) {
    if (heroPosition == villainPosition) {
      throw ArgumentError('heroPosition y villainPosition no pueden ser la misma.');
    }
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final villainSlot = TablePositions(buttonSlot).slotOf(villainPosition);
    _requireActsBefore(buttonSlot, villainSlot, heroSlot,
        'cbetDecision: heroPosition ($heroPosition) tiene que tener posición '
        'sobre villainPosition ($villainPosition) postflop.',
        street: Street.flop);

    final hand = heroHand ?? HandPicker.forBias(deck, heroPosition, heroHandBias);
    // La mano del villano no importa para esta familia: su única acción
    // (pagar preflop) está guionada más abajo, nunca decidida por
    // fuerza de mano — cualquier mano sirve.
    final villainHand = HandPicker.forBias(deck, villainPosition, HandBias.any);

    var state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: buttonSlot,
      stackBb: stackBb,
      explicitHandBySlot: {heroSlot: hand, villainSlot: villainHand},
    );
    state = _resolveBackgroundActors(state, heroSlot, OpponentProfile.balanced);
    state = ActionResolver.apply(
        state, PokerAction.raiseTo(OpeningRanges.sizingFor(heroPosition)));
    state = _resolveBackgroundActors(state, villainSlot, OpponentProfile.balanced);
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));
    // `heroPosition`/`villainPosition` variados (ver `ScenarioRandomizer.
    // aggressorWithPositionPositions`) ya no garantizan que villainSlot
    // sea el último en actuar preflop — puede quedar gente "de fondo"
    // (p. ej. la BB) por detrás si villainPosition es la SB.
    state = _foldRemainingBackgroundActors(state);

    if (!state.isStreetComplete) {
      throw StateError(
          'cbetDecision: la calle preflop no cerró donde se esperaba.');
    }
    state = _withFavorableFlop(state);
    state = ActionResolver.advanceStreet(state);
    // El villano checkea de guion (ver el doc-comment de este método) —
    // nunca vía OpponentPolicy.
    state = ActionResolver.apply(state, const PokerAction(ActionType.check));

    return _finish(
        state, heroSlot, PreflopScenarioKind.cbetDecision, _cbetDecisionConcepts,
        metadata: {'villainSlot': villainSlot, 'villainPosition': villainPosition.abbreviation});
  }

  static const List<String> _cbetDecisionConcepts = [
    ConceptIds.cbet,
    ConceptIds.boardTexture,
  ];

  /// Tipo G — postflop: el héroe defendió preflop (no fue el agresor),
  /// pagó un flop chico de guion (mecánico, sin evaluar — el punto
  /// pedagógico es la calle siguiente, no esta) y en el turn encara una
  /// apuesta real del agresor, con posición sobre él/ella. El héroe
  /// decide fold/call/raise fundamentado en equity real
  /// (`PostflopStrategy`, ver su doc-comment).
  ///
  /// **Por qué el turn y no el flop**: `EquityEngine.handVsRange` en el
  /// flop (2 cartas por venir) enumera del orden de mil runouts POR
  /// combo del rango del agresor — con un rango de apertura real
  /// (decenas a cientos de combos) eso tarda varios segundos por
  /// ejercicio, inviable para una decisión en vivo. En el turn (1 carta
  /// por venir) son ~46 runouts por combo — el mismo cálculo real, sin
  /// aproximar nada, pero órdenes de magnitud más rápido. La apuesta que
  /// el héroe encara en el flop es de guion precisamente para poder
  /// llegar a esa calle más barata sin inventar una heurística nueva.
  static ExerciseScenario facingCbet({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.btn,
    Position aggressorPosition = Position.co,
    HoleCards? heroHand,
    double stackBb = 100,
    double flopBetPotFraction = 0.5,
    double turnBetPotFraction = 0.66,
  }) {
    if (heroPosition == aggressorPosition) {
      throw ArgumentError('heroPosition y aggressorPosition no pueden ser la misma.');
    }
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final aggressorSlot = TablePositions(buttonSlot).slotOf(aggressorPosition);
    _requireActsBefore(buttonSlot, aggressorSlot, heroSlot,
        'facingCbet: heroPosition ($heroPosition) tiene que tener posición '
        'sobre aggressorPosition ($aggressorPosition) postflop.',
        street: Street.flop);

    // Sin sesgo de mano: la lección acá es leer equity real contra el
    // board, no "reconocer una mano típica de apertura" — cualquier
    // mano que el héroe hubiera defendido sirve (ver `_biasAppliesTo` en
    // `LabSessionController`, que excluye esta familia del sesgo de
    // dificultad por el mismo motivo).
    final hand = heroHand ?? HandPicker.forBias(deck, heroPosition, HandBias.any);
    final aggressorHand =
        HandPicker.forBias(deck, aggressorPosition, HandBias.clearlyInRange);

    var state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: buttonSlot,
      stackBb: stackBb,
      explicitHandBySlot: {heroSlot: hand, aggressorSlot: aggressorHand},
    );
    state = _resolveBackgroundActors(state, aggressorSlot, OpponentProfile.balanced);
    state = ActionResolver.apply(
        state, PokerAction.raiseTo(OpeningRanges.sizingFor(aggressorPosition)));
    state = _resolveBackgroundActors(state, heroSlot, OpponentProfile.balanced);
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));
    // heroPosition puede no ser el último en actuar preflop (ver
    // `ScenarioRandomizer.facingCbetPositions`).
    state = _foldRemainingBackgroundActors(state);

    if (!state.isStreetComplete) {
      throw StateError('facingCbet: la calle preflop no cerró donde se esperaba.');
    }
    state = ActionResolver.advanceStreet(state);
    // Flop de guion (mecánico, nunca evaluado): board real, sin forzar
    // textura — la variedad de texturas es parte del punto, y la única
    // decisión real de esta familia es la del turn (ver el doc-comment).
    state = _resolveBackgroundActors(state, aggressorSlot, OpponentProfile.balanced);
    final flopBetSizeBb =
        BetSizingEngine.potSizedBet(state.pot.totalBb, fraction: flopBetPotFraction);
    state = ActionResolver.apply(state, PokerAction.bet(flopBetSizeBb));
    state = _resolveBackgroundActors(state, heroSlot, OpponentProfile.balanced);
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));

    if (!state.isStreetComplete) {
      throw StateError('facingCbet: el flop no cerró donde se esperaba.');
    }
    state = ActionResolver.advanceStreet(state);
    // El turn sí es la decisión real: el agresor apuesta de guion, el
    // héroe decide.
    state = _resolveBackgroundActors(state, aggressorSlot, OpponentProfile.balanced);
    final turnBetSizeBb =
        BetSizingEngine.potSizedBet(state.pot.totalBb, fraction: turnBetPotFraction);
    state = ActionResolver.apply(state, PokerAction.bet(turnBetSizeBb));
    state = _resolveBackgroundActors(state, heroSlot, OpponentProfile.balanced);

    return _finish(state, heroSlot, PreflopScenarioKind.facingCbet, _facingCbetConcepts,
        metadata: {
          'aggressorSlot': aggressorSlot,
          'aggressorPosition': aggressorPosition.abbreviation,
        });
  }

  static const List<String> _facingCbetConcepts = [
    ConceptIds.potOdds,
    ConceptIds.equity,
    ConceptIds.call,
  ];

  /// Tipo H — postflop: el héroe fue el agresor preflop, c-apostó el
  /// flop (de guion — la calidad de ESE bet ya la cubre [cbetDecision]
  /// por separado) y el rival pagó (de guion); en el turn, el rival
  /// checkea y el héroe decide el segundo barril (seguir apostando) o
  /// pasar a controlar el bote. Fundamentado en la misma equity real que
  /// [facingCbet].
  static ExerciseScenario turnBarrel({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.btn,
    Position villainPosition = Position.bb,
    HoleCards? heroHand,
    double stackBb = 100,
    double flopBetPotFraction = 0.5,
  }) {
    var state = _startBarrelLine(
      deck: deck,
      buttonSlot: buttonSlot,
      heroPosition: heroPosition,
      villainPosition: villainPosition,
      heroHand: heroHand,
      stackBb: stackBb,
      flopBetPotFraction: flopBetPotFraction,
    );
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final villainSlot = TablePositions(buttonSlot).slotOf(villainPosition);

    return _finish(state, heroSlot, PreflopScenarioKind.turnBarrel, _barrelConcepts,
        metadata: {'villainSlot': villainSlot, 'villainPosition': villainPosition.abbreviation});
  }

  /// Tipo I — postflop: misma decisión que [turnBarrel] un paso más
  /// adelante — flop Y turn ya fueron apuesta más pago (de guion), y en
  /// el río el rival vuelve a checkear. El héroe decide el tercer
  /// barril de valor o pasar a showdown.
  static ExerciseScenario riverBarrel({
    required Deck deck,
    int buttonSlot = 0,
    Position heroPosition = Position.btn,
    Position villainPosition = Position.bb,
    HoleCards? heroHand,
    double stackBb = 100,
    double flopBetPotFraction = 0.5,
    double turnBetPotFraction = 0.66,
  }) {
    var state = _startBarrelLine(
      deck: deck,
      buttonSlot: buttonSlot,
      heroPosition: heroPosition,
      villainPosition: villainPosition,
      heroHand: heroHand,
      stackBb: stackBb,
      flopBetPotFraction: flopBetPotFraction,
    );
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final villainSlot = TablePositions(buttonSlot).slotOf(villainPosition);

    // `_startBarrelLine` deja al héroe recién en su decisión de turn (el
    // rival ya checkeó). Acá esa decisión también es de guion (siempre
    // apuesta), porque el punto pedagógico de esta familia es el río, no
    // el turn (ese ya lo cubre `turnBarrel` por separado).
    final turnBetSizeBb =
        BetSizingEngine.potSizedBet(state.pot.totalBb, fraction: turnBetPotFraction);
    // Solo héroe y rival siguen activos (ver `_startBarrelLine`) — se
    // aplica en orden, sin `_resolveBackgroundActors`.
    state = ActionResolver.apply(state, PokerAction.bet(turnBetSizeBb));
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));

    if (!state.isStreetComplete) {
      throw StateError('riverBarrel: el turn no cerró donde se esperaba.');
    }
    state = ActionResolver.advanceStreet(state);
    state = ActionResolver.apply(state, const PokerAction(ActionType.check));

    return _finish(state, heroSlot, PreflopScenarioKind.riverBarrel, _barrelConcepts,
        metadata: {'villainSlot': villainSlot, 'villainPosition': villainPosition.abbreviation});
  }

  static const List<String> _barrelConcepts = [
    ConceptIds.valueBet,
    ConceptIds.equity,
    ConceptIds.ev,
  ];

  /// Arma preflop (héroe abre, rival paga, de guion) + flop (héroe
  /// c-apuesta, rival paga, de guion) hasta dejar al rival recién
  /// checkeando el turn — el tramo mecánico compartido por [turnBarrel]
  /// y [riverBarrel], que solo difieren en qué pasa DESPUÉS de ese
  /// check. Nunca decide la calidad de ninguna de estas acciones (todas
  /// son de guion); la única decisión real que arma es la del turn (que
  /// [turnBarrel] deja tal cual, y [riverBarrel] resuelve mecánicamente
  /// para seguir una calle más).
  static GameState _startBarrelLine({
    required Deck deck,
    required int buttonSlot,
    required Position heroPosition,
    required Position villainPosition,
    required HoleCards? heroHand,
    required double stackBb,
    required double flopBetPotFraction,
  }) {
    if (heroPosition == villainPosition) {
      throw ArgumentError('heroPosition y villainPosition no pueden ser la misma.');
    }
    final heroSlot = TablePositions(buttonSlot).slotOf(heroPosition);
    final villainSlot = TablePositions(buttonSlot).slotOf(villainPosition);
    _requireActsBefore(buttonSlot, villainSlot, heroSlot,
        'turnBarrel/riverBarrel: heroPosition ($heroPosition) tiene que '
        'tener posición sobre villainPosition ($villainPosition) postflop.',
        street: Street.flop);

    final hand = heroHand ?? HandPicker.forBias(deck, heroPosition, HandBias.any);
    final villainHand = HandPicker.forBias(deck, villainPosition, HandBias.any);

    var state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: buttonSlot,
      stackBb: stackBb,
      explicitHandBySlot: {heroSlot: hand, villainSlot: villainHand},
    );
    state = _resolveBackgroundActors(state, heroSlot, OpponentProfile.balanced);
    state = ActionResolver.apply(
        state, PokerAction.raiseTo(OpeningRanges.sizingFor(heroPosition)));
    state = _resolveBackgroundActors(state, villainSlot, OpponentProfile.balanced);
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));
    // heroPosition puede no ser el último en actuar preflop (ver
    // `ScenarioRandomizer.aggressorWithPositionPositions`).
    state = _foldRemainingBackgroundActors(state);

    if (!state.isStreetComplete) {
      throw StateError('turnBarrel/riverBarrel: la calle preflop no cerró donde se esperaba.');
    }
    state = ActionResolver.advanceStreet(state);
    // A partir de acá solo quedan héroe y rival activos (todo el resto
    // se foldeó en preflop) — el rival actúa primero en cada calle
    // (`_requireActsBefore` ya lo garantiza), así que alcanza con
    // aplicar las acciones en orden, sin `_resolveBackgroundActors`:
    // ya no queda nadie de fondo que resolver.
    state = ActionResolver.apply(state, const PokerAction(ActionType.check));
    final flopBetSizeBb =
        BetSizingEngine.potSizedBet(state.pot.totalBb, fraction: flopBetPotFraction);
    state = ActionResolver.apply(state, PokerAction.bet(flopBetSizeBb));
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));

    if (!state.isStreetComplete) {
      throw StateError('turnBarrel/riverBarrel: el flop no cerró donde se esperaba.');
    }
    state = ActionResolver.advanceStreet(state);
    state = ActionResolver.apply(state, const PokerAction(ActionType.check));
    return state;
  }

  /// Reordena `state.remainingDeckCards` para que las próximas 3 cartas
  /// (las que [ActionResolver.advanceStreet] va a repartir como flop)
  /// formen un board que favorece al agresor preflop
  /// ([PostflopStrategy.boardFavorsAggressor]) — nunca inventa cartas
  /// nuevas ni cambia cuáles cartas puede tocar el resto de la mano,
  /// solo el ORDEN en el que salen de un mazo ya barajado. Determinista:
  /// recorre `remainingDeckCards` en su propio orden (ya sale del
  /// `Random` sembrado del `Deck`) y arma el primer board válido que
  /// encuentra — nunca vuelve a tocar un `Random` nuevo.
  static GameState _withFavorableFlop(GameState state) {
    final pool = state.remainingDeckCards;
    final highIndex =
        pool.indexWhere((c) => c.rank == Rank.ace || c.rank == Rank.king);
    if (highIndex == -1) {
      throw TemplateGenerationException(
          'cbetDecision: no queda ningún As ni Rey en el mazo restante '
          'para armar un flop que favorezca al agresor.');
    }
    final high = pool[highIndex];
    final flop = <Card>[high];
    final usedSuits = {high.suit};
    final usedRanks = {high.rank};
    for (final c in pool) {
      if (flop.length == 3) break;
      if (c == high) continue;
      if (usedSuits.contains(c.suit) || usedRanks.contains(c.rank)) continue;
      flop.add(c);
      usedSuits.add(c.suit);
      usedRanks.add(c.rank);
    }
    if (flop.length != 3) {
      throw TemplateGenerationException(
          'cbetDecision: no se pudo armar un flop rainbow y sin parejas '
          'con el mazo restante.');
    }
    final rest = [for (final c in pool) if (!flop.contains(c)) c];
    return state.copyWith(remainingDeckCards: [...flop, ...rest]);
  }

  /// Avanza el estado foldeando a cualquier jugador "de fondo" (sin mano
  /// conocida) y haciendo decidir de verdad, vía [OpponentPolicy] con
  /// [profile], a cualquiera que sí la tenga — hasta que le toque a
  /// [targetSlot].
  static GameState _resolveBackgroundActors(
      GameState state, int targetSlot, OpponentProfile profile) {
    while (state.toActSlot != null && state.toActSlot != targetSlot) {
      final actor = state.toActSlot!;
      final hasKnownHand = state.seatAt(actor).holeCards != null;
      state = ActionResolver.apply(
        state,
        hasKnownHand
            ? OpponentPolicy.decide(state, profile: profile)
            : const PokerAction(ActionType.fold),
      );
    }
    if (state.toActSlot != targetSlot) {
      throw StateError(
          'ExerciseScenarioBuilder: la mano terminó antes de llegar al '
          'slot $targetSlot.');
    }
    return state;
  }

  /// Foldea a cualquier jugador "de fondo" (sin mano conocida) que
  /// todavía tenga que actuar DESPUÉS del último actor real de la calle
  /// — necesario cuando ese actor real no es, por posición, el último en
  /// la rotación (p. ej. el héroe/rival de una familia postflop cae en
  /// una posición intermedia, no en la BB): sin esto, `isStreetComplete`
  /// queda en `false` porque a esos asientos de fondo nunca les tocó
  /// actuar, aunque su mano ya esté decidida de antemano (no van a hacer
  /// más que retirarse, no tienen mano real que jugar). Lanza
  /// [StateError] si el próximo en turno resulta tener una mano
  /// conocida — eso significaría un actor real sin guionar, un error de
  /// construcción del escenario, nunca algo que este helper deba
  /// silenciar foldeándolo igual.
  static GameState _foldRemainingBackgroundActors(GameState state) {
    while (!state.isStreetComplete && state.toActSlot != null) {
      final actor = state.toActSlot!;
      if (state.seatAt(actor).holeCards != null) {
        throw StateError(
            'ExerciseScenarioBuilder: el slot $actor tiene una mano conocida '
            'y todavía no actuó — no debería quedar ningún actor real acá.');
      }
      state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
    }
    return state;
  }

  static void _requireActsBefore(
      int buttonSlot, int firstSlot, int secondSlot, String message,
      {Street street = Street.preflop}) {
    final order = TablePositions(buttonSlot).order(street);
    if (order.indexOf(firstSlot) >= order.indexOf(secondSlot)) {
      throw ArgumentError(message);
    }
  }

  static HoleCards _fixedPremiumHand(Deck deck) {
    final notation = deck.pick(const ['AA', 'KK', 'AKs']);
    final hand = deck.dealHandOfClass(notation);
    if (hand == null) {
      throw TemplateGenerationException(
          'ExerciseScenarioBuilder: no quedan combos de $notation en el mazo '
          'para garantizar un 3-bet.');
    }
    return hand;
  }

  static ExerciseScenario _finish(
    GameState state,
    int heroSlot,
    PreflopScenarioKind kind,
    List<String> concepts, {
    Map<String, Object?> metadata = const {},
  }) {
    final context = DecisionContext.fromGameState(state, heroSlot: heroSlot);
    return ExerciseScenario(
      initialState: state,
      heroSlot: heroSlot,
      decisionContext: context,
      objective: kind,
      evaluableConcepts: concepts,
      metadata: metadata,
    );
  }
}

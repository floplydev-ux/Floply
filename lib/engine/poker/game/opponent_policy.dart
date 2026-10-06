import 'dart:math';

import '../evaluator/hand_strength_tier.dart';
import '../hole_cards.dart';
import '../poker_action.dart';
import '../position.dart';
import '../sizing/bet_sizing_engine.dart';
import '../street.dart';
import '../../strategy/hand_strength.dart';
import '../../strategy/opening_ranges.dart';
import '../../strategy/preflop_range_book.dart';
import 'game_state.dart';
import 'legal_action_engine.dart';
import 'player_state.dart';

/// Los umbrales que gobiernan `_decidePreflop` — extraídos a un value
/// type (Fase 8.7) para que `OpponentPolicy` pueda recibir un perfil
/// distinto sin reescribir el motor. La legalidad nunca depende del
/// perfil: `_resolveLegal` degrada cualquier acción "ideal" a la
/// alternativa legal más parecida para los 4 perfiles por igual — un
/// perfil nuevo nunca necesita su propia lógica de legalidad.
///
/// Nombres de campo corregidos en Fase 10 (antes `foldPercentile`/
/// `threeBetPercentile`, invertidos respecto de lo que realmente
/// controlan): [threeBetPercentile] es el umbral para re-subir
/// enfrentando una subida, [callPercentile] el umbral para pagarla.
class OpponentProfile {
  const OpponentProfile({
    required this.name,
    required this.openFrequency,
    required this.threeBetPercentile,
    required this.callPercentile,
    required this.threeBetMultiplier,
  });

  /// Apertura basada en rangos reales (probabilística para manos mixtas),
  /// re-sube con el 6% superior de manos enfrentando una subida,
  /// paga hasta el percentil 28 en situaciones sin ancla de PreflopRangeBook
  /// (reducido de 35 para limitar la frecuencia de all-ins — pero siempre
  /// más ancho que `tag` en 0.25, preservando la jerarquía passive > balanced > tag),
  /// sube a 3x el bet actual.
  static const balanced = OpponentProfile(
    name: 'balanced',
    openFrequency: 0.5,
    threeBetPercentile: 0.06,
    callPercentile: 0.28,
    threeBetMultiplier: 3,
  );

  /// Agresión baja: abre más angosto que balanced, re-sube solo con lo
  /// más top del rango, y prefiere pagar antes que re-subir con manos
  /// intermedias (callPercentile más ancho, sizing de 3-bet más chico).
  static const passive = OpponentProfile(
    name: 'passive',
    openFrequency: 0.7,
    threeBetPercentile: 0.03,
    callPercentile: 0.45,
    threeBetMultiplier: 2.5,
  );

  /// Tight-aggressive: rango de apertura selectivo, 3-bet más selectivo
  /// todavía que balanced pero con más presión de tamaño cuando ocurre,
  /// y descarta calls marginales (callPercentile más angosto).
  static const tag = OpponentProfile(
    name: 'tag',
    openFrequency: 0.65,
    threeBetPercentile: 0.04,
    callPercentile: 0.25,
    threeBetMultiplier: 3.5,
  );

  final String name;
  final double openFrequency;
  final double threeBetPercentile;
  final double callPercentile;
  final double threeBetMultiplier;
}

/// Decide una acción concreta para el jugador en turno — reglas simples,
/// deterministas, sin solver ni Monte Carlo.
///
/// **Preflop**: piezas reales para fundamentar la decisión
/// ([OpeningRanges], [HandStrength], [PreflopRangeBook] cuando hay
/// ancla).
///
/// **Postflop** (Mesa con Coach, Grupo 8): [HandStrengthClassifier]
/// evalúa la mano hecha real contra el board (categoría + proyectos) —
/// nunca equity exacta contra un rango: con hasta 5 bots decidiendo en
/// cada calle de cada mano, `EquityEngine.handVsRange` (enumeración
/// exacta, cara con rangos anchos en el flop — ver el hallazgo de
/// rendimiento de `postflop_strategy.dart`) sería impracticable acá. Ver
/// el doc-comment de [HandStrengthClassifier] para el detalle completo
/// de esta simplificación deliberada, documentada, no un descuido.
///
/// No reutiliza `StrategyEngine` (esa clase arma una `Strategy` graduada
/// con texto de justificación para dar feedback a un humano); usa
/// directamente las mismas piezas de más bajo nivel que `StrategyEngine`
/// ya usa internamente.
class OpponentPolicy {
  const OpponentPolicy._();

  // Una sola instancia compartida: las decisiones de bots no necesitan
  // semilla reproducible (la reproducibilidad está en HandTableController
  // vía su propio Random inyectable, que controla el mazo y los stacks).
  static final Random _random = Random();

  /// Decide la acción del jugador en turno.
  ///
  /// Lanza [StateError] si no hay nadie en turno o si no se conoce su
  /// mano (`holeCards == null` — no hay con qué decidir).
  static PokerAction decide(GameState state,
      {OpponentProfile profile = OpponentProfile.balanced}) {
    final slot = state.toActSlot;
    if (slot == null) {
      throw StateError('OpponentPolicy: no hay jugador en turno.');
    }
    // Vista pública desde acá para abajo (ver [_publicView]): toda la
    // lógica de decisión de esta clase trabaja sobre esta copia, nunca
    // sobre [state] tal cual llegó — así ninguna rama nueva que se
    // agregue después puede terminar leyendo, ni por descuido, la mano
    // de otro asiento o el mazo restante.
    final visible = _publicView(state, slot);
    final player = visible.seatAt(slot);
    final hand = player.holeCards;
    if (hand == null) {
      throw StateError(
          'OpponentPolicy: el slot $slot no tiene una mano conocida '
          '(holeCards null) — no se puede decidir sin saber qué mano '
          'tiene.');
    }
    if (visible.street != Street.preflop) {
      final ideal = _decidePostflop(visible, player, hand);
      return _resolveLegal(visible, ideal);
    }

    final position = visible.positionOf(slot);
    final ideal = _decidePreflop(visible, position, hand, profile);
    return _resolveLegal(visible, ideal);
  }

  /// Lo único que [actingSlot] podría legítimamente conocer en una mesa
  /// real: sus propias cartas privadas, el board ya revelado (`board`
  /// ya solo tiene las cartas de la calle actual — invariante propia de
  /// `GameState`, que valida `board.length == street.boardCards` en
  /// cada construcción, así que nunca trae cartas futuras) y todo lo
  /// demás público (stacks/pot/apuestas/historial/street/posiciones).
  ///
  /// Dos cosas quedan explícitamente fuera, aunque nada de la lógica de
  /// más abajo las use hoy: las cartas privadas de CUALQUIER otro
  /// asiento (`PlayerState.copyWith(clearHoleCards: true)`, el mismo
  /// mecanismo que ya usa el motor para un rival cuya mano el héroe no
  /// ve) y [GameState.remainingDeckCards] (en orden, son exactamente las
  /// próximas cartas por repartir — la única vía real por la que
  /// "cartas futuras del board" podrían llegar a filtrarse). Es la
  /// solución arquitectónica que pide la auditoría de información
  /// oculta: un límite estructural antes de decidir, no un `if (bot) no
  /// mires X` disperso en cada regla.
  static GameState _publicView(GameState state, int actingSlot) {
    return state.copyWith(
      seats: [
        for (final s in state.seats)
          s.slot == actingSlot ? s : s.copyWith(clearHoleCards: true),
      ],
      remainingDeckCards: const [],
    );
  }

  /// Nadie subió más allá de la ciega grande todavía (incluye tanto
  /// "primero en entrar" como entrar sobre limpers — esta política no
  /// distingue abrir de aislar limpers, simplificación documentada) vs.
  /// ya hay una subida sobre la mesa.
  static PokerAction _decidePreflop(
      GameState state, Position position, HoleCards hand, OpponentProfile profile) {
    final facingRaise = state.round.currentBetBb > state.bigBlindBb;

    if (!facingRaise) {
      if (position == Position.bb) {
        return const PokerAction(ActionType.check);
      }
      final range = OpeningRanges.forPosition(position);
      final freq = range.frequencyOfHand(hand);
      // La mano califica solo si supera el umbral de apertura del perfil
      // (passive=0.7 / tag=0.65 nunca abren manos mixtas con freq=0.5).
      // Para las que califican y son mixtas (freq < 1.0), se samplea con
      // probabilidad = freq en vez de abrirlas siempre (balanced abre las
      // mixtas ~50% de las veces, comportamiento GTO correcto).
      // openFrequency=0 es caso especial: abre cualquier mano sin filtro
      // de rango (solo usado en perfiles de prueba).
      final willOpen = freq >= profile.openFrequency &&
          (profile.openFrequency <= 0.0 ||
           freq >= 1.0 ||
           _random.nextDouble() < freq);
      if (willOpen) {
        return _clampedRaise(state, OpeningRanges.sizingFor(position));
      }
      return const PokerAction(ActionType.fold);
    }

    // Si existe una tabla real de `PreflopRangeBook` para esta situación
    // exacta, la usa en vez del percentil — así el rival simulado nunca
    // decide con un criterio distinto del que evalúa al alumno para la
    // misma situación (`DefenseVsOpenStrategy`/`FacingThreeBetStrategy`/
    // `ShortStackStrategy`, todos en `lib/engine/exercises/`). Solo para
    // `balanced`: es el único perfil con tabla de referencia propia hoy
    // (ver el riesgo ya documentado en la memoria del proyecto,
    // `laboratorio-motor-preflop` — passive/tag siguen con el percentil
    // de siempre, no se les fuerza la tabla de otro perfil). Sin ancla
    // real para la situación, cae al percentil de siempre.
    if (profile == OpponentProfile.balanced) {
      final fromRangeBook = _decideFromRangeBook(state, position, hand);
      if (fromRangeBook != null) return fromRangeBook;
    }

    // Enfrentando una subida: reglas simples de referencia por percentil
    // (0 = la mejor mano de las 169), sin ajuste por pot odds todavía —
    // simplificación documentada, no un olvido.
    final percentile = HandStrength.percentile(hand.notation);
    if (percentile <= profile.threeBetPercentile) {
      return _clampedRaise(state, state.round.currentBetBb * profile.threeBetMultiplier);
    }
    if (percentile <= profile.callPercentile) {
      return const PokerAction(ActionType.call);
    }
    return const PokerAction(ActionType.fold);
  }

  /// `null` si no hay ninguna ancla real de [PreflopRangeBook] para la
  /// situación exacta (par de posiciones, si el actor ya fue agresor
  /// esta calle, profundidad de stack) — el caller cae de vuelta al
  /// percentil. Misma clasificación en 3 pasos que ya usa
  /// `PreflopStrategy.forDecision` (encarar un 3-bet propio > stack
  /// corto > encarar una apertura ajena), para que el rival simulado y
  /// el evaluador del alumno nunca puedan divergir en la misma
  /// situación.
  static PokerAction? _decideFromRangeBook(
      GameState state, Position position, HoleCards hand) {
    final slot = state.toActSlot!;
    final villainSlot = state.round.lastAggressorSlot;
    if (villainSlot == null) return null;
    final villainPosition = state.positionOf(villainSlot);
    final notation = hand.notation;

    final alreadyRaised = state.round.log
        .any((e) => e.slot == slot && e.action.type.isAggressive);
    if (alreadyRaised) {
      final anchor = PreflopRangeBook.facingThreeBetAnchorFor(position, villainPosition);
      if (anchor == null) return null;
      if (anchor.fourBetValueRange.contains(notation)) {
        return _clampedRaise(state, state.round.currentBetBb * 2.2);
      }
      if (anchor.callRange.contains(notation)) return const PokerAction(ActionType.call);
      return const PokerAction(ActionType.fold);
    }

    final actor = state.seatAt(slot);
    final startingStackBb = actor.stackBb + actor.investedTotalBb;
    if (startingStackBb < 20) {
      final anchor = PreflopRangeBook.shortStackAnchorFor(position, villainPosition);
      if (anchor == null) return null;
      if (anchor.shoveRange.contains(notation)) {
        return _clampedRaise(state, LegalActionEngine.maxRaiseToBb(state));
      }
      return const PokerAction(ActionType.fold);
    }

    final anchor = PreflopRangeBook.anchorFor(position, villainPosition);
    if (anchor == null) return null;
    if (anchor.threeBetValueRange.contains(notation)) {
      return _clampedRaise(state, state.round.currentBetBb * 3);
    }
    if (anchor.threeBetBluffRange.contains(notation) || anchor.callRange.contains(notation)) {
      return const PokerAction(ActionType.call);
    }
    return const PokerAction(ActionType.fold);
  }

  static PokerAction _clampedRaise(GameState state, double desired) {
    final min = LegalActionEngine.minRaiseToBb(state);
    final max = LegalActionEngine.maxRaiseToBb(state);
    final clamped = desired < min ? min : (desired > max ? max : desired);
    return PokerAction.raiseTo(clamped);
  }

  /// Piso aproximado de equity por banda de [HandStrengthTier] — NO un
  /// cálculo real (ver el doc-comment de la clase sobre por qué
  /// `EquityEngine` está descartado acá por rendimiento). Números
  /// redondos y conservadores, documentados como tales: alcanzan para
  /// decidir fold/call/raise de forma razonable sin pretender precisión
  /// de solver.
  ///
  /// Público (no `_approxEquity`) para que `CoachAnalyzer` clasifique la
  /// calidad de una decisión postflop con el MISMO número que usa el bot
  /// para decidir la suya — nunca un segundo criterio de equity
  /// aproximada inventado aparte para el Coach.
  static double approxEquity(HandStrengthReading reading) => switch (reading.tier) {
        HandStrengthTier.strong => 0.80,
        HandStrengthTier.decent => 0.55,
        HandStrengthTier.weakOrDrawing => reading.hasAnyDraw ? 0.35 : 0.25,
        HandStrengthTier.air => 0.12,
      };

  /// Decisión postflop del jugador en turno — ver el doc-comment de la
  /// clase para el fundamento (categoría real de mano + proyectos,
  /// nunca equity exacta contra un rango).
  static PokerAction _decidePostflop(
      GameState state, PlayerState player, HoleCards hand) {
    final reading = HandStrengthClassifier.classify(hand, state.board);
    final potBb = state.pot.totalBb;
    final facingBet = state.round.currentBetBb > player.investedThisStreetBb;

    if (!facingBet) {
      // Nadie apostó todavía esta calle: decide entre pasar o apostar
      // (valor con manos decentes+, semi-farol con un proyecto sin nada
      // hecho todavía).
      final betsForValue = reading.tier.isAtLeastDecent ||
          (reading.tier == HandStrengthTier.weakOrDrawing && reading.hasAnyDraw);
      if (!betsForValue) return const PokerAction(ActionType.check);
      final desired = BetSizingEngine.potSizedBet(potBb, fraction: 0.66);
      final min = LegalActionEngine.minRaiseToBb(state);
      final max = LegalActionEngine.maxRaiseToBb(state);
      final clamped = desired < min ? min : (desired > max ? max : desired);
      return PokerAction.bet(clamped);
    }

    // Encara una apuesta real: compara el piso de equity aproximado
    // contra las pot odds reales (esto sí es aritmética exacta, no una
    // aproximación — ver `toCallBb`/`requiredEquity`).
    final toCallBb = state.round.currentBetBb - player.investedThisStreetBb;
    final requiredEquity = toCallBb / (potBb + toCallBb);
    final approxEquityValue = approxEquity(reading);

    if (reading.tier == HandStrengthTier.strong &&
        approxEquityValue - requiredEquity > 0.2) {
      return _clampedRaise(state, state.round.currentBetBb * 2.5);
    }
    if (approxEquityValue >= requiredEquity) {
      return const PokerAction(ActionType.call);
    }
    return const PokerAction(ActionType.fold);
  }

  /// Si la acción "ideal" no es legal en este estado (típicamente: stack
  /// corto), degrada a la alternativa legal más parecida en intención —
  /// nunca deja pasar una [PokerAction] que `ActionResolver` fuera a
  /// rechazar.
  static PokerAction _resolveLegal(GameState state, PokerAction ideal) {
    final legal = LegalActionEngine.legalActionTypes(state);
    if (legal.isEmpty) {
      throw StateError(
          'OpponentPolicy: no hay acciones legales (¿la mano ya terminó '
          'o la calle está cerrada?).');
    }
    if (legal.contains(ideal.type)) return ideal;

    final wantedAggressive =
        ideal.type == ActionType.raise || ideal.type == ActionType.bet;
    if (wantedAggressive && legal.contains(ActionType.allIn)) {
      return const PokerAction(ActionType.allIn);
    }
    if (wantedAggressive && legal.contains(ActionType.call)) {
      return const PokerAction(ActionType.call);
    }
    if (legal.contains(ActionType.check)) return const PokerAction(ActionType.check);
    if (legal.contains(ActionType.call)) return const PokerAction(ActionType.call);
    if (legal.contains(ActionType.fold)) return const PokerAction(ActionType.fold);
    return PokerAction(legal.first);
  }
}

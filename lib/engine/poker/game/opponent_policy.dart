import '../hole_cards.dart';
import '../poker_action.dart';
import '../position.dart';
import '../street.dart';
import '../../strategy/hand_strength.dart';
import '../../strategy/opening_ranges.dart';
import '../../strategy/preflop_range_book.dart';
import 'game_state.dart';
import 'legal_action_engine.dart';

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

  /// Comportamiento original (Fase 4), sin cambios: abre con freq >=
  /// 0.5, re-sube con el 6% superior de manos enfrentando una subida,
  /// paga hasta el percentil 35, sube a 3x el bet actual.
  static const balanced = OpponentProfile(
    name: 'balanced',
    openFrequency: 0.5,
    threeBetPercentile: 0.06,
    callPercentile: 0.35,
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
/// **Alcance: solo preflop.** El motor tiene piezas reales para
/// fundamentar una decisión preflop ([OpeningRanges], [HandStrength]),
/// pero nada equivalente para postflop — juzgar una mano contra un board
/// concreto necesita un evaluador de manos hechas, y eso es exactamente
/// lo que el pedido viene excluyendo como "showdown evaluator" en fases
/// anteriores. `decide` lanza [UnsupportedError] en vez de improvisar una
/// regla postflop sin fundamento.
///
/// No reutiliza `StrategyEngine` (esa clase arma una `Strategy` graduada
/// con texto de justificación para dar feedback a un humano); usa
/// directamente las mismas piezas de más bajo nivel que `StrategyEngine`
/// ya usa internamente.
class OpponentPolicy {
  const OpponentPolicy._();

  /// Decide la acción del jugador en turno.
  ///
  /// Lanza [StateError] si no hay nadie en turno o si no se conoce su
  /// mano (`holeCards == null` — no hay con qué decidir). Lanza
  /// [UnsupportedError] si `state.street != Street.preflop`.
  static PokerAction decide(GameState state,
      {OpponentProfile profile = OpponentProfile.balanced}) {
    final slot = state.toActSlot;
    if (slot == null) {
      throw StateError('OpponentPolicy: no hay jugador en turno.');
    }
    final player = state.seatAt(slot);
    final hand = player.holeCards;
    if (hand == null) {
      throw StateError(
          'OpponentPolicy: el slot $slot no tiene una mano conocida '
          '(holeCards null) — no se puede decidir sin saber qué mano '
          'tiene.');
    }
    if (state.street != Street.preflop) {
      throw UnsupportedError(
          'OpponentPolicy: todavía no decide postflop — necesitaría '
          'comparar la mano contra el board (un evaluador de manos), '
          'fuera de alcance de esta fase. Ver el informe de Fase 4.');
    }

    final position = state.positionOf(slot);
    final ideal = _decidePreflop(state, position, hand, profile);
    return _resolveLegal(state, ideal);
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
      final freq = OpeningRanges.forPosition(position).frequencyOf(hand.notation);
      if (freq >= profile.openFrequency) {
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

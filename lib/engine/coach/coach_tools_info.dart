import '../poker/combos/combo_engine.dart';
import '../poker/evaluator/hand_strength_tier.dart';
import '../poker/ev/ev_engine.dart';
import '../poker/equity/equity_engine.dart';
import '../poker/game/game_state.dart';
import '../poker/game/opponent_policy.dart';
import '../poker/poker_action.dart';
import '../poker/pot_odds/pot_odds_engine.dart';
import '../poker/position.dart';
import '../poker/street.dart';
import '../strategy/hand_range.dart';
import '../strategy/hand_strength.dart';
import '../strategy/opening_ranges.dart';
import '../strategy/preflop_range_book.dart';
import 'coach_analyzer.dart';

/// El contenido de cada tarjeta de "Herramientas de ayuda" (evolución de
/// la Mesa Coach, sección 6): contextualizado a la mano/calle actual,
/// reutilizando los motores existentes tal cual — nunca un sistema
/// matemático paralelo. Ver el doc-comment de cada motor
/// ([PotOddsEngine]/[EVEngine]/[EquityEngine]) para los límites que ya
/// tienen documentados (p. ej. equity exacta solo desde el flop): esta
/// clase los respeta en vez de inventar un cálculo propio para tapar el
/// hueco.
///
/// Puro texto derivado de [GameState] — sin estado propio, así el panel
/// que la usa puede recalcular en cada apertura sin guardar nada aparte.
class CoachToolsInfo {
  const CoachToolsInfo._();

  static String rangeSummary(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final hand = hero.holeCards;
    if (hand == null) return _noHandYet;
    final position = state.positionOf(heroSlot);

    if (state.street == Street.preflop) {
      final range = OpeningRanges.forPosition(position);
      final freq = range.frequencyOf(hand.notation);
      final word = freq >= 0.9
          ? 'entra cómoda en tu rango de apertura habitual'
          : freq > 0
              ? 'queda en el límite de tu rango de apertura — jugable, pero '
                  'no la primera opción'
              : 'queda afuera de lo que solés abrir desde ahí';
      return 'Desde ${position.fullName} (${position.abbreviation}), tu '
          'mano ($word) para ${hand.notation}. Cuanto más tarde es tu '
          'posición, más ancho podés jugar.';
    }

    final reading = HandStrengthClassifier.classify(hand, state.board);
    return 'En ${_streetLabel(state.street)}, con el board actual, tenés '
        '${CoachAnalyzer.describeHandForDisplay(reading)}.';
  }

  static String potOddsSummary(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final toCall = state.round.currentBetBb - hero.investedThisStreetBb;
    if (toCall <= 0) {
      return 'Nadie te está pidiendo un pago ahora mismo — no hay pot '
          'odds que calcular en este momento.';
    }
    final result = PotOddsEngine.calculate(
      potBeforeCallBb: state.pot.totalBb,
      callAmountBb: toCall,
    );
    return 'Bote antes de pagar: ${_fmt(result.potBeforeCallBb)} BB. Te '
        'cuesta ${_fmt(result.callAmountBb)} BB seguir. Necesitás ganar '
        'al menos ${_pct(result.requiredEquity)} de las veces para que '
        'pagar sea rentable a largo plazo.';
  }

  static String equitySummary(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final hand = hero.holeCards;
    if (hand == null) return _noHandYet;

    if (state.street == Street.preflop) {
      final percentile = HandStrength.percentile(hand.notation);
      return 'Preflop no calculamos una equity exacta (depende del rango '
          'preciso del rival) — como referencia, tu mano está en el '
          'percentil ${_pct(percentile)} de todas las manos posibles '
          '(0% es la mejor de las 169).';
    }

    final villainPosition = _bestGuessVillain(state, heroSlot);
    final villainRange = _bestGuessVillainRange(state, heroSlot, villainPosition);
    try {
      final result = EquityEngine.handVsRange(hand, villainRange, state.board);
      return 'Contra un rango típico de ${villainPosition.abbreviation}, tu '
          'mano tiene ~${_pct(result.equity)} de equity en '
          '${_streetLabel(state.street)}.';
    } on ArgumentError {
      return 'No se pudo estimar la equity para este spot puntual — tu '
          'mano bloquea por completo el rango de referencia.';
    }
  }

  static String evSummary(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final hand = hero.holeCards;
    if (hand == null) return _noHandYet;

    if (state.street == Street.preflop) {
      return 'El EV de esta mesa está pensado para cuando ya hay una mano '
          'armada contra el board (desde el flop) — preflop, usá la '
          'tarjeta de rango de arriba.';
    }
    final toCall = state.round.currentBetBb - hero.investedThisStreetBb;
    if (toCall <= 0) {
      return 'Nadie te está pidiendo un pago ahora mismo — no hay EV de '
          'call que calcular.';
    }
    final reading = HandStrengthClassifier.classify(hand, state.board);
    final potOdds = PotOddsEngine.calculate(
      potBeforeCallBb: state.pot.totalBb,
      callAmountBb: toCall,
    );
    final ev = EVEngine.calculateCall(
      equity: OpponentPolicy.approxEquity(reading),
      finalPotBb: potOdds.finalPotBb,
      callAmountBb: potOdds.callAmountBb,
    );
    final sign = ev.evBb >= 0 ? '+' : '';
    return 'Con una equity aproximada de ${_pct(ev.equity)} para tu mano, '
        'pagar ${_fmt(toCall)} BB en este bote da un EV de '
        '$sign${_fmt(ev.evBb)} BB.';
  }

  static String spotSummary(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final position = state.positionOf(heroSlot);
    final activeCount = state.seats.where((s) => s.isActive).length;
    final entries = state.round.log
        .map((e) =>
            '${state.positionOf(e.slot).abbreviation} ${_actionWord(e.action)}')
        .join(' · ');
    final stacks = state.seats
        .where((s) => s.isActive)
        .map((s) =>
            '${state.positionOf(s.slot).abbreviation} ${_fmt(s.stackBb)}BB')
        .join(' · ');
    final sprText = hero.stackBb > 0 && state.pot.totalBb > 0
        ? ' SPR: ${_fmt(hero.stackBb / state.pot.totalBb)}.'
        : '';
    return 'Calle: ${_streetLabel(state.street)}. Tu posición: '
        '${position.fullName} (${position.abbreviation}). Bote: '
        '${_fmt(state.pot.totalBb)} BB.$sprText Jugadores activos: '
        '$activeCount de ${GameState.seatCount}. Stacks: $stacks. '
        '${entries.isEmpty ? "Nadie actuó todavía en esta calle." : "Esta calle: $entries."}';
  }

  /// Combos y bloqueadores (sección 7): cuántas combinaciones físicas le
  /// quedan al rango estimado del rival una vez que se descuentan las
  /// cartas que ya están a la vista (la mano del héroe + el board) —
  /// [ComboEngine] tal cual existe, nunca un conteo propio. Solo tiene
  /// sentido desde el flop en adelante (preflop no hay board que
  /// descontar y el rango de apertura ya se explica en la tarjeta de
  /// rango) y solo si el héroe ya tiene cartas asignadas.
  static String combosSummary(GameState state, int heroSlot) {
    final hero = state.seatAt(heroSlot);
    final hand = hero.holeCards;
    if (hand == null) return _noHandYet;
    if (state.street == Street.preflop) {
      return 'Los combos y bloqueadores se vuelven relevantes recién desde '
          'el flop, cuando ya hay board para descontar.';
    }
    final villainPosition = _bestGuessVillain(state, heroSlot);
    final villainRange = _bestGuessVillainRange(state, heroSlot, villainPosition);
    final deadCards = [...hand.cards, ...state.board];
    final withoutRemoval = ComboEngine.comboCountForRange(villainRange);
    final withRemoval =
        ComboEngine.comboCountForRange(villainRange, deadCards: deadCards);
    return 'Rango estimado de ${villainPosition.abbreviation}: '
        '$withoutRemoval combos en total. Descontando tu mano y el board, '
        'le quedan $withRemoval combos reales — tus cartas actúan como '
        'bloqueador de ${withoutRemoval - withRemoval} de ellos.';
  }

  static Position _bestGuessVillain(GameState state, int heroSlot) {
    final aggressor = state.round.lastAggressorSlot;
    if (aggressor != null && aggressor != heroSlot) {
      return state.positionOf(aggressor);
    }
    for (final s in state.seats) {
      if (s.slot != heroSlot && s.isActive) return state.positionOf(s.slot);
    }
    return state.positionOf(heroSlot);
  }

  /// El rango del rival, actualizado según lo que de verdad pasó en la
  /// mano cuando el motor lo permite: si el héroe es quien viene
  /// agrediendo esta calle (el rival solo está pagando, no abriendo), hay
  /// una tabla real más precisa que "su rango de apertura completo" —
  /// mismo mecanismo que ya usa `PostflopStrategy._villainRangeFor`
  /// (rango de DEFENSA del rival contra la apertura del héroe, nunca un
  /// segundo cálculo de rangos). Si no existe ancla para ese par exacto,
  /// o el rival es quien está agrediendo, se mantiene el proxy de
  /// siempre (su rango de apertura).
  static HandRange _bestGuessVillainRange(
      GameState state, int heroSlot, Position villainPosition) {
    final aggressor = state.round.lastAggressorSlot;
    if (aggressor == heroSlot) {
      final anchor =
          PreflopRangeBook.anchorFor(villainPosition, state.positionOf(heroSlot));
      if (anchor != null) return anchor.callRange;
    }
    return OpeningRanges.forPosition(villainPosition);
  }

  static String _actionWord(PokerAction action) => switch (action.type) {
        ActionType.fold => 'foldeó',
        ActionType.check => 'pasó',
        ActionType.call || ActionType.limp => 'pagó',
        ActionType.bet => 'apostó ${_fmt(action.sizeBb ?? 0)}',
        ActionType.raise => 'subió a ${_fmt(action.sizeBb ?? 0)}',
        ActionType.allIn => 'fue all-in',
      };

  static String _streetLabel(Street street) => switch (street) {
        Street.flop => 'el flop',
        Street.turn => 'el turn',
        Street.river => 'el río',
        Street.preflop => 'preflop',
      };

  static const String _noHandYet =
      'Todavía no tenés cartas asignadas en esta mano.';

  static String _fmt(double bb) =>
      bb == bb.roundToDouble() ? bb.toStringAsFixed(0) : bb.toStringAsFixed(1);

  static String _pct(double v) =>
      '${(v * 100).clamp(0, 100).toStringAsFixed(0)}%';
}

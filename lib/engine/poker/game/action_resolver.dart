import '../poker_action.dart';
import '../street.dart';
import '../../pedagogy/table_position.dart' show TablePositions;
import 'betting_round.dart';
import 'game_state.dart';
import 'legal_action_engine.dart';
import 'player_state.dart';
import 'pot_manager.dart';

/// Una acción no permitida por [LegalActionEngine] en el estado actual.
///
/// Reemplaza cualquier tentación de usar `assert` acá: esto puede
/// dispararse con datos que vienen de una UI o de un `OpponentPolicy`
/// futuro, no solo de tests — tiene que fallar también en release.
class IllegalActionException implements Exception {
  const IllegalActionException(this.message);
  final String message;

  @override
  String toString() => 'IllegalActionException: $message';
}

/// Aplica acciones sobre un [GameState] y avanza de calle.
///
/// Es una función pura `(GameState, PokerAction) → GameState`: no hay RNG
/// acá (ver el doc-comment de [GameState] sobre `remainingDeckCards`), así
/// que la misma secuencia de acciones sobre el mismo estado inicial da
/// siempre el mismo resultado, byte a byte.
///
/// **Reapertura de la acción tras un all-in corto**: si un all-in sube
/// `currentBetBb` pero no llega a un raise completo, quienes ya habían
/// actuado contra el nivel anterior quedan registrados en
/// `BettingRound.cannotReraiseSlots` — pueden pagar o retirarse, pero no
/// volver a subir — mientras que quienes todavía no habían actuado
/// conservan sus derechos completos. Side pots multijugador siguen fuera
/// de esta pasada (Fase 7, ya nombrada así en el plan): esta clase separa
/// correctamente call / short all-in / full raise, pero el bote sigue
/// siendo uno solo (ver [PotManager]).
class ActionResolver {
  const ActionResolver._();

  /// Aplica [action] tomada por el jugador en turno. Lanza
  /// [IllegalActionException] si no es legal en este estado — nunca
  /// silenciosamente la ignora ni la reinterpreta.
  static GameState apply(GameState state, PokerAction action) {
    final slot = state.toActSlot;
    if (slot == null) {
      throw const IllegalActionException(
          'No hay jugador en turno (la mano ya terminó o la calle está '
          'cerrada, hace falta avanzar de calle).');
    }
    final legal = LegalActionEngine.legalActionTypes(state);
    if (!legal.contains(action.type)) {
      throw IllegalActionException(
          '${action.type.label} no es legal para el slot $slot en este '
          'estado (legales: ${legal.map((t) => t.label).join(", ")}).');
    }

    final player = state.seatAt(slot);
    switch (action.type) {
      case ActionType.fold:
        return _applyFold(state, player);
      case ActionType.check:
        return _applyPassive(state, player,
            type: ActionType.check,
            investedThisStreetBb: player.investedThisStreetBb);
      case ActionType.call:
        return _applyPassive(state, player,
            type: ActionType.call,
            investedThisStreetBb: state.round.currentBetBb);
      case ActionType.bet:
      case ActionType.raise:
        return _applyAggressive(state, player, action);
      case ActionType.allIn:
        return _applyAllIn(state, player);
      case ActionType.limp:
        throw IllegalActionException(
            '${action.type.label} no es un tipo de acción resoluble '
            'directamente (usar call).');
    }
  }

  static GameState _applyFold(GameState state, PlayerState player) {
    final newSeats = _replaceSeat(state, player.copyWith(folded: true));
    final stillActive = {
      for (final s in newSeats)
        if (s.isActive) s.slot,
    };
    final round = state.round.copyWith(
      actedSlots: {...state.round.actedSlots, player.slot},
      log: [
        ...state.round.log,
        (slot: player.slot, action: const PokerAction(ActionType.fold)),
      ],
    );

    if (stillActive.length <= 1) {
      return state.copyWith(
        seats: newSeats,
        round: round,
        clearToActSlot: true,
        winnerSlots: stillActive,
        pot: _recomputePot(newSeats, stillActive),
      );
    }

    // Un fold no cambia cuánto hay en el bote, pero sí quién sigue
    // elegible para ganarlo — hay que recalcularlo también acá, no solo
    // en el camino de "la mano terminó".
    return _advanceTurnOrClose(
      state.copyWith(pot: _recomputePot(newSeats, stillActive)),
      newSeats,
      round,
      player.slot,
    );
  }

  /// CHECK o CALL: no cambian `currentBetBb` (CALL solo iguala lo que ya
  /// había, nunca más — ver [delta]). [investedThisStreetBb] es el total al
  /// que queda el jugador en esta calle (igual al que ya tenía, en un
  /// check).
  static GameState _applyPassive(
    GameState state,
    PlayerState player, {
    required ActionType type,
    required double investedThisStreetBb,
  }) {
    // El costo real de un CALL es lo que falta para igualar, no
    // `currentBetBb` a secas: si el jugador ya tenía fichas invertidas en
    // esta calle (p. ej. la BB pagando un raise), ese aporte previo no se
    // vuelve a cobrar.
    final delta = investedThisStreetBb - player.investedThisStreetBb;
    final newPlayer = player.copyWith(
      stackBb: player.stackBb - delta,
      investedThisStreetBb: investedThisStreetBb,
      investedTotalBb: player.investedTotalBb + delta,
    );
    final newSeats = _replaceSeat(state, newPlayer);
    final logged = PokerAction(type,
        sizeBb: type == ActionType.call ? investedThisStreetBb : null);
    final round = state.round.copyWith(
      actedSlots: {...state.round.actedSlots, player.slot},
      log: [...state.round.log, (slot: player.slot, action: logged)],
    );
    final activeSlots = {
      for (final s in newSeats)
        if (s.isActive) s.slot,
    };
    return _advanceTurnOrClose(
      state.copyWith(pot: _recomputePot(newSeats, activeSlots)),
      newSeats,
      round,
      player.slot,
    );
  }

  static GameState _applyAggressive(
    GameState state,
    PlayerState player,
    PokerAction action,
  ) {
    final total = action.sizeBb;
    if (total == null) {
      throw IllegalActionException(
          '${action.type.label} necesita un tamaño (sizeBb).');
    }
    final maxTotal = player.investedThisStreetBb + player.stackBb;
    // El piso es siempre `currentBetBb + minRaiseIncrement`
    // (`LegalActionEngine.minRaiseToBb`), nunca solo `minRaiseIncrement` —
    // importa cuando `currentBetBb` ya es > 0 pero la acción legal igual
    // se llama BET (p. ej. la BB, tras igualar todos los limpers, decide
    // subir en vez de solo pasar: eso no es abrir un bote a 0, es subir
    // desde `currentBetBb`, y el mínimo tiene que reflejarlo).
    final minTotal = LegalActionEngine.minRaiseToBb(state);
    if (total < minTotal - 1e-9 || total > maxTotal + 1e-9) {
      throw IllegalActionException(
          '${action.type.label} a $total bb fuera de rango '
          '[$minTotal, $maxTotal].');
    }

    final delta = total - player.investedThisStreetBb;
    final newPlayer = player.copyWith(
      stackBb: player.stackBb - delta,
      investedThisStreetBb: total,
      investedTotalBb: player.investedTotalBb + delta,
      isAllIn: player.stackBb - delta <= 0,
    );
    final newSeats = _replaceSeat(state, newPlayer);
    final increment = total - state.round.currentBetBb;
    // Un bet/raise de tamaño completo siempre reabre la acción para
    // todos — a diferencia de un all-in corto (ver [_applyAllIn]).
    final round = state.round.copyWith(
      currentBetBb: total,
      minRaiseIncrementBb: increment > state.round.minRaiseIncrementBb
          ? increment
          : state.round.minRaiseIncrementBb,
      lastAggressorSlot: player.slot,
      actedSlots: {player.slot},
      cannotReraiseSlots: const {},
      log: [
        ...state.round.log,
        (slot: player.slot, action: PokerAction(action.type, sizeBb: total)),
      ],
    );
    final activeSlots = {
      for (final s in newSeats)
        if (s.isActive) s.slot,
    };
    return _advanceTurnOrClose(
      state.copyWith(pot: _recomputePot(newSeats, activeSlots)),
      newSeats,
      round,
      player.slot,
    );
  }

  /// ALL-IN: el jugador empuja todo lo que le queda. Se resuelve como
  /// exactamente uno de tres casos distintos, con tres efectos distintos
  /// sobre quién puede volver a subir (ver [BettingRound.cannotReraiseSlots]):
  ///
  ///  - **Short call** (`total <= currentBetBb`): no sube la apuesta, no
  ///    reabre ni cierra nada — un actor más que responde.
  ///  - **Short raise** (`total > currentBetBb` pero el incremento no
  ///    llega a `minRaiseIncrementBb`): sube `currentBetBb`, así que todos
  ///    los demás vuelven a tener que responder, pero **no reabre el
  ///    derecho a subir** de quienes ya habían actuado contra el nivel
  ///    anterior — solo pueden pagar o retirarse.
  ///  - **Full raise** (el incremento sí llega al mínimo): se comporta
  ///    exactamente como un `raise` de tamaño completo — reabre la acción
  ///    para todos.
  static GameState _applyAllIn(GameState state, PlayerState player) {
    final total = player.investedThisStreetBb + player.stackBb;
    final newPlayer = player.copyWith(
      stackBb: 0,
      investedThisStreetBb: total,
      investedTotalBb: player.investedTotalBb + player.stackBb,
      isAllIn: true,
    );
    final newSeats = _replaceSeat(state, newPlayer);
    final logEntry = (
      slot: player.slot,
      action: PokerAction(ActionType.allIn, sizeBb: total),
    );

    final isRaise = total > state.round.currentBetBb;
    final increment = total - state.round.currentBetBb;
    final fullRaise = isRaise && increment >= state.round.minRaiseIncrementBb;

    final BettingRound round;
    if (fullRaise) {
      round = state.round.copyWith(
        currentBetBb: total,
        minRaiseIncrementBb: increment,
        lastAggressorSlot: player.slot,
        actedSlots: {player.slot},
        cannotReraiseSlots: const {},
        log: [...state.round.log, logEntry],
      );
    } else if (isRaise) {
      round = state.round.copyWith(
        currentBetBb: total,
        lastAggressorSlot: player.slot,
        actedSlots: {player.slot},
        // Quienes ya habían actuado contra el nivel de apuesta anterior
        // pierden el derecho a volver a subir; quienes todavía no habían
        // actuado lo conservan (van a entrar a `actedSlots` recién ahora).
        cannotReraiseSlots: {
          ...state.round.cannotReraiseSlots,
          ...state.round.actedSlots,
        },
        log: [...state.round.log, logEntry],
      );
    } else {
      round = state.round.copyWith(
        actedSlots: {...state.round.actedSlots, player.slot},
        log: [...state.round.log, logEntry],
      );
    }

    final activeSlots = {
      for (final s in newSeats)
        if (s.isActive) s.slot,
    };
    return _advanceTurnOrClose(
      state.copyWith(pot: _recomputePot(newSeats, activeSlots)),
      newSeats,
      round,
      player.slot,
    );
  }

  static List<PlayerState> _replaceSeat(GameState state, PlayerState player) => [
        for (final s in state.seats) s.slot == player.slot ? player : s,
      ];

  static PotManager _recomputePot(
          List<PlayerState> seats, Set<int> activeSlots) =>
      PotManager.fromInvestments(
        {for (final s in seats) s.slot: s.investedTotalBb},
        activeSlots: activeSlots,
      );

  /// Después de aplicar una acción: si la calle sigue abierta, calcula
  /// quién actúa después; si se cerró, deja `toActSlot` en `null` (hace
  /// falta llamar [advanceStreet] para seguir).
  static GameState _advanceTurnOrClose(
    GameState state,
    List<PlayerState> newSeats,
    BettingRound round,
    int actorSlot,
  ) {
    final withUpdates = state.copyWith(seats: newSeats, round: round);
    if (withUpdates.isStreetComplete) {
      return withUpdates.copyWith(clearToActSlot: true);
    }
    final positions = TablePositions(withUpdates.buttonSlot);
    final cannotAct = {
      for (final s in newSeats)
        if (s.sittingOut || s.isAllIn) s.slot,
    };
    final next = positions.nextToAct(
      actorSlot,
      withUpdates.street,
      folded: withUpdates.foldedSlots,
      empty: cannotAct,
    );
    return withUpdates.copyWith(
      toActSlot: next,
      clearToActSlot: next == null,
    );
  }

  /// Cierra la calle actual y reparte la siguiente. Requiere que la calle
  /// esté efectivamente cerrada ([GameState.isStreetComplete]) y que no
  /// sea ya el river — de lo contrario es un error de uso del motor
  /// (`StateError`), no una acción ilegal de un jugador.
  static GameState advanceStreet(GameState state) {
    if (state.isHandOver) {
      throw StateError('La mano ya terminó, no hay calle que avanzar.');
    }
    if (!state.isStreetComplete) {
      throw StateError(
          'La calle ${state.street} todavía no está cerrada.');
    }
    if (state.street == Street.river) {
      throw StateError('No hay calle después del river.');
    }

    final nextStreet = Street.values[state.street.index + 1];
    final newCardsNeeded = nextStreet.boardCards - state.board.length;
    final dealt = state.remainingDeckCards.take(newCardsNeeded).toList();
    final remaining = state.remainingDeckCards.skip(newCardsNeeded).toList();

    final resetSeats = [
      for (final s in state.seats) s.copyWith(investedThisStreetBb: 0),
    ];

    final positions = TablePositions(state.buttonSlot);
    final cannotAct = {
      for (final s in resetSeats)
        if (s.sittingOut || s.isAllIn) s.slot,
    };
    final firstToAct = positions.firstToAct(
      nextStreet,
      folded: state.foldedSlots,
      empty: cannotAct,
    );

    return state.copyWith(
      seats: resetSeats,
      street: nextStreet,
      board: [...state.board, ...dealt],
      remainingDeckCards: remaining,
      streetHistory: [...state.streetHistory, state.round],
      round: BettingRound(
        street: nextStreet,
        minRaiseIncrementBb: state.bigBlindBb,
      ),
      toActSlot: firstToAct,
      clearToActSlot: firstToAct == null,
    );
  }
}

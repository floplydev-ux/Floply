import 'dart:math' show min;

import '../card.dart';
import '../position.dart';
import '../street.dart';
import '../../pedagogy/table_position.dart' show TablePositions;
import 'betting_round.dart';
import 'player_state.dart';
import 'pot_manager.dart';

/// El estado mutable (representado de forma inmutable, con `copyWith`) de
/// una mano de Hold'em en curso.
///
/// Es la pieza que la auditoría de motores encontró que faltaba: hoy
/// `PokerSituation` es "la foto" de una única decisión, nunca un stepper.
/// `GameState` + [ActionResolver] cubren ese rol: una mano que avanza
/// acción por acción y calle por calle.
///
/// Determinismo sin hilo de RNG: [remainingDeckCards] es la lista ya
/// barajada (con la semilla del `Deck` que la armó) y congelada — avanzar
/// de calle es simplemente tomar las próximas N cartas del frente de esa
/// lista. `GameState`/`ActionResolver` nunca vuelven a tocar un `Random`.
class GameState {
  GameState({
    required this.buttonSlot,
    required List<PlayerState> seats,
    required this.street,
    List<Card> board = const [],
    required List<Card> remainingDeckCards,
    required this.pot,
    required this.bigBlindBb,
    this.toActSlot,
    required this.round,
    List<BettingRound> streetHistory = const [],
    Set<int>? winnerSlots,
  })  : seats = List.unmodifiable(seats),
        board = List.unmodifiable(board),
        remainingDeckCards = List.unmodifiable(remainingDeckCards),
        streetHistory = List.unmodifiable(streetHistory),
        winnerSlots = winnerSlots == null ? null : Set.unmodifiable(winnerSlots) {
    // Chequeos reales de invariantes — no `assert`: este constructor corre
    // en CADA transición de estado (todo `copyWith` pasa por acá), así que
    // es el lugar correcto para que un estado imposible falle siempre,
    // también en release, en vez de propagarse silenciosamente.
    if (this.seats.length != seatCount) {
      throw ArgumentError.value(this.seats.length, 'seats',
          'debe tener exactamente $seatCount asientos');
    }
    for (var i = 0; i < seatCount; i++) {
      if (this.seats[i].slot != i) {
        throw ArgumentError(
            'seats[$i] tiene slot ${this.seats[i].slot}: cada asiento debe '
            'estar en el índice igual a su propio slot');
      }
    }
    if (buttonSlot < 0 || buttonSlot >= seatCount) {
      throw ArgumentError.value(
          buttonSlot, 'buttonSlot', 'debe estar entre 0 y ${seatCount - 1}');
    }
    if (round.street != street) {
      throw ArgumentError(
          'street ($street) no coincide con round.street (${round.street})');
    }
    if (this.board.length != street.boardCards) {
      throw ArgumentError(
          'board tiene ${this.board.length} cartas pero $street debería '
          'tener ${street.boardCards}');
    }
    final seen = <Card>{};
    void checkUnique(Card c, String where) {
      if (!seen.add(c)) {
        throw ArgumentError('carta repetida $c ($where)');
      }
    }

    for (final s in this.seats) {
      final hole = s.holeCards;
      if (hole != null) {
        checkUnique(hole.high, 'hole cards del slot ${s.slot}');
        checkUnique(hole.low, 'hole cards del slot ${s.slot}');
      }
    }
    for (final c in this.board) {
      checkUnique(c, 'board');
    }
    for (final c in this.remainingDeckCards) {
      checkUnique(c, 'remainingDeckCards');
    }
  }

  static const int seatCount = 6;

  /// Slot (0..5) que tiene el botón del dealer. Fuente de verdad para
  /// derivar la [Position] de cualquier slot vía [positionOf].
  final int buttonSlot;

  /// Los 6 asientos de la mesa, indexados por slot (`seats[i].slot == i`).
  final List<PlayerState> seats;

  final Street street;

  /// Cartas comunitarias reveladas hasta ahora (0 en preflop, 3 en flop...).
  final List<Card> board;

  /// Cartas del mazo que todavía no se repartieron, en el orden en que se
  /// van a repartir (frente de la lista = próxima carta).
  final List<Card> remainingDeckCards;

  final PotManager pot;

  /// Tamaño de la ciega grande, en BB (por definición, `1`) — se guarda
  /// igual para que las reglas de sizing (mínimo bet/raise al abrir una
  /// calle nueva) no dependan de una constante repetida en otro lado.
  final double bigBlindBb;

  /// Slot que debe actuar ahora. `null` si la mano terminó.
  final int? toActSlot;

  final BettingRound round;

  /// Rondas de apuestas ya cerradas de calles anteriores, en orden.
  final List<BettingRound> streetHistory;

  /// Slots ganadores, una vez resuelta la mano. Esta pasada solo resuelve
  /// manos que terminan porque todos menos uno se retiraron — ver
  /// [needsShowdown] para el caso todavía no resuelto por este motor.
  final Set<int>? winnerSlots;

  TablePositions get _positions => TablePositions(buttonSlot);

  /// La posición del asiento [slot], derivada de [buttonSlot]. Única
  /// fuente de verdad — nunca se guarda una `Position` en [PlayerState].
  Position positionOf(int slot) => _positions.positionOf(slot);

  PlayerState seatAt(int slot) => seats[slot];

  Set<int> get foldedSlots =>
      {for (final s in seats) if (s.folded) s.slot};

  Set<int> get emptySlots =>
      {for (final s in seats) if (s.sittingOut) s.slot};

  /// Slots que siguen en juego por el bote (no foldeados, no afuera).
  Set<int> get activeSlots =>
      {for (final s in seats) if (s.isActive) s.slot};

  /// La calle en curso está cerrada: todos los que todavía pueden actuar
  /// ya actuaron desde la última subida y coinciden con la apuesta actual
  /// (o no queda nadie en condiciones de actuar más).
  ///
  /// Nota: este chequeo también cubre correctamente la "opción de la BB"
  /// preflop — la BB es un actor normal en [round.actedSlots], así que si
  /// todos igualaron pero la BB todavía no actuó, la calle sigue abierta.
  bool get isStreetComplete {
    final active = seats.where((s) => s.isActive).toList();
    if (active.length <= 1) return true;
    final pending = active.where((s) => !s.isAllIn).toList();
    if (pending.isEmpty) return true; // todos los que quedan están all-in
    return pending.every((s) =>
        round.actedSlots.contains(s.slot) &&
        s.investedThisStreetBb == round.currentBetBb);
  }

  /// La mano terminó porque todos menos uno se retiraron.
  bool get isHandOver => winnerSlots != null;

  /// La mano llegó al final del river con 2+ jugadores todavía activos:
  /// haría falta un showdown para saber quién gana. Esta pasada (Fase 1+2)
  /// no incluye un evaluador de manos — `ActionResolver` no resuelve este
  /// caso, y [winnerSlots] queda `null`. Ver el informe final, sección de
  /// deuda técnica restante.
  bool get needsShowdown =>
      street == Street.river &&
      isStreetComplete &&
      winnerSlots == null &&
      activeSlots.length > 1;

  /// Arma el estado inicial de una mano: postea ciegas y calcula quién
  /// actúa primero preflop. Es mecánica de reglas pura (no elige qué
  /// cartas ni qué stacks — eso es responsabilidad de quien arme el
  /// escenario, hoy fuera del alcance de esta pasada).
  factory GameState.newHand({
    required int buttonSlot,
    required List<PlayerState> seats,
    required List<Card> remainingDeckCards,
    double smallBlindBb = 0.5,
    double bigBlindBb = 1,
  }) {
    if (seats.length != seatCount) {
      throw ArgumentError.value(
          seats.length, 'seats', 'debe tener exactamente $seatCount asientos');
    }
    final positions = TablePositions(buttonSlot);
    final sbSlot = positions.slotOf(Position.sb);
    final bbSlot = positions.slotOf(Position.bb);

    PlayerState postBlind(PlayerState s, double amount) {
      final posted = min(amount, s.stackBb);
      return s.copyWith(
        stackBb: s.stackBb - posted,
        investedThisStreetBb: posted,
        investedTotalBb: posted,
        isAllIn: posted == s.stackBb,
      );
    }

    final postedSeats = [
      for (final s in seats)
        if (s.slot == sbSlot && s.isActive)
          postBlind(s, smallBlindBb)
        else if (s.slot == bbSlot && s.isActive)
          postBlind(s, bigBlindBb)
        else
          s,
    ];

    // No solo `sittingOut`: si postear la ciega dejó a alguien all-in (un
    // stack más corto que la ciega), tampoco puede ser el primero en
    // actuar — mismo criterio que usa `ActionResolver` en cada
    // transición de turno.
    final cannotAct = {
      for (final s in postedSeats)
        if (s.sittingOut || s.isAllIn) s.slot,
    };
    final toAct =
        positions.firstToAct(Street.preflop, folded: const {}, empty: cannotAct);

    final activeSlots = {
      for (final s in postedSeats)
        if (s.isActive) s.slot,
    };

    return GameState(
      buttonSlot: buttonSlot,
      seats: postedSeats,
      street: Street.preflop,
      board: const [],
      remainingDeckCards: remainingDeckCards,
      pot: PotManager.fromInvestments(
        {for (final s in postedSeats) s.slot: s.investedTotalBb},
        activeSlots: activeSlots,
      ),
      bigBlindBb: bigBlindBb,
      toActSlot: toAct,
      round: BettingRound(
        street: Street.preflop,
        currentBetBb: bigBlindBb,
        minRaiseIncrementBb: bigBlindBb,
        lastAggressorSlot: bbSlot,
      ),
    );
  }

  GameState copyWith({
    List<PlayerState>? seats,
    Street? street,
    List<Card>? board,
    List<Card>? remainingDeckCards,
    PotManager? pot,
    int? toActSlot,
    bool clearToActSlot = false,
    BettingRound? round,
    List<BettingRound>? streetHistory,
    Set<int>? winnerSlots,
  }) =>
      GameState(
        buttonSlot: buttonSlot,
        seats: seats ?? this.seats,
        street: street ?? this.street,
        board: board ?? this.board,
        remainingDeckCards: remainingDeckCards ?? this.remainingDeckCards,
        pot: pot ?? this.pot,
        bigBlindBb: bigBlindBb,
        toActSlot: clearToActSlot ? null : (toActSlot ?? this.toActSlot),
        round: round ?? this.round,
        streetHistory: streetHistory ?? this.streetHistory,
        winnerSlots: winnerSlots ?? this.winnerSlots,
      );

  @override
  String toString() =>
      'GameState(street: $street, board: $board, toAct: $toActSlot, '
      'pot: ${pot.totalBb})';
}

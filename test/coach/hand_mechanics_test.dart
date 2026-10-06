import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker/game/player_state.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/screens/coach/coach_table_snapshot.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<PlayerState> sixSeats({double stackBb = 100}) => [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(slot: slot, stackBb: stackBb),
    ];

/// Mazo fijo de 8 cartas suficientes para cualquier test unitario.
List<Card> fixedDeck() => const [
      Card(Rank.two, Suit.clubs),
      Card(Rank.three, Suit.clubs),
      Card(Rank.four, Suit.clubs),
      Card(Rank.five, Suit.clubs),
      Card(Rank.six, Suit.clubs),
      Card(Rank.seven, Suit.clubs),
      Card(Rank.eight, Suit.clubs),
      Card(Rank.nine, Suit.clubs),
    ];

int slotFor(Position pos, int buttonSlot) =>
    TablePositions(buttonSlot).slotOf(pos);

/// Obtiene el slot activo en turno dado el estado actual y lo aplica.
GameState _fold(GameState state) =>
    ActionResolver.apply(state, const PokerAction(ActionType.fold));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // --- Caso A: stack corto no puede apostar más de lo que tiene ---
  test('A — short stack bet capped at available chips', () {
    // Armar mesa con un jugador de stack muy corto (3 BB).
    // El botón está en slot 0, SB=slot5, BB=slot4, UTG=slot3
    // Vamos a hacer que todos foldeen hasta llegar al jugador de stack corto.
    final seats = [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(
          slot: slot,
          stackBb: slot == 3 ? 3.0 : 100.0, // slot 3 tiene solo 3 BB
        ),
    ];
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: seats,
      remainingDeckCards: fixedDeck(),
    );

    // Obtener los slots de SB y BB
    final sbSlot = slotFor(Position.sb, 0);
    final bbSlot = slotFor(Position.bb, 0);

    // Avanzar hasta que sea el turno del slot 3 (stack corto)
    while (state.toActSlot != 3 && !state.isHandOver) {
      final toAct = state.toActSlot!;
      if (toAct == sbSlot || toAct == bbSlot) {
        // SB/BB ya postearon — si llegamos aquí es su opción; pasar
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      } else {
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
    }

    if (state.isHandOver) return; // mano terminó antes de slot 3

    final player = state.seatAt(3);
    final legalTypes = LegalActionEngine.legalActionTypes(state);

    // Con stack de 3 BB, enfrentando la BB de 1 BB, el jugador puede:
    // raise (si tiene suficiente) o all-in
    // El máximo legal es su stack + lo invertido
    final maxRaise = LegalActionEngine.maxRaiseToBb(state);
    expect(maxRaise, equals(player.investedThisStreetBb + player.stackBb));

    // Si el jugador hace all-in, su stack queda en 0 y isAllIn = true
    if (legalTypes.contains(ActionType.allIn)) {
      final newState = ActionResolver.apply(
          state, const PokerAction(ActionType.allIn));
      final newPlayer = newState.seatAt(3);
      expect(newPlayer.stackBb, 0.0);
      expect(newPlayer.isAllIn, isTrue);
    }
  });

  // --- Caso B: stack normal —  apuesta descuenta correctamente ---
  test('B — normal bet deducts correctly', () {
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: sixSeats(stackBb: 100),
      remainingDeckCards: fixedDeck(),
    );

    // Buscar el primer jugador en turno que puede BET/RAISE
    final toActSlot = state.toActSlot!;
    final playerBefore = state.seatAt(toActSlot);
    final stackBefore = playerBefore.stackBb + playerBefore.investedThisStreetBb;

    // Apostar 10 BB (si es legal, de lo contrario fold)
    final legal = LegalActionEngine.legalActionTypes(state);
    if (legal.contains(ActionType.raise)) {
      final min = LegalActionEngine.minRaiseToBb(state);
      final raiseTo = (min + 4.0).clamp(min, LegalActionEngine.maxRaiseToBb(state));
      state = ActionResolver.apply(state, PokerAction.raiseTo(raiseTo));
      final playerAfter = state.seatAt(toActSlot);
      expect(playerAfter.investedTotalBb,
          greaterThan(playerBefore.investedTotalBb));
      expect(playerAfter.stackBb + playerAfter.investedTotalBb,
          closeTo(stackBefore, 1e-9));
    }
  });

  // --- Caso C: raise adicional vs total —  el motor descuenta solo el delta ---
  test('C — raise amount is additional not total', () {
    // Arrancar una mano y dejar que SB postee (ya está hecho por newHand)
    // luego que alguien suba, y verificar que el delta se descuenta
    // correctamente (no el total acumulado).
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: sixSeats(stackBb: 100),
      remainingDeckCards: fixedDeck(),
    );

    // UTG sube a 3 BB
    final utg = state.toActSlot!;
    final min = LegalActionEngine.minRaiseToBb(state);
    state = ActionResolver.apply(state, PokerAction.raiseTo(min));
    final playerAfterRaise = state.seatAt(utg);

    // El stack debe ser exactamente stackBb inicial - lo que invirtió en total
    expect(playerAfterRaise.stackBb,
        closeTo(100.0 - playerAfterRaise.investedTotalBb, 1e-9));
    expect(playerAfterRaise.stackBb, greaterThanOrEqualTo(0));
  });

  // --- Caso D: apostar nunca aumenta el stack ---
  test('D — betting never increases stack', () {
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: sixSeats(stackBb: 100),
      remainingDeckCards: fixedDeck(),
    );

    // Aplicar varias acciones y verificar que el stack nunca sube
    var actionsLeft = 10;
    while (!state.isHandOver && actionsLeft > 0) {
      final slot = state.toActSlot;
      if (slot == null) break;
      final player = state.seatAt(slot);
      final stackBefore = player.stackBb;

      final legal = LegalActionEngine.legalActionTypes(state);
      if (legal.contains(ActionType.call)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.call));
      } else if (legal.contains(ActionType.check)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.check));
      } else {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.fold));
      }

      final playerAfter = state.seatAt(slot);
      expect(playerAfter.stackBb, lessThanOrEqualTo(stackBefore + 1e-9),
          reason: 'slot $slot: stack aumentó de $stackBefore a ${playerAfter.stackBb}');
      actionsLeft--;
    }
  });

  // --- Caso E: all-in cuando apuesta == stack ---
  test('E — all-in when bet equals full stack', () {
    final seats = [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(slot: slot, stackBb: 50.0),
    ];
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: seats,
      remainingDeckCards: fixedDeck(),
    );

    // Encontrar un jugador que pueda hacer all-in
    while (!state.isHandOver) {
      final slot = state.toActSlot;
      if (slot == null) break;
      final legal = LegalActionEngine.legalActionTypes(state);
      if (legal.contains(ActionType.allIn)) {
        final playerBefore = state.seatAt(slot);
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.allIn));
        final playerAfter = state.seatAt(slot);
        expect(playerAfter.stackBb, 0.0);
        expect(playerAfter.isAllIn, isTrue);
        expect(playerAfter.investedTotalBb,
            greaterThan(playerBefore.investedTotalBb));
        return; // test pasado
      } else if (legal.contains(ActionType.fold)) {
        state = _fold(state);
      } else if (legal.contains(ActionType.call)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.call));
      } else {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.check));
      }
    }
  });

  // --- Caso F: jugador foldado no revela cartas al showdown ---
  test('F — folded player cards stay hidden at showdown', () {
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: sixSeats(stackBb: 100),
      remainingDeckCards: fixedDeck(),
    );

    // Hacer fold a todos menos la BB (slot bbSlot) y el primero en turno
    final bbSlot = slotFor(Position.bb, 0);
    int? lastFolder;
    while (!state.isHandOver) {
      final toAct = state.toActSlot;
      if (toAct == null) break;
      if (state.isStreetComplete) break;
      if (toAct != bbSlot) {
        lastFolder = toAct;
        state = _fold(state);
      } else {
        break; // dejamos que la mano termine por fold-out
      }
    }

    if (lastFolder == null) return;

    // Verificar que el snapshot con revealAll=true NO muestra cartas de foldados
    final snapshot = CoachTableSnapshot.from(
      state,
      heroSlot: 0,
      revealAll: true,
      winnerSlots: state.winnerSlots ?? const {},
    );

    // El jugador que foldeó no debe tener cartas
    final foldedSeat = snapshot.seatAt(lastFolder);
    expect(foldedSeat.cards, isEmpty,
        reason:
            'el jugador foldado (slot $lastFolder) no debería tener cartas '
            'visibles aunque revealAll=true');
  });

  // --- Caso H: jugador all-in no recibe más turnos ---
  test('H — all-in player skipped in subsequent betting rounds', () {
    // Construir una situación donde alguien va all-in y verificar
    // que no aparece como `toActSlot` en la siguiente ronda.
    final seats = [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(slot: slot, stackBb: slot == 3 ? 2.0 : 100.0),
    ];
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: seats,
      remainingDeckCards: fixedDeck(),
    );

    // Avanzar hasta que el slot 3 vaya all-in
    var allInSlot = -1;
    while (!state.isHandOver && allInSlot == -1) {
      final toAct = state.toActSlot;
      if (toAct == null) break;
      final legal = LegalActionEngine.legalActionTypes(state);
      if (toAct == 3 && legal.contains(ActionType.allIn)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.allIn));
        allInSlot = 3;
      } else if (toAct == 3 && legal.contains(ActionType.fold)) {
        // Stack muy corto puede no alcanzar ni para all-in; saltar test
        return;
      } else if (legal.contains(ActionType.fold)) {
        state = _fold(state);
      } else if (legal.contains(ActionType.call)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.call));
      } else {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.check));
      }
    }

    if (allInSlot == -1 || state.isHandOver) return;

    // Después del all-in, el slot 3 nunca debe ser toActSlot
    var steps = 0;
    while (!state.isHandOver && steps < 50) {
      expect(state.toActSlot, isNot(equals(allInSlot)),
          reason: 'el slot $allInSlot está all-in y no debería volver a actuar');

      final toAct = state.toActSlot;
      if (toAct == null) {
        if (state.isStreetComplete && state.street.index < 3) {
          state = ActionResolver.advanceStreet(state);
        }
        break;
      }
      final legal = LegalActionEngine.legalActionTypes(state);
      if (legal.contains(ActionType.check)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.check));
      } else if (legal.contains(ActionType.call)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.call));
      } else {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.fold));
      }
      steps++;
    }
  });

  // --- Invariante: apuesta nunca deja stack negativo ---
  test('stack cannot go negative after any sequence of actions', () {
    var state = GameState.newHand(
      buttonSlot: 0,
      seats: sixSeats(stackBb: 20), // stacks cortos para forzar all-ins
      remainingDeckCards: fixedDeck(),
    );

    var steps = 0;
    while (!state.isHandOver && steps < 80) {
      final toAct = state.toActSlot;
      if (toAct == null) {
        if (state.isStreetComplete &&
            !state.isHandOver &&
            state.street.index < 3) {
          state = ActionResolver.advanceStreet(state);
        } else {
          break;
        }
        continue;
      }

      // Verificar que todos los stacks son >= 0 en este momento
      for (final seat in state.seats) {
        expect(seat.stackBb, greaterThanOrEqualTo(-1e-9),
            reason: 'slot ${seat.slot} tiene stack negativo: ${seat.stackBb}');
      }

      final legal = LegalActionEngine.legalActionTypes(state);
      if (legal.contains(ActionType.allIn)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.allIn));
      } else if (legal.contains(ActionType.call)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.call));
      } else if (legal.contains(ActionType.check)) {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.check));
      } else {
        state = ActionResolver.apply(
            state, const PokerAction(ActionType.fold));
      }
      steps++;
    }
  });
}

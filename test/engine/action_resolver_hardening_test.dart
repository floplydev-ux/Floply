import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker/game/player_state.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';

/// Hardening final de Fase 2 — los dos gates identificados como deuda en
/// la auditoría profunda: conservación global de fichas y una cadena de
/// varios short all-ins sucesivos con distintos jugadores.

List<PlayerState> sixSeats({double stackBb = 100}) => [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(slot: slot, stackBb: stackBb),
    ];

List<Card> fixedDeckTail() => const [
      Card(Rank.two, Suit.clubs),
      Card(Rank.three, Suit.clubs),
      Card(Rank.four, Suit.clubs),
      Card(Rank.five, Suit.clubs),
      Card(Rank.six, Suit.clubs),
      Card(Rank.seven, Suit.clubs),
      Card(Rank.eight, Suit.clubs),
      Card(Rank.nine, Suit.clubs),
    ];

int slotFor(Position position, int buttonSlot) =>
    TablePositions(buttonSlot).slotOf(position);

/// Suma de stacks + bote — el total de fichas "vivo" en la mano en este
/// instante. Nunca debería moverse de un `totalInicial` fijo: cada ficha
/// que sale de un stack tiene que entrar al bote, y viceversa.
double totalChips(GameState state) =>
    state.seats.fold(0.0, (sum, s) => sum + s.stackBb) + state.pot.totalBb;

double totalInvestedTotal(GameState state) =>
    state.seats.fold(0.0, (sum, s) => sum + s.investedTotalBb);

void main() {
  group('Hardening 1 — conservación global de fichas', () {
    test(
        'stacks + pot se mantiene exactamente igual al total inicial después '
        'de CADA acción — bet, call, raise, call, fold, cambio de calle, '
        'nuevas apuestas — y el pot siempre coincide con investedTotal',
        () {
      final rawSeats = sixSeats(stackBb: 100);
      // Total inicial: la suma de stacks ANTES de postear ninguna ciega.
      // Nada de lo que pase después (ciegas, apuestas, folds, calles)
      // puede cambiar esta suma — solo puede moverse entre "stack" y
      // "pot".
      final totalInicial =
          rawSeats.fold(0.0, (sum, s) => sum + s.stackBb);

      void checkConservation(GameState state, String where) {
        expect(totalChips(state), closeTo(totalInicial, 1e-9),
            reason: 'conservación de fichas rota: $where');
        expect(state.pot.totalBb, closeTo(totalInvestedTotal(state), 1e-9),
            reason: 'pot no coincide con investedTotal: $where');
      }

      GameState apply(GameState state, PokerAction action, String where) {
        final next = ActionResolver.apply(state, action);
        checkConservation(next, where);
        return next;
      }

      GameState advance(GameState state, String where) {
        final next = ActionResolver.advanceStreet(state);
        checkConservation(next, where);
        return next;
      }

      var state = GameState.newHand(
        buttonSlot: 0,
        seats: rawSeats,
        remainingDeckCards: fixedDeckTail(),
      );
      checkConservation(state, 'justo después de postear las ciegas');

      // --- Preflop: raise, fold, call, fold, fold, call ---
      state = apply(state, PokerAction.raiseTo(3), 'UTG raise a 3');
      state = apply(state, const PokerAction(ActionType.fold), 'HJ fold');
      state = apply(state, const PokerAction(ActionType.call), 'CO call');
      state = apply(state, const PokerAction(ActionType.fold), 'BTN fold');
      state = apply(state, const PokerAction(ActionType.fold), 'SB fold');
      state = apply(state, const PokerAction(ActionType.call), 'BB call');
      expect(state.isStreetComplete, isTrue);
      expect(state.activeSlots.length, 3, reason: 'UTG, CO y BB siguen en mano');

      // --- Cambio de calle: preflop → flop ---
      state = advance(state, 'avanzar a flop');
      expect(state.street.name, 'flop');

      // --- Flop: bet, call, raise, fold, call ---
      final toActOnFlop = state.toActSlot!;
      state = apply(state, PokerAction.bet(5), 'primero en el flop apuesta 5');
      state = apply(state, const PokerAction(ActionType.call), 'siguiente paga');
      state = apply(state, PokerAction.raiseTo(20), 'tercero sube a 20');
      // Quien abrió la apuesta se retira; el que pagó antes vuelve a pagar.
      state = apply(state, const PokerAction(ActionType.fold),
          'el que abrió la apuesta se retira');
      state = apply(state, const PokerAction(ActionType.call),
          'el otro jugador paga el raise');
      expect(state.isStreetComplete, isTrue);
      expect(state.activeSlots.length, 2);
      expect(toActOnFlop, isNotNull); // referencia usada solo para claridad del relato

      // --- Cambio de calle: flop → turn, con más apuestas ---
      state = advance(state, 'avanzar a turn');
      state = apply(state, PokerAction.bet(10), 'bet en el turn');
      state = apply(state, const PokerAction(ActionType.call), 'call en el turn');
      expect(state.isStreetComplete, isTrue);

      state = advance(state, 'avanzar a river');
      state = apply(state, const PokerAction(ActionType.check), 'check en el river');
      state = apply(state, const PokerAction(ActionType.check), 'check en el river');
      expect(state.needsShowdown, isTrue);

      // Verificación final, de punta a punta.
      checkConservation(state, 'estado final, mano completa');
    });

    test('conservación de fichas también se sostiene cuando alguien va '
        'all-in y arrastra su stack a 0', () {
      final rawSeats = sixSeats(stackBb: 20);
      final totalInicial = rawSeats.fold(0.0, (sum, s) => sum + s.stackBb);

      var state = GameState.newHand(
        buttonSlot: 0,
        seats: rawSeats,
        remainingDeckCards: fixedDeckTail(),
      );

      void checkConservation(String where) {
        expect(totalChips(state), closeTo(totalInicial, 1e-9), reason: where);
        expect(state.pot.totalBb, closeTo(totalInvestedTotal(state), 1e-9),
            reason: where);
      }

      // Todos van all-in preflop (stacks cortos: 20bb).
      while (!state.isStreetComplete) {
        final legal = LegalActionEngine.legalActionTypes(state);
        final actor = state.seatAt(state.toActSlot!);
        final shoveTo = actor.investedThisStreetBb + actor.stackBb;
        if (legal.contains(ActionType.allIn)) {
          state = ActionResolver.apply(state, const PokerAction(ActionType.allIn));
        } else if (legal.contains(ActionType.raise)) {
          state = ActionResolver.apply(state, PokerAction.raiseTo(shoveTo));
        } else if (legal.contains(ActionType.bet)) {
          state = ActionResolver.apply(state, PokerAction.bet(shoveTo));
        } else {
          state = ActionResolver.apply(state, const PokerAction(ActionType.call));
        }
        checkConservation('tras una acción de la cadena de all-ins');
      }

      while (state.street.name != 'river') {
        state = ActionResolver.advanceStreet(state);
        checkConservation('tras avanzar de calle con todos all-in');
      }
      checkConservation('mano corrida hasta el final');
    });
  });

  group('Hardening 2 — cadena de múltiples short all-ins (4 jugadores)', () {
    test(
        'A abre, B sube completo, C va all-in corto, D va all-in corto de '
        'nuevo, A (que nunca respondió) conserva el raise y reabre '
        'completo, y B recupera el derecho a subir que había perdido', () {
      // buttonSlot=0 → sb=5, bb=4, utg=3, hj=2. CO/BTN (slots 1,0) fuera
      // de la mano para tener exactamente 4 jugadores activos: A=SB,
      // B=BB, C=UTG, D=HJ, en ese orden de acción postflop.
      final sbSlot = slotFor(Position.sb, 0);
      final bbSlot = slotFor(Position.bb, 0);
      final utgSlot = slotFor(Position.utg, 0);
      final hjSlot = slotFor(Position.hj, 0);

      var state = _fourHandedFlop();
      expect(state.toActSlot, sbSlot);

      // --- A abre por 4 (bet de apertura, minRaiseIncrement pasa a 4) ---
      state = ActionResolver.apply(state, PokerAction.bet(4));
      expect(state.round.currentBetBb, 4);
      expect(state.round.minRaiseIncrementBb, 4);
      expect(state.toActSlot, bbSlot);

      // --- B sube a 12: raise COMPLETO (increment 8 >= 4) ---
      state = ActionResolver.apply(state, PokerAction.raiseTo(12));
      expect(state.round.currentBetBb, 12);
      expect(state.round.minRaiseIncrementBb, 8);
      expect(state.round.cannotReraiseSlots, isEmpty,
          reason: 'un raise completo reabre para todos');
      expect(state.toActSlot, utgSlot);

      // --- C (stack ajustado a 16 en total) va all-in: SHORT raise ---
      // owed = 12, minRaiseIncrement = 8 → un raise completo necesitaría
      // llegar a 20. 16 sube la apuesta pero no llega: short raise.
      state = state.copyWith(seats: [
        for (final s in state.seats)
          if (s.slot == utgSlot) s.copyWith(stackBb: 16) else s,
      ]);
      final legalC = LegalActionEngine.legalActionTypes(state);
      expect(legalC, {ActionType.fold, ActionType.call, ActionType.allIn},
          reason: 'C no llega a un raise completo (necesitaría 20)');

      state = ActionResolver.apply(state, const PokerAction(ActionType.allIn));
      expect(state.round.currentBetBb, 16);
      expect(state.round.minRaiseIncrementBb, 8,
          reason: 'short raise: el mínimo NO sube');
      expect(state.round.cannotReraiseSlots, {bbSlot},
          reason: 'B ya había actuado contra el nivel de 12; queda capado');
      expect(state.toActSlot, hjSlot);

      // --- D (stack ajustado a 20 en total) también va all-in corto: ---
      // segundo short raise sucesivo, de un jugador DISTINTO a C.
      // owed = 16, minRaiseIncrement sigue en 8 → un raise completo
      // necesitaría llegar a 24. 20 sube la apuesta pero tampoco llega.
      state = state.copyWith(seats: [
        for (final s in state.seats)
          if (s.slot == hjSlot) s.copyWith(stackBb: 20) else s,
      ]);
      final legalD = LegalActionEngine.legalActionTypes(state);
      expect(legalD, {ActionType.fold, ActionType.call, ActionType.allIn},
          reason: 'D tampoco llega a un raise completo (necesitaría 24); '
              'D nunca había actuado, así que NO está en cannotReraiseSlots '
              '— la restricción es sobre RAISE, no sobre poder actuar');

      state = ActionResolver.apply(state, const PokerAction(ActionType.allIn));
      expect(state.round.currentBetBb, 20);
      expect(state.round.minRaiseIncrementBb, 8,
          reason: 'segundo short raise seguido: el mínimo sigue sin subir');
      expect(state.round.cannotReraiseSlots, {bbSlot, utgSlot},
          reason: 'B (capado desde antes) y C (que acababa de actuar '
              'contra el nivel de 12 cuando D subió) quedan capados; C '
              'de todos modos ya está all-in y no puede volver a actuar');

      // --- A (SB) nunca respondió a nada de esto: conserva el raise ---
      expect(state.toActSlot, sbSlot,
          reason: 'A es el único que sigue en pie y no está all-in');
      final legalA = LegalActionEngine.legalActionTypes(state);
      expect(legalA, {ActionType.fold, ActionType.call, ActionType.raise},
          reason: 'A jamás actuó contra ningún nivel posterior a su propio '
              'bet de apertura — conserva el derecho a subir intacto, pese '
              'a dos short all-ins sucesivos de otros jugadores');

      // A hace un raise COMPLETO a 28 (increment 8 >= 8): reabre para todos.
      state = ActionResolver.apply(state, PokerAction.raiseTo(28));
      expect(state.round.currentBetBb, 28);
      expect(state.round.minRaiseIncrementBb, 8);
      expect(state.round.cannotReraiseSlots, isEmpty,
          reason: 'un raise de tamaño completo reabre la acción para '
              'TODOS — incluido B, que antes estaba capado');

      // --- B recupera el derecho a subir que había perdido ---
      expect(state.toActSlot, bbSlot);
      final legalBAfterReopen = LegalActionEngine.legalActionTypes(state);
      expect(legalBAfterReopen, {ActionType.fold, ActionType.call, ActionType.raise},
          reason: 'B había quedado capado por el short raise de C, pero el '
              'raise completo de A reabre la acción para todos de nuevo');
    });
  });
}

/// Lleva 4 jugadores (SB, BB, UTG, HJ — CO y BTN afuera de la mano) hasta
/// el flop con currentBet en 0 de verdad, vía un preflop de call-around
/// normal + opción de la BB.
GameState _fourHandedFlop() {
  final seats = [
    for (var slot = 0; slot < 6; slot++)
      PlayerState(slot: slot, stackBb: 100, sittingOut: slot == 0 || slot == 1),
  ];
  var state = GameState.newHand(
    buttonSlot: 0,
    seats: seats,
    remainingDeckCards: fixedDeckTail(),
  );
  while (!state.isStreetComplete) {
    final legal = LegalActionEngine.legalActionTypes(state);
    final type = legal.contains(ActionType.call) ? ActionType.call : ActionType.check;
    state = ActionResolver.apply(state, PokerAction(type));
  }
  return ActionResolver.advanceStreet(state);
}

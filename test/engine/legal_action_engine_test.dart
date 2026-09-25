import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker/game/player_state.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';

List<PlayerState> sixSeats({double stackBb = 100}) => [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(slot: slot, stackBb: stackBb),
    ];

/// El slot de [position] para una mesa con este [buttonSlot], calculado
/// con el motor real de posiciones (no reinventado acá).
int slotFor(Position position, int buttonSlot) =>
    TablePositions(buttonSlot).slotOf(position);

void main() {
  group('LegalActionEngine — enfrentando una apuesta (preflop, UTG)', () {
    test('con stack profundo: fold, call, raise', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      final legal = LegalActionEngine.legalActionTypes(state);
      expect(legal, {ActionType.fold, ActionType.call, ActionType.raise});
    });

    test('raise mínimo es currentBet + minRaiseIncrement (2bb preflop)', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      expect(LegalActionEngine.minRaiseToBb(state), 2);
    });

    test('raise máximo es invertido + stack del jugador en turno', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      final utg = state.toActSlot!;
      expect(LegalActionEngine.maxRaiseToBb(state),
          state.seatAt(utg).investedThisStreetBb + 100);
    });

    test('con stack que no alcanza ni para igualar: fold, all-in', () {
      final utgSlot = slotFor(Position.utg, 0);
      final shortSeats = [
        for (final s in sixSeats(stackBb: 100))
          if (s.slot == utgSlot) s.copyWith(stackBb: 0.5) else s,
      ];
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: shortSeats,
        remainingDeckCards: const [],
      );
      expect(state.toActSlot, utgSlot);
      final legal = LegalActionEngine.legalActionTypes(state);
      expect(legal, {ActionType.fold, ActionType.allIn});
    });

    test(
        'con stack que alcanza para igualar pero no para un raise completo: '
        'fold, call, all-in', () {
      final utgSlot = slotFor(Position.utg, 0);
      // BB=1, así que owed=1 para UTG. minRaiseIncrement=1 (BB). Con stack
      // 1.5: alcanza para call (owed=1, deja 0.5) pero no para un raise
      // completo (necesitaría al menos otro 1bb más).
      final shortSeats = [
        for (final s in sixSeats(stackBb: 100))
          if (s.slot == utgSlot) s.copyWith(stackBb: 1.5) else s,
      ];
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: shortSeats,
        remainingDeckCards: const [],
      );
      final legal = LegalActionEngine.legalActionTypes(state);
      expect(legal, {ActionType.fold, ActionType.call, ActionType.allIn});
    });
  });

  group('LegalActionEngine — sin apuesta que igualar', () {
    test('la BB con su propia opción (todos limpiaron): check, bet', () {
      final bbSlot = slotFor(Position.bb, 0);
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      // Todos limpian (call) hasta llegar a la BB.
      while (state.toActSlot != bbSlot) {
        state = _callAction(state);
      }
      final legal = LegalActionEngine.legalActionTypes(state);
      expect(legal, {ActionType.check, ActionType.bet});
    });
  });

  group('Auditoría sección 4 — matriz de escenarios de acciones legales', () {
    test('Caso A — sin apuesta, héroe primero en hablar: CHECK, BET (y '
        'un ALL_IN voluntario es alcanzable apostando todo el stack, no '
        'un tercer tipo aparte)', () {
      // Postflop recién repartido: currentBet vuelve a 0 de verdad (no es
      // el caso particular de la BB con su propia ciega ya puesta).
      var state = _headsUpToFlop();
      final legal = LegalActionEngine.legalActionTypes(state);
      expect(legal, {ActionType.check, ActionType.bet});
      // Apostar el stack entero es simplemente un BET de tamaño = stack,
      // no requiere que ALL_IN esté en el set legal.
      final toAct = state.seatAt(state.toActSlot!);
      final allInBet = ActionResolver.apply(
          state, PokerAction.bet(toAct.investedThisStreetBb + toAct.stackBb));
      expect(allInBet.seatAt(toAct.slot).isAllIn, isTrue);
    });

    test('Caso B — enfrentando una apuesta: FOLD, CALL, RAISE (con '
        'ALL_IN en vez de RAISE cuando el stack no da para uno completo)',
        () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      expect(LegalActionEngine.legalActionTypes(state),
          {ActionType.fold, ActionType.call, ActionType.raise});
    });

    test('Caso C — héroe con 0 fichas restantes: sin acciones', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      final utg = state.toActSlot!;
      // 0 fichas y en juego solo puede llegar como consecuencia de un
      // all-in (isAllIn queda true) — no hay forma de tener stack 0 sin
      // estar all-in; probamos ambos ejes igual, por las dudas.
      final zeroChips = state.copyWith(seats: [
        for (final s in state.seats)
          if (s.slot == utg) s.copyWith(stackBb: 0, isAllIn: true) else s,
      ]);
      expect(LegalActionEngine.legalActionTypes(zeroChips), isEmpty);
    });

    test('Caso D — héroe ya foldeado: sin acciones', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      final utg = state.toActSlot!;
      final foldedState = state.copyWith(seats: [
        for (final s in state.seats)
          if (s.slot == utg) s.copyWith(folded: true) else s,
      ]);
      expect(LegalActionEngine.legalActionTypes(foldedState), isEmpty);
    });

    test('Caso E — héroe ya all-in: sin acciones', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      final utg = state.toActSlot!;
      final allInState = state.copyWith(seats: [
        for (final s in state.seats)
          if (s.slot == utg) s.copyWith(isAllIn: true) else s,
      ]);
      expect(LegalActionEngine.legalActionTypes(allInState), isEmpty);
    });
  });

  group('Auditoría sección 5 — CHECK', () {
    test('CHECK solo es legal cuando amountToCall == 0; enfrentando una '
        'apuesta, intentar CHECK lanza IllegalActionException', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      expect(LegalActionEngine.legalActionTypes(state).contains(ActionType.check),
          isFalse);
      expect(
        () => ActionResolver.apply(state, const PokerAction(ActionType.check)),
        throwsA(isA<IllegalActionException>()),
      );
    });
  });

  group('Auditoría sección 10 — un jugador "capado" no puede subir', () {
    test('un slot en cannotReraiseSlots solo tiene fold/call disponibles, '
        'aunque su stack alcance para un raise completo', () {
      final base = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      final utg = base.toActSlot!;
      final capped = base.copyWith(
        round: base.round.copyWith(cannotReraiseSlots: {utg}),
      );
      expect(LegalActionEngine.legalActionTypes(capped),
          {ActionType.fold, ActionType.call});
    });
  });
}

/// Lleva un heads-up (2 jugadores activos, el resto sitting-out) hasta el
/// flop con currentBet en 0 de verdad — para probar el Caso A sin el
/// matiz de "la BB ya iguala con su propia ciega". buttonSlot=2 pone a
/// SB=slot1 y BB=slot0 (`TablePositions(2)`), ambos entre los únicos dos
/// asientos activos.
GameState _headsUpToFlop() {
  final seats = [
    for (var slot = 0; slot < 6; slot++)
      PlayerState(slot: slot, stackBb: 100, sittingOut: slot > 1),
  ];
  var state = GameState.newHand(
    buttonSlot: 2,
    seats: seats,
    remainingDeckCards: const [
      Card(Rank.two, Suit.clubs),
      Card(Rank.three, Suit.clubs),
      Card(Rank.four, Suit.clubs),
    ],
  );
  while (!state.isStreetComplete) {
    final legal = LegalActionEngine.legalActionTypes(state);
    final type = legal.contains(ActionType.call) ? ActionType.call : ActionType.check;
    state = ActionResolver.apply(state, PokerAction(type));
  }
  return ActionResolver.advanceStreet(state);
}

GameState _callAction(GameState state) =>
    ActionResolver.apply(state, const PokerAction(ActionType.call));

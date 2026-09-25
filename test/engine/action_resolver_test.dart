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

/// 52 cartas fijas en un orden arbitrario pero determinístico, suficientes
/// para repartir 5 calles completas (flop+turn+river = 5 cartas).
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

void main() {
  group('ActionResolver.apply — reglas básicas', () {
    test('rechaza una acción de quien no está en turno / no es legal', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      // UTG no puede "check" enfrentando la ciega grande sin igualar.
      expect(
        () => ActionResolver.apply(state, const PokerAction(ActionType.check)),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('un fold reduce a un solo activo y termina la mano', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      // Todos foldean menos la BB.
      final bbSlot = slotFor(Position.bb, 0);
      while (!state.isHandOver) {
        if (state.toActSlot == bbSlot) break;
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
      expect(state.isHandOver, isTrue);
      expect(state.winnerSlots, {bbSlot});
      expect(state.toActSlot, isNull);
    });

    test('bet fuera de rango lanza IllegalActionException', () {
      final bbSlot = slotFor(Position.bb, 0);
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      while (state.toActSlot != bbSlot) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      // La BB tiene check/bet legales; un bet de 0.1bb es menor al mínimo.
      expect(
        () => ActionResolver.apply(state, PokerAction.bet(0.1)),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('raise por debajo del mínimo lanza IllegalActionException', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      // minRaiseTo == 2bb; pedir 1.2bb no es un raise válido.
      expect(
        () => ActionResolver.apply(state, PokerAction.raiseTo(1.2)),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('advanceStreet antes de cerrar la calle lanza StateError', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      expect(() => ActionResolver.advanceStreet(state), throwsStateError);
    });

    test('advanceStreet después del river lanza StateError', () {
      final state = _runToRiverAllChecked(buttonSlot: 0);
      expect(state.street, Street.river);
      expect(state.isStreetComplete, isTrue);
      expect(() => ActionResolver.advanceStreet(state), throwsStateError);
    });
  });

  group('ActionResolver — una mano completa hasta showdown', () {
    test('todos calls preflop y checks postflop llegan a needsShowdown', () {
      final state = _runToRiverAllChecked(buttonSlot: 0);
      expect(state.needsShowdown, isTrue);
      expect(state.board.length, 5);
      expect(state.activeSlots.length, 6);
      expect(state.pot.totalBb, 6); // 6 jugadores x 1bb cada uno
    });

    test('el bote crece exactamente lo que cada jugador invierte', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: fixedDeckTail(),
      );
      // UTG sube a 3bb, el resto foldea menos la BB que paga.
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      while (state.toActSlot != slotFor(Position.bb, 0)) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
      state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      // 3 (UTG) + 3 (BB, con su ciega incluida) + 0.5 (SB, foldeada pero ya
      // invertida — el aporte forfeited de una ciega sigue yendo al bote).
      expect(state.pot.totalBb, 6.5);
      expect(state.isStreetComplete, isTrue);
    });
  });

  group('ActionResolver — determinismo', () {
    test('la misma secuencia de acciones sobre el mismo estado inicial da '
        'exactamente el mismo resultado', () {
      GameState build() => GameState.newHand(
            buttonSlot: 0,
            seats: sixSeats(),
            remainingDeckCards: fixedDeckTail(),
          );

      GameState playSequence(GameState state) {
        // call, call, call, call (limpian hasta la BB), BB check, avanzar
        // calle, check x6, avanzar calle, check x6.
        while (state.toActSlot != slotFor(Position.bb, 0)) {
          state = ActionResolver.apply(state, const PokerAction(ActionType.call));
        }
        state = ActionResolver.apply(state, const PokerAction(ActionType.check));
        state = ActionResolver.advanceStreet(state);
        for (var i = 0; i < 6; i++) {
          state = ActionResolver.apply(state, const PokerAction(ActionType.check));
        }
        return state;
      }

      final a = playSequence(build());
      final b = playSequence(build());

      expect(a.street, b.street);
      expect(a.board, b.board);
      expect(a.pot.totalBb, b.pot.totalBb);
      expect(a.toActSlot, b.toActSlot);
      for (var slot = 0; slot < 6; slot++) {
        expect(a.seatAt(slot).stackBb, b.seatAt(slot).stackBb, reason: 'slot $slot');
        expect(a.seatAt(slot).investedTotalBb, b.seatAt(slot).investedTotalBb,
            reason: 'slot $slot');
      }
    });
  });

  group('Auditoría sección 6 — CALL cobra lo que falta, no currentBet a secas',
      () {
    test('BB (con 1bb ya invertido) enfrentando un raise a 3bb paga 2bb, '
        'no 3bb', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: fixedDeckTail(),
      );
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      while (state.toActSlot != slotFor(Position.bb, 0)) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
      final bbSlot = slotFor(Position.bb, 0);
      final bbBefore = state.seatAt(bbSlot);
      expect(bbBefore.investedThisStreetBb, 1); // ya invirtió su ciega
      expect(bbBefore.stackBb, 99);

      state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      final bbAfter = state.seatAt(bbSlot);
      expect(bbAfter.stackBb, 97, reason: 'debe pagar 2bb (3-1), no 3bb');
      expect(bbAfter.investedThisStreetBb, 3);
      expect(bbAfter.investedTotalBb, 3);
    });

    test('call sin nada que igualar (owed <= 0) no es una acción legal', () {
      final bbSlot = slotFor(Position.bb, 0);
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      while (state.toActSlot != bbSlot) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      // La BB no tiene nada que igualar (currentBet == su propia ciega).
      expect(
        () => ActionResolver.apply(state, const PokerAction(ActionType.call)),
        throwsA(isA<IllegalActionException>()),
      );
    });
  });

  group('Auditoría sección 7 — BET', () {
    test('una apuesta de apertura real (postflop, currentBet en 0) deja '
        'currentBet/lastAggressor/minRaiseIncrement correctos', () {
      var state = _headsUpFlop();
      final actor = state.toActSlot!;
      state = ActionResolver.apply(state, PokerAction.bet(4));
      expect(state.round.currentBetBb, 4);
      expect(state.round.lastAggressorSlot, actor);
      expect(state.round.minRaiseIncrementBb, 4);
    });

    test(
        'la BB "apostando" tras limpers no es una apertura a 0: el piso es '
        'currentBet + minRaiseIncrement, no minRaiseIncrement a secas '
        '(bug encontrado en la auditoría, ya corregido)', () {
      final bbSlot = slotFor(Position.bb, 0);
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      while (state.toActSlot != bbSlot) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      // currentBet=1, minRaiseIncrement=1 → el mínimo real para "subir"
      // es 1+1=2, no 1. Un bet(1.5) debe rechazarse.
      expect(
        () => ActionResolver.apply(state, PokerAction.bet(1.5)),
        throwsA(isA<IllegalActionException>()),
      );
      final afterRaise = ActionResolver.apply(state, PokerAction.bet(3));
      expect(afterRaise.round.currentBetBb, 3);
      expect(afterRaise.round.minRaiseIncrementBb, 2); // 3 - 1
    });

    test('bet <= 0 lanza IllegalActionException', () {
      final state = _headsUpFlop();
      expect(() => ActionResolver.apply(state, PokerAction.bet(0)),
          throwsA(isA<IllegalActionException>()));
    });

    test('bet mayor al stack disponible lanza IllegalActionException', () {
      final state = _headsUpFlop();
      final actor = state.seatAt(state.toActSlot!);
      expect(
        () => ActionResolver.apply(
            state, PokerAction.bet(actor.stackBb + 50)),
        throwsA(isA<IllegalActionException>()),
      );
    });
  });

  group('Auditoría sección 8 — matemática exacta del raise increment', () {
    test('currentBet=2, Hero sube a 6 → increment=4 → el próximo mínimo '
        'es 10 (no 8 ni 12)', () {
      var state = _headsUpFlop();
      state = ActionResolver.apply(state, PokerAction.bet(2));
      state = ActionResolver.apply(state, PokerAction.raiseTo(6));
      expect(state.round.currentBetBb, 6);
      expect(state.round.minRaiseIncrementBb, 4);
      expect(LegalActionEngine.minRaiseToBb(state), 10);
    });

    test('raise justo al mínimo (10) es legal; 9.9 no lo es', () {
      var state = _headsUpFlop();
      state = ActionResolver.apply(state, PokerAction.bet(2));
      state = ActionResolver.apply(state, PokerAction.raiseTo(6));
      expect(
        () => ActionResolver.apply(state, PokerAction.raiseTo(9.9)),
        throwsA(isA<IllegalActionException>()),
      );
      final ok = ActionResolver.apply(state, PokerAction.raiseTo(10));
      expect(ok.round.currentBetBb, 10);
    });

    test('raise mayor al stack disponible lanza IllegalActionException', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final actor = state.seatAt(state.toActSlot!);
      expect(
        () => ActionResolver.apply(
            state, PokerAction.raiseTo(actor.stackBb + 50)),
        throwsA(isA<IllegalActionException>()),
      );
    });
  });

  group('Auditoría sección 9 — short all-in distinto de un raise completo',
      () {
    test('currentBet=10, Hero tiene 14bb en total: el all-in a 14 es legal '
        'pero el incremento (4) no llega al mínimo de ese momento', () {
      var state = _headsUpFlop();
      final heroSlot = state.toActSlot!;
      // Fuerzo currentBet=10 con minRaiseIncrement=10 (un bet de apertura
      // de 10) y a Hero con stack tal que investedThisStreet+stack==14.
      state = ActionResolver.apply(state, PokerAction.bet(10));
      final villainSlot = state.toActSlot!;
      final shortStack = state.copyWith(seats: [
        for (final s in state.seats)
          if (s.slot == villainSlot) s.copyWith(stackBb: 14) else s,
      ]);
      expect(shortStack.seatAt(villainSlot).investedThisStreetBb + 14, 14);

      final legal = LegalActionEngine.legalActionTypes(shortStack);
      expect(legal, {ActionType.fold, ActionType.call, ActionType.allIn},
          reason: '14 no alcanza para un raise completo (necesitaría 20)');

      final afterAllIn =
          ActionResolver.apply(shortStack, const PokerAction(ActionType.allIn));
      expect(afterAllIn.round.currentBetBb, 14);
      // El incremento (4) no llegó al mínimo (10): NO es un raise
      // completo, así que minRaiseIncrement no cambia.
      expect(afterAllIn.round.minRaiseIncrementBb, 10);
      // Y quien ya había actuado contra el nivel anterior (heroSlot, que
      // abrió el bet de 10) queda capado.
      expect(afterAllIn.round.cannotReraiseSlots, contains(heroSlot));
    });
  });

  group('Auditoría sección 10 — reapertura de la acción (caso crítico)', () {
    test(
        'A bets 2, B raises to 6 (completo), C va all-in a 8 (corto): B '
        'queda capado (solo fold/call), A NO queda capado (nunca respondió '
        'al raise de B), y quien todavía no actuó conserva el raise',
        () {
      // buttonSlot=0 → sb=5, bb=4, utg=3, hj=2, co=1, btn=0. Postflop
      // arranca en SB: orden SB,BB,UTG,HJ,CO,BTN.
      final sbSlot = slotFor(Position.sb, 0);
      final bbSlot = slotFor(Position.bb, 0);
      final utgSlot = slotFor(Position.utg, 0);
      final hjSlot = slotFor(Position.hj, 0);

      final seats = [
        for (var slot = 0; slot < 6; slot++)
          PlayerState(
            slot: slot,
            // UTG entra al flop con exactamente 8bb (9 iniciales - 1 de la
            // llamada preflop) para poder ir all-in a 8 justo.
            stackBb: slot == utgSlot ? 9 : 100,
          ),
      ];
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: seats,
        remainingDeckCards: fixedDeckTail(),
      );
      // Preflop: todos limpian, BB pasa su opción.
      while (state.toActSlot != bbSlot) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      state = ActionResolver.apply(state, const PokerAction(ActionType.check));
      state = ActionResolver.advanceStreet(state); // → flop, currentBet=0

      expect(state.toActSlot, sbSlot);
      state = ActionResolver.apply(state, PokerAction.bet(2)); // A
      expect(state.toActSlot, bbSlot);
      state = ActionResolver.apply(state, PokerAction.raiseTo(6)); // B, full
      expect(state.round.minRaiseIncrementBb, 4);
      expect(state.toActSlot, utgSlot);

      expect(state.seatAt(utgSlot).stackBb, 8);
      state = ActionResolver.apply(state, const PokerAction(ActionType.allIn)); // C, short
      expect(state.round.currentBetBb, 8);
      expect(state.round.minRaiseIncrementBb, 4, reason: 'short raise no sube el mínimo');
      expect(state.round.cannotReraiseSlots, {bbSlot},
          reason: 'B ya había actuado contra el nivel de 6; A todavía no '
              'había respondido al raise de B');

      // D (HJ) nunca actuó: conserva raise completo.
      expect(state.toActSlot, hjSlot);
      expect(LegalActionEngine.legalActionTypes(state), contains(ActionType.raise));

      // B (BB), si le tocara ahora, solo puede pagar o retirarse.
      final asIfBb = state.copyWith(toActSlot: bbSlot);
      expect(LegalActionEngine.legalActionTypes(asIfBb),
          {ActionType.fold, ActionType.call});

      // A (SB) NO está capado: nunca respondió al raise de B (a 6), así
      // que frente al nuevo nivel (8) todavía tiene derecho a resubir.
      final asIfSb = state.copyWith(toActSlot: sbSlot);
      expect(LegalActionEngine.legalActionTypes(asIfSb), contains(ActionType.raise));
    });
  });

  group('Auditoría sección 11 — action history reconstruible', () {
    test('el log de la calle registra slot y el total resuelto de cada '
        'acción, en orden, alcanza para reconstruir cada raise', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final utgSlot = state.toActSlot!;
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      final hjSlot = state.toActSlot!;
      state = ActionResolver.apply(state, const PokerAction(ActionType.fold));

      final log = state.round.log;
      expect(log.length, 2);
      expect(log[0].slot, utgSlot);
      expect(log[0].action.type, ActionType.raise);
      expect(log[0].action.sizeBb, 3);
      expect(log[1].slot, hjSlot);
      expect(log[1].action.type, ActionType.fold);
      expect(log[1].action.sizeBb, isNull);

      // Reconstrucción: el raise anterior a cada entrada es rastreable
      // reproduciendo el log en orden (acá, trivialmente: solo hay un
      // raise, currentBet pasa de 1 a 3).
      final totals = log
          .where((e) => e.action.sizeBb != null)
          .map((e) => e.action.sizeBb)
          .toList();
      expect(totals, [3]);
    });

    test('check y call también quedan en el log, con y sin tamaño', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final utgSlot = state.toActSlot!;
      state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      expect(state.round.log.last.slot, utgSlot);
      expect(state.round.log.last.action.type, ActionType.call);
      expect(state.round.log.last.action.sizeBb, 1);
    });
  });

  group('Auditoría sección 12 — transiciones de calle', () {
    test('advanceStreet resetea inversión de calle, currentBet, '
        'minRaise y actedSlots, pero preserva investedTotal y el pot', () {
      // Estado justo DESPUÉS de advanceStreet al flop, ANTES de que nadie
      // actúe todavía en la nueva calle — es ahí donde importa que el
      // reset haya pasado, no en un river ya jugado de punta a punta.
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      while (state.toActSlot != slotFor(Position.bb, 0)) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      state = ActionResolver.apply(state, const PokerAction(ActionType.check));
      final potBeforeAdvance = state.pot.totalBb;
      state = ActionResolver.advanceStreet(state);

      for (var slot = 0; slot < 6; slot++) {
        expect(state.seatAt(slot).investedThisStreetBb, 0,
            reason: 'slot $slot: la calle nueva arranca en 0');
        expect(state.seatAt(slot).investedTotalBb, 1,
            reason: 'slot $slot: lo invertido en preflop se preserva');
      }
      expect(state.round.currentBetBb, 0);
      expect(state.round.minRaiseIncrementBb, 1); // bigBlindBb
      expect(state.round.actedSlots, isEmpty);
      expect(state.round.cannotReraiseSlots, isEmpty);
      expect(state.pot.totalBb, potBeforeAdvance,
          reason: 'avanzar de calle no mueve fichas al bote');
    });

    test('preflop → flop → turn → river reparte exactamente 3, luego 1, '
        'luego 1 carta, nunca de más ni de menos', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      while (state.toActSlot != slotFor(Position.bb, 0)) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      state = ActionResolver.apply(state, const PokerAction(ActionType.check));
      expect(state.board.length, 0);

      state = ActionResolver.advanceStreet(state);
      expect(state.street, Street.flop);
      expect(state.board.length, 3);

      for (var i = 0; i < 6; i++) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.check));
      }
      state = ActionResolver.advanceStreet(state);
      expect(state.street, Street.turn);
      expect(state.board.length, 4);

      for (var i = 0; i < 6; i++) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.check));
      }
      state = ActionResolver.advanceStreet(state);
      expect(state.street, Street.river);
      expect(state.board.length, 5);
      expect(state.board.toSet().length, 5, reason: 'sin cartas repetidas');
    });
  });

  group('Auditoría sección 14 — pot por acción, sin doble contabilización',
      () {
    test('Hero que invierte 5 (bet) ve su stack bajar exactamente 5 y el '
        'pot subir exactamente 5 — ni un centavo más, ni menos', () {
      final state = _headsUpFlop();
      final heroSlot = state.toActSlot!;
      final stackBefore = state.seatAt(heroSlot).stackBb;
      final investedBefore = state.seatAt(heroSlot).investedTotalBb;
      final potBefore = state.pot.totalBb;

      final after = ActionResolver.apply(state, PokerAction.bet(5));

      expect(after.seatAt(heroSlot).stackBb, stackBefore - 5);
      expect(after.seatAt(heroSlot).investedThisStreetBb, 5);
      expect(after.seatAt(heroSlot).investedTotalBb, investedBefore + 5);
      expect(after.pot.totalBb, potBefore + 5);
    });

    test('un fold no reduce el pot: lo ya invertido por el que se retira '
        'queda adentro', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final potBefore = state.pot.totalBb;
      state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      expect(state.pot.totalBb, potBefore);
    });
  });

  group('Auditoría sección 15 — PotManager.eligibleSlots excluye foldeados',
      () {
    test('tras un fold, ese slot desaparece de eligibleSlots del bote', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final folder = state.toActSlot!;
      state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      expect(state.pot.pots.first.eligibleSlots, isNot(contains(folder)));
      expect(state.pot.pots.first.eligibleSlots.length, 5);
    });
  });

  group('Auditoría sección 18 — inmutabilidad', () {
    test('ActionResolver.apply no muta el GameState original', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final originalStack = state.seatAt(state.toActSlot!).stackBb;
      final originalToAct = state.toActSlot;
      final originalPot = state.pot.totalBb;

      final next = ActionResolver.apply(state, PokerAction.raiseTo(3));

      expect(identical(state, next), isFalse);
      expect(state.toActSlot, originalToAct, reason: 'el estado viejo no cambia');
      expect(state.seatAt(originalToAct!).stackBb, originalStack);
      expect(state.pot.totalBb, originalPot);
      expect(next.toActSlot, isNot(originalToAct));
    });

    test('advanceStreet no muta el GameState original', () {
      var closed = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      while (closed.toActSlot != slotFor(Position.bb, 0)) {
        closed = ActionResolver.apply(closed, const PokerAction(ActionType.call));
      }
      closed = ActionResolver.apply(closed, const PokerAction(ActionType.check));
      final boardBefore = closed.board;
      final streetBefore = closed.street;
      final roundBefore = closed.round;

      final next = ActionResolver.advanceStreet(closed);

      expect(closed.board, boardBefore);
      expect(closed.street, streetBefore);
      expect(closed.round, roundBefore);
      expect(next.street, isNot(streetBefore));
      expect(next.board.length, 3);
    });
  });

  group('Auditoría sección 19 — batería de acciones ilegales', () {
    test('acción de un slot foldeado lanza IllegalActionException', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final folder = state.toActSlot!;
      state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      // Fuerzo (de forma sintética) que le vuelva a tocar al que ya foldeó.
      final corrupted = state.copyWith(toActSlot: folder);
      expect(
        () => ActionResolver.apply(corrupted, const PokerAction(ActionType.fold)),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('acción de un slot ya all-in lanza IllegalActionException', () {
      // Stack corto para que ALL_IN sea de verdad la única forma de
      // seguir en mano (con stack profundo, "ir all-in" es legalmente un
      // RAISE de tamaño = stack, no el tipo ALL_IN — ver sección 21).
      final seats = sixSeats();
      final utgSlot = slotFor(Position.utg, 0);
      final shortSeats = [
        for (final s in seats)
          if (s.slot == utgSlot) s.copyWith(stackBb: 0.5) else s,
      ];
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: shortSeats,
        remainingDeckCards: fixedDeckTail(),
      );
      final actor = state.toActSlot!;
      expect(actor, utgSlot);
      state = ActionResolver.apply(state, const PokerAction(ActionType.allIn));
      expect(state.seatAt(actor).isAllIn, isTrue);
      final corrupted = state.copyWith(toActSlot: actor);
      expect(
        () => ActionResolver.apply(corrupted, const PokerAction(ActionType.check)),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('cualquier acción después de terminada la mano lanza '
        'IllegalActionException', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final bbSlot = slotFor(Position.bb, 0);
      while (!state.isHandOver) {
        if (state.toActSlot == bbSlot) break;
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
      expect(state.isHandOver, isTrue);
      expect(
        () => ActionResolver.apply(state, const PokerAction(ActionType.check)),
        throwsA(isA<IllegalActionException>()),
      );
    });
  });

  group('Auditoría sección 20 — terminación de la mano', () {
    test('Caso 1: todos menos uno foldean → termina inmediatamente', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      final bbSlot = slotFor(Position.bb, 0);
      // OJO: con 6 jugadores, el 5° fold (SB) ya deja a la BB como único
      // activo — la mano termina ahí mismo, SIN que le llegue el turno a
      // la BB. El loop tiene que cortar por `isHandOver`, no por
      // "hasta que le toque a la BB" (ese turno puede no llegar nunca).
      while (!state.isHandOver) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
      expect(state.isHandOver, isTrue);
      expect(state.winnerSlots, {bbSlot});
      expect(state.toActSlot, isNull);
    });

    test('Caso 2: todos los que quedan van all-in → el motor avanza las '
        'calles necesarias sin pedir ninguna decisión más, hasta el '
        'showdown pendiente', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 5),
        remainingDeckCards: fixedDeckTail(),
      );
      // Fuerzo que todos empujen su stack entero, sea cual sea el tipo de
      // acción legal que les toque (ALL_IN si el stack no da para un
      // raise completo, o un RAISE/BET de tamaño = stack si sí da).
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
      }
      expect(state.isStreetComplete, isTrue);
      expect(state.toActSlot, isNull);
      expect(state.seats.where((s) => s.isActive).every((s) => s.isAllIn), isTrue,
          reason: 'todos los que siguen en mano quedaron all-in');

      var guard = 0;
      while (state.street != Street.river) {
        state = ActionResolver.advanceStreet(state);
        expect(state.toActSlot, isNull,
            reason: 'nadie puede actuar: todos están all-in');
        guard++;
        expect(guard, lessThan(10), reason: 'no debería hacer falta más de 3 saltos');
      }
      expect(state.board.length, 5);
      expect(state.needsShowdown, isTrue);
    });
  });

  group('Auditoría sección 21 — ActionType.allIn tiene semántica real', () {
    test('un all-in que no supera currentBet se resuelve como un call '
        'corto: no sube nada, no reabre nada', () {
      var state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: fixedDeckTail(),
      );
      state = ActionResolver.apply(state, PokerAction.raiseTo(10));
      final shortStackSlot = state.toActSlot!;
      final shortState = state.copyWith(seats: [
        for (final s in state.seats)
          if (s.slot == shortStackSlot) s.copyWith(stackBb: 5) else s,
      ]);
      final before = shortState.round.currentBetBb;
      final investedBefore = shortState.seatAt(shortStackSlot).investedThisStreetBb;
      final after =
          ActionResolver.apply(shortState, const PokerAction(ActionType.allIn));
      expect(after.round.currentBetBb, before, reason: 'call corto: no sube');
      expect(after.seatAt(shortStackSlot).investedThisStreetBb, investedBefore + 5);
      expect(after.round.cannotReraiseSlots, isEmpty,
          reason: 'un call corto no capa a nadie');
    });
  });
}

/// Lleva una mano de 6 jugadores hasta el flop (call-around preflop, BB
/// pasa su opción) para tener un estado con `currentBet == 0` de verdad
/// (no el caso particular de la BB ya matcheando su propia ciega) y a
/// alguien listo para abrir la acción.
GameState _headsUpFlop() {
  var state = GameState.newHand(
    buttonSlot: 0,
    seats: sixSeats(),
    remainingDeckCards: fixedDeckTail(),
  );
  while (state.toActSlot != slotFor(Position.bb, 0)) {
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));
  }
  state = ActionResolver.apply(state, const PokerAction(ActionType.check));
  return ActionResolver.advanceStreet(state);
}

/// Juega una mano entera con call-around preflop y check-around en cada
/// calle postflop, hasta llegar al river con la calle cerrada.
GameState _runToRiverAllChecked({required int buttonSlot}) {
  var state = GameState.newHand(
    buttonSlot: buttonSlot,
    seats: sixSeats(),
    remainingDeckCards: fixedDeckTail(),
  );
  final bbSlot = slotFor(Position.bb, buttonSlot);
  while (state.toActSlot != bbSlot) {
    state = ActionResolver.apply(state, const PokerAction(ActionType.call));
  }
  state = ActionResolver.apply(state, const PokerAction(ActionType.check));

  while (state.street != Street.river || !state.isStreetComplete) {
    if (state.isStreetComplete) {
      state = ActionResolver.advanceStreet(state);
      continue;
    }
    state = ActionResolver.apply(state, const PokerAction(ActionType.check));
  }
  return state;
}

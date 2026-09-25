import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/game/player_state.dart';

/// 6 asientos activos con el mismo stack, sin cartas repartidas (no hacen
/// falta para probar bookkeeping de pot/turnos).
List<PlayerState> sixSeats({double stackBb = 100}) => [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(slot: slot, stackBb: stackBb),
    ];

void main() {
  group('GameState.newHand — postea ciegas correctamente', () {
    test('SB y BB quedan con el stack descontado y su aporte registrado',
        () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(stackBb: 100),
        remainingDeckCards: const [],
      );
      final positions = state.positionOf;
      final sbSlot =
          [for (var s = 0; s < 6; s++) s].firstWhere((s) => positions(s) == Position.sb);
      final bbSlot =
          [for (var s = 0; s < 6; s++) s].firstWhere((s) => positions(s) == Position.bb);

      expect(state.seatAt(sbSlot).stackBb, 99.5);
      expect(state.seatAt(sbSlot).investedThisStreetBb, 0.5);
      expect(state.seatAt(bbSlot).stackBb, 99);
      expect(state.seatAt(bbSlot).investedThisStreetBb, 1);
      // El resto no aportó nada todavía.
      for (var s = 0; s < 6; s++) {
        if (s == sbSlot || s == bbSlot) continue;
        expect(state.seatAt(s).stackBb, 100);
        expect(state.seatAt(s).investedThisStreetBb, 0);
      }
    });

    test('el bote inicial es exactamente SB + BB', () {
      final state = GameState.newHand(
        buttonSlot: 2,
        seats: sixSeats(),
        remainingDeckCards: const [],
      );
      expect(state.pot.totalBb, 1.5);
    });

    test('un stack más corto que la ciega postea all-in por lo que tiene',
        () {
      final seats = sixSeats();
      final bbSlot = TablePositions(0).slotOf(Position.bb);
      final shortSeats = [
        for (final s in seats)
          if (s.slot == bbSlot) s.copyWith(stackBb: 0.4) else s,
      ];
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: shortSeats,
        remainingDeckCards: const [],
      );
      expect(state.seatAt(bbSlot).stackBb, 0);
      expect(state.seatAt(bbSlot).investedThisStreetBb, 0.4);
      expect(state.seatAt(bbSlot).isAllIn, isTrue);
    });

    test('el primero en actuar preflop es siempre UTG', () {
      for (var btn = 0; btn < 6; btn++) {
        final state = GameState.newHand(
          buttonSlot: btn,
          seats: sixSeats(),
          remainingDeckCards: const [],
        );
        expect(state.positionOf(state.toActSlot!), Position.utg,
            reason: 'buttonSlot=$btn');
      }
    });

    test(
        'SB/BB/pot/currentBet/current player quedan correctos para las 6 '
        'posiciones posibles del botón — sin asumir "button + 1", '
        'delegando en TablePositions', () {
      for (var btn = 0; btn < 6; btn++) {
        final state = GameState.newHand(
          buttonSlot: btn,
          seats: sixSeats(stackBb: 100),
          remainingDeckCards: const [],
        );
        final sbSlot = TablePositions(btn).slotOf(Position.sb);
        final bbSlot = TablePositions(btn).slotOf(Position.bb);
        final utgSlot = TablePositions(btn).slotOf(Position.utg);

        expect(state.seatAt(sbSlot).stackBb, 99.5, reason: 'btn=$btn SB stack');
        expect(state.seatAt(sbSlot).investedThisStreetBb, 0.5,
            reason: 'btn=$btn SB invested');
        expect(state.seatAt(sbSlot).investedTotalBb, 0.5,
            reason: 'btn=$btn SB investedTotal');
        expect(state.seatAt(bbSlot).stackBb, 99, reason: 'btn=$btn BB stack');
        expect(state.seatAt(bbSlot).investedThisStreetBb, 1,
            reason: 'btn=$btn BB invested');
        expect(state.seatAt(bbSlot).investedTotalBb, 1,
            reason: 'btn=$btn BB investedTotal');
        expect(state.pot.totalBb, 1.5, reason: 'btn=$btn pot');
        expect(state.round.currentBetBb, 1, reason: 'btn=$btn currentBet');
        expect(state.toActSlot, utgSlot, reason: 'btn=$btn current player');
      }
    });

    test('rechaza una lista de asientos que no tenga exactamente 6', () {
      expect(
        () => GameState.newHand(
          buttonSlot: 0,
          seats: sixSeats().sublist(0, 5),
          remainingDeckCards: const [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('GameState — derivados', () {
    test('positionOf es consistente con TablePositions', () {
      final state = GameState.newHand(
        buttonSlot: 4,
        seats: sixSeats(),
        remainingDeckCards: const [],
      );
      expect(state.positionOf(4), Position.btn);
    });

    test('isStreetComplete es falso apenas empieza la mano (UTG no actuó)',
        () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: const [],
      );
      expect(state.isStreetComplete, isFalse);
    });

    test('isHandOver es falso mientras no haya winnerSlots', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: const [],
      );
      expect(state.isHandOver, isFalse);
    });

    test('needsShowdown es falso fuera del river', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: const [],
      );
      expect(state.needsShowdown, isFalse);
    });
  });

  group('GameState.copyWith', () {
    test('preserva buttonSlot y bigBlindBb sin pedirlos de nuevo', () {
      final state = GameState.newHand(
        buttonSlot: 1,
        seats: sixSeats(),
        remainingDeckCards: const [Card(Rank.ace, Suit.spades)],
      );
      final copy = state.copyWith(toActSlot: 3);
      expect(copy.buttonSlot, 1);
      expect(copy.bigBlindBb, 1);
      expect(copy.toActSlot, 3);
    });

    test('street y round.street deben coincidir: cambiar una sin la otra '
        'es un estado imposible y se rechaza', () {
      final state = GameState.newHand(
        buttonSlot: 1,
        seats: sixSeats(),
        remainingDeckCards: const [Card(Rank.ace, Suit.spades)],
      );
      expect(() => state.copyWith(street: Street.flop), throwsArgumentError);
    });

    test('clearToActSlot fuerza null incluso si se pasa toActSlot', () {
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: const [],
      );
      final copy = state.copyWith(clearToActSlot: true);
      expect(copy.toActSlot, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/game/betting_round.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/game/player_state.dart';
import 'package:poker_trainer/engine/poker/game/pot_manager.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/street.dart';

/// Auditoría — sección 2: "Comprobá que no existan estados imposibles."
///
/// Estos tests construyen `GameState`/`PlayerState`/`Pot` directamente
/// (no vía `newHand`/`ActionResolver`) para probar que el propio
/// constructor rechaza cada forma de estado imposible, en vez de confiar
/// en que los callers "se porten bien".
void main() {
  List<PlayerState> sixSeats({double stackBb = 100}) => [
        for (var slot = 0; slot < 6; slot++)
          PlayerState(slot: slot, stackBb: stackBb),
      ];

  GameState validBase() => GameState.newHand(
        buttonSlot: 0,
        seats: sixSeats(),
        remainingDeckCards: const [],
      );

  group('PlayerState — invariantes', () {
    test('stack negativo lanza ArgumentError', () {
      expect(() => PlayerState(slot: 0, stackBb: -1), throwsArgumentError);
    });

    test('investedThisStreetBb negativo lanza ArgumentError', () {
      expect(
        () => PlayerState(slot: 0, stackBb: 100, investedThisStreetBb: -1),
        throwsArgumentError,
      );
    });

    test('investedTotalBb negativo lanza ArgumentError', () {
      expect(
        () => PlayerState(slot: 0, stackBb: 100, investedTotalBb: -1),
        throwsArgumentError,
      );
    });

    test(
        'investedThisStreetBb no puede superar investedTotalBb (plata '
        'que "aparece" de la nada en la calle actual)', () {
      expect(
        () => PlayerState(
          slot: 0,
          stackBb: 100,
          investedThisStreetBb: 5,
          investedTotalBb: 2,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Pot — invariantes', () {
    test('un bote negativo lanza ArgumentError', () {
      expect(() => Pot(amountBb: -1, eligibleSlots: const {0, 1}),
          throwsArgumentError);
    });
  });

  group('GameState — forma de los asientos', () {
    test('menos de 6 asientos lanza ArgumentError', () {
      final seats = sixSeats().sublist(0, 5);
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: seats,
          street: Street.preflop,
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.preflop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });

    test('un asiento en el índice equivocado (slot != índice) lanza '
        'ArgumentError', () {
      final seats = sixSeats();
      final shuffled = [seats[1], seats[0], ...seats.sublist(2)];
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: shuffled,
          street: Street.preflop,
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.preflop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });

    test('buttonSlot fuera de 0..5 lanza ArgumentError', () {
      expect(
        () => GameState(
          buttonSlot: 6,
          seats: sixSeats(),
          street: Street.preflop,
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.preflop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('GameState — coherencia street / board', () {
    test('street y round.street inconsistentes lanza ArgumentError', () {
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: sixSeats(),
          street: Street.flop,
          board: const [
            Card(Rank.two, Suit.clubs),
            Card(Rank.three, Suit.clubs),
            Card(Rank.four, Suit.clubs),
          ],
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.preflop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });

    test('board con menos cartas de las que pide la calle: flop con 4 '
        'lanza ArgumentError', () {
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: sixSeats(),
          street: Street.flop,
          board: const [
            Card(Rank.two, Suit.clubs),
            Card(Rank.three, Suit.clubs),
            Card(Rank.four, Suit.clubs),
            Card(Rank.five, Suit.clubs),
          ],
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.flop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });

    test('preflop con board no vacío lanza ArgumentError', () {
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: sixSeats(),
          street: Street.preflop,
          board: const [Card(Rank.two, Suit.clubs)],
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.preflop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('GameState — unicidad de cartas', () {
    test('dos jugadores con la misma carta en la mano lanza ArgumentError',
        () {
      const ace = Card(Rank.ace, Suit.spades);
      final seats = sixSeats();
      final withDupes = [
        seats[0].copyWith(holeCards: HoleCards(ace, const Card(Rank.king, Suit.hearts))),
        seats[1].copyWith(holeCards: HoleCards(ace, const Card(Rank.queen, Suit.hearts))),
        ...seats.sublist(2),
      ];
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: withDupes,
          street: Street.preflop,
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.preflop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });

    test('una carta del board repetida en la mano de un jugador lanza '
        'ArgumentError', () {
      const ace = Card(Rank.ace, Suit.spades);
      final seats = sixSeats();
      final withHole = [
        seats[0].copyWith(holeCards: HoleCards(ace, const Card(Rank.king, Suit.hearts))),
        ...seats.sublist(1),
      ];
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: withHole,
          street: Street.flop,
          board: [ace, const Card(Rank.two, Suit.clubs), const Card(Rank.three, Suit.clubs)],
          remainingDeckCards: const [],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.flop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });

    test('el mazo restante con una carta repetida respecto al board lanza '
        'ArgumentError', () {
      const two = Card(Rank.two, Suit.clubs);
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: sixSeats(),
          street: Street.flop,
          board: [two, const Card(Rank.three, Suit.clubs), const Card(Rank.four, Suit.clubs)],
          remainingDeckCards: [two],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.flop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });

    test('el mazo restante con dos copias de la misma carta lanza '
        'ArgumentError', () {
      const two = Card(Rank.two, Suit.clubs);
      expect(
        () => GameState(
          buttonSlot: 0,
          seats: sixSeats(),
          street: Street.preflop,
          remainingDeckCards: [two, two],
          pot: PotManager.fromInvestments({}, activeSlots: const {}),
          bigBlindBb: 1,
          round: BettingRound(street: Street.preflop, minRaiseIncrementBb: 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('GameState — un estado válido no lanza nada de lo anterior', () {
    test('newHand produce un estado que pasa todos los chequeos', () {
      expect(validBase, returnsNormally);
    });
  });
}

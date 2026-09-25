import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/decision_context.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/player_state.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';

List<PlayerState> sixSeats({double stackBb = 100}) => [
      for (var slot = 0; slot < 6; slot++)
        PlayerState(slot: slot, stackBb: stackBb),
    ];

int slotFor(Position position, int buttonSlot) =>
    TablePositions(buttonSlot).slotOf(position);

void main() {
  group('DecisionContext.fromGameState — recién arranca la mano', () {
    test('deriva posición, street, mano, pot, stack y acciones legales '
        'correctos para UTG', () {
      final utgSlot = slotFor(Position.utg, 0);
      final hand = HoleCards.parse('AsKd');
      final seats = sixSeats();
      final withHand = [
        for (final s in seats) if (s.slot == utgSlot) s.copyWith(holeCards: hand) else s,
      ];
      final state = GameState.newHand(
        buttonSlot: 0,
        seats: withHand,
        remainingDeckCards: const [],
      );

      final context = DecisionContext.fromGameState(state, heroSlot: utgSlot);

      expect(context.heroSlot, utgSlot);
      expect(context.heroPosition, Position.utg);
      expect(context.street.name, 'preflop');
      expect(context.heroCards, hand);
      expect(context.board, isEmpty);
      expect(context.actionHistory, isEmpty);
      expect(context.lastActingSlot, isNull);
      expect(context.currentBetBb, 1);
      expect(context.toCallBb, 1);
      expect(context.potBb, 1.5);
      expect(context.effectiveStackBb, 100);
      expect(context.legalActions, {ActionType.fold, ActionType.call, ActionType.raise});
      expect(context.minRaiseToBb, 2);
      expect(context.maxRaiseToBb, 100);
    });
  });

  group('DecisionContext.fromGameState — mid-calle, con historial real', () {
    test('refleja la subida previa y quién actuó último', () {
      final utgSlot = slotFor(Position.utg, 0);
      final bbSlot = slotFor(Position.bb, 0);
      final seats = sixSeats();
      final withHands = [
        for (final s in seats)
          if (s.slot == bbSlot) s.copyWith(holeCards: HoleCards.parse('7c2d')) else s,
      ];
      var state = GameState.newHand(buttonSlot: 0, seats: withHands, remainingDeckCards: const []);
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      while (state.toActSlot != bbSlot) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }

      final context = DecisionContext.fromGameState(state, heroSlot: bbSlot);

      expect(context.heroPosition, Position.bb);
      expect(context.currentBetBb, 3);
      expect(context.toCallBb, 2); // 3 - 1 (ciega ya puesta)
      expect(context.actionHistory, isNotEmpty);
      expect(context.actionHistory.first.slot, utgSlot);
      expect(context.actionHistory.first.action.type, ActionType.raise);
      expect(context.lastActingSlot, context.actionHistory.last.slot);
      expect(context.legalActions, {ActionType.fold, ActionType.call, ActionType.raise});
    });
  });

  group('DecisionContext.fromGameState — stack corto', () {
    test('sin acciones agresivas legales, minRaiseToBb es null', () {
      final utgSlot = slotFor(Position.utg, 0);
      final seats = sixSeats();
      final shortSeats = [
        for (final s in seats)
          if (s.slot == utgSlot)
            s.copyWith(stackBb: 0.5, holeCards: HoleCards.parse('AsKd'))
          else
            s,
      ];
      final state = GameState.newHand(buttonSlot: 0, seats: shortSeats, remainingDeckCards: const []);
      final context = DecisionContext.fromGameState(state, heroSlot: utgSlot);

      expect(context.legalActions, {ActionType.fold, ActionType.allIn});
      expect(context.minRaiseToBb, isNull);
      expect(context.maxRaiseToBb, isNotNull);
    });
  });

  group('DecisionContext.fromGameState — falla explícita', () {
    test('lanza StateError si no es el turno del slot pedido', () {
      final state = GameState.newHand(buttonSlot: 0, seats: sixSeats(), remainingDeckCards: const []);
      final wrongSlot = slotFor(Position.bb, 0);
      expect(() => DecisionContext.fromGameState(state, heroSlot: wrongSlot), throwsStateError);
    });

    test('lanza StateError si el héroe no tiene una mano conocida', () {
      final utgSlot = slotFor(Position.utg, 0);
      final state = GameState.newHand(buttonSlot: 0, seats: sixSeats(), remainingDeckCards: const []);
      expect(state.seatAt(utgSlot).holeCards, isNull);
      expect(() => DecisionContext.fromGameState(state, heroSlot: utgSlot), throwsStateError);
    });
  });
}

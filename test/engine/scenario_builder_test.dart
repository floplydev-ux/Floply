import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/scenario_builder.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';

void main() {
  group('ScenarioBuilder.freshHand — manos explícitas y sampleadas', () {
    test('una mano explícita para un slot se respeta exactamente', () {
      final hand = HoleCards.parse('AsKs');
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {3: hand},
      );
      expect(state.seatAt(3).holeCards, hand);
    });

    test('una mano sampleada de un rango siempre pertenece a ese rango', () {
      final range = OpeningRanges.forPosition(Position.utg);
      for (var seed = 0; seed < 20; seed++) {
        final utgSlot = TablePositions(0).slotOf(Position.utg);
        final state = ScenarioBuilder.freshHand(
          deck: Deck(Random(seed)),
          buttonSlot: 0,
          rangeBySlot: {utgSlot: range},
        );
        final hand = state.seatAt(utgSlot).holeCards!;
        expect(range.contains(hand.notation), isTrue,
            reason: 'seed=$seed dio ${hand.notation}');
      }
    });

    test('la mano explícita gana si el mismo slot también tiene rango '
        'asignado', () {
      final hand = HoleCards.parse('2c2d');
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {3: hand},
        rangeBySlot: {3: OpeningRanges.forPosition(Position.utg)},
      );
      expect(state.seatAt(3).holeCards, hand);
    });

    test('un slot activo sin rango ni mano explícita queda con cartas '
        'ocultas', () {
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {3: HoleCards.parse('AsKs')},
      );
      for (var slot = 0; slot < 6; slot++) {
        if (slot == 3) continue;
        expect(state.seatAt(slot).holeCards, isNull, reason: 'slot $slot');
      }
    });
  });

  group('ScenarioBuilder.freshHand — asientos vacíos', () {
    test('un slot sitting-out queda fuera de la rotación de turno', () {
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        sittingOutSlots: {1, 2}, // CO, HJ afuera
      );
      expect(state.emptySlots, {1, 2});
      expect(state.toActSlot, isNot(anyOf(1, 2)));
      // Nadie foldea todavía, pero un sitting-out tampoco es "activo".
      expect(state.activeSlots.contains(1), isFalse);
      expect(state.activeSlots.contains(2), isFalse);
    });

    test('pedir una mano para un slot sitting-out es un error de uso', () {
      expect(
        () => ScenarioBuilder.freshHand(
          deck: Deck(Random(1)),
          buttonSlot: 0,
          sittingOutSlots: {3},
          explicitHandBySlot: {3: HoleCards.parse('AsKs')},
        ),
        throwsArgumentError,
      );
    });
  });

  group('ScenarioBuilder.freshHand — stacks', () {
    test('stackBb aplica a todos, stackOverridesBb pisa un slot puntual', () {
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        stackBb: 100,
        stackOverridesBb: {3: 40},
      );
      final bbSlot = TablePositions(0).slotOf(Position.bb);
      final sbSlot = TablePositions(0).slotOf(Position.sb);
      expect(state.seatAt(3).stackBb, 40 - (3 == bbSlot ? 1 : 3 == sbSlot ? 0.5 : 0));
      for (var slot = 0; slot < 6; slot++) {
        if (slot == 3) continue;
        final expectedBase =
            slot == bbSlot ? 99.0 : (slot == sbSlot ? 99.5 : 100.0);
        expect(state.seatAt(slot).stackBb, expectedBase, reason: 'slot $slot');
      }
    });
  });

  group('ScenarioBuilder.freshHand — sin cartas repetidas', () {
    test('las manos de todos los slots activos, entre sí y contra el resto '
        'del mazo, nunca se repiten', () {
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(3)),
        buttonSlot: 0,
        rangeBySlot: {
          0: OpeningRanges.forPosition(Position.btn),
          1: OpeningRanges.forPosition(Position.co),
          2: OpeningRanges.forPosition(Position.hj),
          3: OpeningRanges.forPosition(Position.utg),
        },
      );
      final allCards = [
        for (final s in state.seats) ...?s.holeCards?.cards,
        ...state.remainingDeckCards,
      ];
      expect(allCards.length, 8 + 44); // 4 manos (8 cartas) + resto del mazo
      expect(allCards.toSet().length, allCards.length);
    });
  });

  group('ScenarioBuilder.freshHand — determinismo', () {
    test('la misma semilla da exactamente el mismo escenario', () {
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(77)),
        buttonSlot: 2,
        rangeBySlot: {0: OpeningRanges.forPosition(Position.btn)},
      );
      var other = ScenarioBuilder.freshHand(
        deck: Deck(Random(77)),
        buttonSlot: 2,
        rangeBySlot: {0: OpeningRanges.forPosition(Position.btn)},
      );
      expect(state.seatAt(0).holeCards, other.seatAt(0).holeCards);
      expect(state.remainingDeckCards, other.remainingDeckCards);
      expect(state.toActSlot, other.toActSlot);
      expect(state.pot.totalBb, other.pot.totalBb);
    });
  });

  group('ScenarioBuilder.freshHand — el escenario resultante es jugable', () {
    test('se puede jugar de verdad con ActionResolver/LegalActionEngine, '
        'sin ningún ajuste especial', () {
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(5)),
        buttonSlot: 0,
        rangeBySlot: {
          3: OpeningRanges.forPosition(Position.utg),
        },
      );
      final utgSlot = TablePositions(0).slotOf(Position.utg);
      expect(state.toActSlot, utgSlot);

      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      while (!state.isStreetComplete && !state.isHandOver) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
      expect(state.isStreetComplete || state.isHandOver, isTrue);
    });
  });
}

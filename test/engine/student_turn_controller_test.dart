import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/student_turn_controller.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';

void main() {
  group('StudentTurnController — legalActions nunca reinventadas', () {
    test('coincide exactamente con LegalActionEngine.legalActionTypes', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      final controller = StudentTurnController(scenario);
      expect(controller.legalActions, LegalActionEngine.legalActionTypes(scenario.initialState));
      expect(controller.minRaiseToBb, LegalActionEngine.minRaiseToBb(scenario.initialState));
      expect(controller.maxRaiseToBb, LegalActionEngine.maxRaiseToBb(scenario.initialState));
    });
  });

  group('StudentTurnController.applyHeroAction — acción legal', () {
    test('produce exactamente el mismo GameState que aplicar la acción '
        'directo con ActionResolver', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(2)));
      final controller = StudentTurnController(scenario);
      final action = PokerAction.raiseTo(controller.minRaiseToBb!);

      final viaController = controller.applyHeroAction(action);
      final viaResolverDirect = ActionResolver.apply(scenario.initialState, action);

      expect(viaController.seats.map((s) => s.stackBb), viaResolverDirect.seats.map((s) => s.stackBb));
      expect(viaController.pot.totalBb, viaResolverDirect.pot.totalBb);
      expect(viaController.round.currentBetBb, viaResolverDirect.round.currentBetBb);
      expect(viaController.toActSlot, viaResolverDirect.toActSlot);
      expect(viaController.round.log.length, viaResolverDirect.round.log.length);
      expect(controller.state, viaController, reason: 'el controller queda apuntando al nuevo estado');
    });

    test('stack, pot, investedThisStreet y currentBet cambian de verdad', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(3)));
      final controller = StudentTurnController(scenario);
      final heroBefore = scenario.initialState.seatAt(scenario.heroSlot);
      final potBefore = scenario.initialState.pot.totalBb;

      final action = PokerAction.raiseTo(controller.minRaiseToBb!);
      final after = controller.applyHeroAction(action);
      final heroAfter = after.seatAt(scenario.heroSlot);

      expect(heroAfter.stackBb, lessThan(heroBefore.stackBb));
      expect(heroAfter.investedThisStreetBb, action.sizeBb);
      expect(after.round.currentBetBb, action.sizeBb);
      expect(after.pot.totalBb, greaterThan(potBefore));
      expect(after.toActSlot, isNot(scenario.heroSlot));
    });
  });

  group('StudentTurnController.applyHeroAction — acción ilegal', () {
    test('se rechaza, no muta el estado y no produce ninguna evaluación', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(4)));
      final controller = StudentTurnController(scenario);
      final before = controller.state;

      // CHECK nunca es legal para el primero en hablar preflop (siempre
      // enfrenta, como mínimo, la ciega grande).
      expect(controller.legalActions.contains(ActionType.check), isFalse);
      expect(
        () => controller.applyHeroAction(const PokerAction(ActionType.check)),
        throwsA(isA<IllegalActionException>()),
      );
      expect(controller.state, same(before), reason: 'el estado no debe cambiar tras un intento ilegal');
    });
  });
}

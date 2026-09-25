import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_strategy.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/preflop_authoring.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

void main() {
  group('ShortStackStrategy (vía PreflopStrategy.forDecision) — BB a ~8bb '
      'vs CO', () {
    test('mano del rango de empuje (AJo): shove óptimo/jamValue, fold '
        'malo, call dudoso/dependiente', () {
      final scenario = ExerciseScenarioBuilder.shortStackFacingOpen(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('AsJd'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final shove = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(shove.rating, StrategicRating.optimal);
      expect(shove.role, StrategyRole.jamValue);
      expect(shove.rationaleKey, 'short_stack.shove.value');
      // Empujar es literalmente jugarse todo el stack.
      expect(shove.action.sizeBb, LegalActionEngine.maxRaiseToBb(scenario.initialState));

      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.rating, StrategicRating.dubious);
      expect(call.contextSensitivity.isDependent, isTrue);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(fold.rating, StrategicRating.bad);

      final result = AnswerEvaluator.evaluate(scenario, shove.action);
      expect(result.verdict, AnswerVerdict.best);
    });

    test('mano fuera del rango de empuje (72o): fold óptimo, shove y call '
        'malos', () {
      final scenario = ExerciseScenarioBuilder.shortStackFacingOpen(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('7c2d'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(fold.rating, StrategicRating.optimal);
      expect(fold.role, StrategyRole.fold);

      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.fold));
      expect(result.verdict, AnswerVerdict.best);

      final shoveResult = AnswerEvaluator.evaluate(
        scenario,
        strategy.options.firstWhere((o) => o.action.type == ActionType.raise).action,
      );
      expect(shoveResult.verdict, AnswerVerdict.poor);
    });
  });
}

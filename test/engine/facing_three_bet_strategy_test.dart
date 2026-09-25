import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_strategy.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/preflop_authoring.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

void main() {
  group('FacingThreeBetStrategy (vía PreflopStrategy.forDecision) — CO vs '
      '3-bet de BTN', () {
    test('mano de 4-bet de valor (KK): raise óptimo/fourBetValue, call '
        'viable/defend, fold malo', () {
      final scenario = ExerciseScenarioBuilder.facingThreeBet(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('KsKd'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(raise.rating, StrategicRating.optimal);
      expect(raise.role, StrategyRole.fourBetValue);
      expect(raise.rationaleKey, 'facing_three_bet.raise.value');

      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.rating, StrategicRating.viable);
      expect(call.role, StrategyRole.defend);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(fold.rating, StrategicRating.bad);
      expect(fold.role, StrategyRole.fold);

      final result = AnswerEvaluator.evaluate(scenario, raise.action);
      expect(result.verdict, AnswerVerdict.best);
    });

    test('mano de call estándar (QQ): call óptimo/defend, raise y fold '
        'malos', () {
      final scenario = ExerciseScenarioBuilder.facingThreeBet(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('QsQd'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.rating, StrategicRating.optimal);
      expect(call.role, StrategyRole.defend);

      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(raise.rating, StrategicRating.bad);

      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.call));
      expect(result.verdict, AnswerVerdict.best);
    });

    test('mano claramente fuera de rango (72o): fold óptimo, call y raise '
        'malos', () {
      final scenario = ExerciseScenarioBuilder.facingThreeBet(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('7c2d'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(fold.rating, StrategicRating.optimal);
      expect(fold.role, StrategyRole.fold);

      final result = AnswerEvaluator.evaluate(scenario, PokerAction.raiseTo(20));
      expect(result.verdict, AnswerVerdict.poor);
    });
  });
}

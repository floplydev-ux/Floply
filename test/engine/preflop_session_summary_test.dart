import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_session_summary.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';

void main() {
  group('PreflopSessionSummary.empty', () {
    test('sesión sin ejercicios: todo en cero/vacío', () {
      final summary = PreflopSessionSummary.empty();
      expect(summary.exercisesDone, 0);
      expect(summary.verdictCounts, isEmpty);
      expect(summary.averageQuality, 0);
      expect(summary.scenarioCounts, isEmpty);
      expect(summary.conceptsWorked, isEmpty);
      expect(summary.conceptsWithWeakPerformance, isEmpty);
      expect(summary.bestCount, 0);
      expect(summary.acceptableCount, 0);
      expect(summary.dependentCount, 0);
      expect(summary.poorCount, 0);
    });

    test('fromResults con una lista vacía es igual a empty()', () {
      final summary = PreflopSessionSummary.fromResults(const []);
      expect(summary.exercisesDone, 0);
      expect(summary.averageQuality, 0);
    });
  });

  group('PreflopSessionSummary.fromResults — acumulación', () {
    test('cuenta exercisesDone, verdictCounts y scenarioCounts '
        'correctamente sobre resultados reales', () {
      final scenarioA = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'), // abrir es lo óptimo → best
      );
      final resultA = AnswerEvaluator.evaluate(scenarioA, const PokerAction(ActionType.fold));
      // foldear una mano premium en un spot de apertura clara → poor
      expect(resultA.verdict, AnswerVerdict.poor);

      final scenarioB = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(3)),
        heroHand: HoleCards.parse('AsAd'),
      );
      final resultB = AnswerEvaluator.evaluate(scenarioB, const PokerAction(ActionType.fold));
      expect(resultB.verdict, AnswerVerdict.poor);

      final summary = PreflopSessionSummary.fromResults([
        (scenarioA.objective, resultA),
        (scenarioB.objective, resultB),
      ]);

      expect(summary.exercisesDone, 2);
      expect(summary.verdictCounts[AnswerVerdict.poor], 2);
      expect(summary.scenarioCounts[PreflopScenarioKind.openRaise], 1);
      expect(summary.scenarioCounts[PreflopScenarioKind.defenseVsOpen], 1);
    });

    test('averageQuality es el promedio real de matchedOption.rating.score',
        () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final best = AnswerEvaluator.evaluate(
          scenario, PokerAction.raiseTo(scenario.decisionContext.minRaiseToBb!));
      final poor = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.fold));

      final summary = PreflopSessionSummary.fromResults([
        (scenario.objective, best),
        (scenario.objective, poor),
      ]);

      final expectedAverage =
          (best.matchedOption.rating.score + poor.matchedOption.rating.score) / 2;
      expect(summary.averageQuality, expectedAverage);
    });

    test('conceptsWorked es la unión de justifyingConcepts, sin duplicados',
        () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final action = PokerAction.raiseTo(scenario.decisionContext.minRaiseToBb!);
      final result = AnswerEvaluator.evaluate(scenario, action);
      expect(result.justifyingConcepts, isNotEmpty);

      final summary = PreflopSessionSummary.fromResults([
        (scenario.objective, result),
        (scenario.objective, result), // mismo resultado dos veces
      ]);

      expect(summary.conceptsWorked, result.justifyingConcepts.toSet());
      expect(summary.exercisesDone, 2,
          reason: 'exercisesDone cuenta cada entrada, aunque el concepto se repita');
    });
  });

  group('PreflopSessionSummary — getters de conveniencia por verdict (Fase 9.2)', () {
    test('bestCount/acceptableCount/dependentCount/poorCount reflejan '
        'verdictCounts exactamente', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final best = AnswerEvaluator.evaluate(
          scenario, PokerAction.raiseTo(OpeningRanges.sizingFor(Position.utg)));
      expect(best.verdict, AnswerVerdict.best);
      final poor = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.fold));

      final summary = PreflopSessionSummary.fromResults([
        (scenario.objective, best),
        (scenario.objective, poor),
        (scenario.objective, poor),
      ]);

      expect(summary.bestCount, summary.verdictCounts[AnswerVerdict.best] ?? 0);
      expect(summary.poorCount, summary.verdictCounts[AnswerVerdict.poor] ?? 0);
      expect(summary.poorCount, 2);
      expect(summary.acceptableCount, 0);
      expect(summary.dependentCount, 0);
    });
  });

  group('PreflopSessionSummary.conceptsWithWeakPerformance (Fase 9.2)', () {
    test('solo incluye conceptos que participaron en al menos una decisión '
        'poor — no un ranking, solo presencia', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final poor = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.fold));
      expect(poor.verdict, AnswerVerdict.poor);
      expect(poor.justifyingConcepts, isNotEmpty);

      final summary = PreflopSessionSummary.fromResults([(scenario.objective, poor)]);
      expect(summary.conceptsWithWeakPerformance, poor.justifyingConcepts.toSet());
      expect(
        summary.conceptsWithWeakPerformance.every(summary.conceptsWorked.contains),
        isTrue,
        reason: 'todo concepto débil es también un concepto practicado',
      );
    });

    test('ninguna decisión poor → conjunto vacío, sin inventar debilidades',
        () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final best = AnswerEvaluator.evaluate(
          scenario, PokerAction.raiseTo(OpeningRanges.sizingFor(Position.utg)));
      expect(best.verdict, AnswerVerdict.best);

      final summary = PreflopSessionSummary.fromResults([(scenario.objective, best)]);
      expect(summary.conceptsWithWeakPerformance, isEmpty);
      expect(summary.conceptsWorked, isNotEmpty,
          reason: 'sí se practicaron conceptos, solo que ninguno salió mal');
    });
  });
}

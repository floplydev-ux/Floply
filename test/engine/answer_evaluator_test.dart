import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';

void main() {
  group('AnswerEvaluator.evaluate — los 4 veredictos', () {
    test('best: la acción óptima real de un escenario de apertura', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'), // premium: abrir es lo óptimo
      );
      // El tamaño tiene que ser el que PreflopStrategy realmente espera
      // (2.5bb, vía OpeningRanges.sizingFor) — no cualquier raise legal:
      // Strategy.optionFor matchea por tamaño con tolerancia, y un
      // mínimo técnico (2bb) no necesariamente cae dentro de esa
      // tolerancia.
      final result = AnswerEvaluator.evaluate(
          scenario, PokerAction.raiseTo(OpeningRanges.sizingFor(Position.utg)));
      expect(result.verdict, AnswerVerdict.best);
    });

    test('poor: foldear una mano premium en un spot de apertura clara', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.fold));
      expect(result.verdict, AnswerVerdict.poor);
    });

    test('best: pagar con una mano media, enfrentando un open', () {
      // T9s: ni tan fuerte como para 3-betear "claramente", ni tan débil
      // como para foldear — cae en la banda media de HandStrength.
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(3)),
        heroHand: HoleCards.parse('Ts9s'),
      );
      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.call));
      expect(result.verdict, anyOf(AnswerVerdict.best, AnswerVerdict.dependent));
    });

    test('poor: foldear una mano claramente premium enfrentando un open',
        () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(3)),
        heroHand: HoleCards.parse('AsAd'),
      );
      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.fold));
      expect(result.verdict, AnswerVerdict.poor);
    });

    test('acceptable: una acción defendible pero no la preferida (pagar '
        'con una mano premium en vez de subirla, enfrentando un open)', () {
      // Con una mano premium enfrentando un open, PreflopStrategy ofrece
      // raise=optimal, call=viable (frequency 0 → no entra en el gate de
      // "dependent", que exige frequency >= 0.15) y fold=bad. Pagar acá
      // es defendible pero no lo preferido: exactamente "acceptable".
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(3)),
        heroHand: HoleCards.parse('AsAd'),
      );
      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.call));
      expect(result.verdict, AnswerVerdict.acceptable);
    });

    test('dependent: una mano en la frontera del rango — la respuesta '
        'admite más de una opción con frecuencia real', () {
      String? mixedNotation;
      for (final hc in HandClass.all()) {
        final hand = Deck(Random(0)).dealHandOfClass(hc.notation);
        if (hand == null) continue;
        final scenario = ExerciseScenarioBuilder.openRaise(
          deck: Deck(Random(2)),
          heroPosition: Position.utg,
          heroHand: hand,
        );
        if (!scenario.decisionContext.legalActions.contains(ActionType.raise)) continue;
        final result = AnswerEvaluator.evaluate(
            scenario, PokerAction.raiseTo(OpeningRanges.sizingFor(Position.utg)));
        if (result.verdict == AnswerVerdict.dependent) {
          mixedNotation = hc.notation;
          break;
        }
      }
      expect(mixedNotation, isNotNull,
          reason: 'debería existir al menos una mano de frontera cuya '
              'apertura sea "dependent" (estrategia mixta)');
    });
  });

  group('AnswerEvaluator.evaluate — respeta evaluableConcepts', () {
    test('nunca devuelve un concepto que el escenario no declaró', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final result = AnswerEvaluator.evaluate(
          scenario, PokerAction.raiseTo(OpeningRanges.sizingFor(Position.utg)));
      expect(
        result.justifyingConcepts.every(scenario.evaluableConcepts.contains),
        isTrue,
      );
    });
  });

  group('AnswerEvaluator.evaluate — nunca explota', () {
    test('una acción que la estrategia de referencia no contempló '
        'igual devuelve un veredicto (no lanza)', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      // Un tamaño de subida rarísimo que ninguna Strategy de referencia
      // contemplaría puntualmente.
      final oddAction = PokerAction.raiseTo(scenario.decisionContext.maxRaiseToBb!);
      expect(() => AnswerEvaluator.evaluate(scenario, oddAction), returnsNormally);
    });
  });

  group('AnswerEvaluator.evaluate — chosenAction/recommendedAction (Fase 8.3)', () {
    test('chosenAction es exactamente la acción pasada a evaluate', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      const action = PokerAction(ActionType.fold);
      final result = AnswerEvaluator.evaluate(scenario, action);
      expect(result.chosenAction, action);
    });

    test('recommendedAction es la acción óptima real (coincide con lo que '
        'hace que el veredicto sea "best")', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final recommended = AnswerEvaluator.evaluate(
              scenario, const PokerAction(ActionType.fold))
          .recommendedAction;
      final result = AnswerEvaluator.evaluate(scenario, recommended);
      expect(result.verdict, AnswerVerdict.best,
          reason: 'jugar recommendedAction siempre debería calificar best');
    });

    test('para los 4 veredictos, chosenAction/recommendedAction nunca son '
        'nulos ni cambian entre sí de forma inconsistente', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(3)),
        heroHand: HoleCards.parse('AsAd'),
      );
      for (final action in const [
        PokerAction(ActionType.fold),
        PokerAction(ActionType.call),
      ]) {
        final result = AnswerEvaluator.evaluate(scenario, action);
        expect(result.chosenAction, action);
        expect(result.recommendedAction, isNotNull);
      }
    });
  });

  group('AnswerEvaluator.evaluate — postflop (cbetDecision, vía '
      'ScenarioStrategy)', () {
    test('best: c-apostar (cualquier tamaño) en el flop favorable', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(1)));
      final result = AnswerEvaluator.evaluate(scenario, PokerAction.bet(3));
      expect(result.verdict, AnswerVerdict.best);
      expect(result.justifyingConcepts, containsAll(['cbet', 'board_texture']));
    });

    test('best: c-apostar matchea sin importar el tamaño exacto elegido '
        '(la lección es si apostar, no con qué tamaño)', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(1)));
      for (final sizeBb in [1.0, 2.5, 10.0]) {
        final result = AnswerEvaluator.evaluate(scenario, PokerAction.bet(sizeBb));
        expect(result.verdict, AnswerVerdict.best, reason: 'sizeBb=$sizeBb');
      }
    });

    test('poor: checkear en vez de c-apostar el flop favorable', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(1)));
      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.check));
      expect(result.verdict, AnswerVerdict.poor);
    });

    test('recommendedAction siempre es un bet', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(1)));
      final result = AnswerEvaluator.evaluate(scenario, const PokerAction(ActionType.check));
      expect(result.recommendedAction.type, ActionType.bet);
    });
  });
}

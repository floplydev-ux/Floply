import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/lab_feedback_builder.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';

/// UserKnowledge con exactamente estos conceptos enseñados (el resto queda
/// `locked`) — mismo helper que ya usa `exercise_scenario_adapter_test.dart`.
UserKnowledge _knowledgeWith(ConceptRegistry registry, Iterable<String> taught) {
  final k = UserKnowledge(registry);
  for (final id in taught) {
    k.teach(id);
  }
  return k;
}

void main() {
  final registry = ConceptRegistry.standard();

  group('LabFeedbackBuilder.build — contenido estructurado', () {
    test('expectedLabel y whyText nunca están vacíos, sea cual sea el '
        'veredicto', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);

      for (final action in [PokerAction.fold, const PokerAction(ActionType.call)]) {
        final result = AnswerEvaluator.evaluate(scenario, action);
        final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);

        expect(feedback.expectedLabel, isNotEmpty);
        expect(feedback.whyText, isNotEmpty);
        expect(feedback.expectedLabel, result.recommendedAction.label);
      }
    });

    test('nunca menciona (ni cita para repasar) un concepto que el usuario '
        'no tiene enseñado', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(2)));
      // A propósito, ningún concepto enseñado: el escenario sigue siendo
      // evaluable (evaluableConcepts no vacío), pero `isTaught` es falso
      // para todos.
      final knowledge = UserKnowledge(registry);

      final result = AnswerEvaluator.evaluate(scenario, PokerAction.fold);
      final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);

      expect(feedback.conceptTitle, isNull);
      expect(feedback.conceptExplanation, isNull);
      expect(feedback.academyReviewLessonId, isNull);
    });

    test('cuando sí hay un concepto enseñado, conceptTitle/conceptExplanation '
        'son el nombre/descripción reales de ConceptRegistry (nunca texto '
        'redactado aparte)', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(3)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);

      final result = AnswerEvaluator.evaluate(scenario, PokerAction.fold);
      final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);

      if (result.justifyingConcepts.isNotEmpty) {
        final concept = registry.byId(result.justifyingConcepts.first);
        expect(feedback.conceptTitle, concept.name);
        expect(feedback.conceptExplanation, concept.description);
      }
    });

    test('academyReviewLessonId, cuando no es null, siempre corresponde a '
        'una lección real de Curriculum.standard() — nunca una lección '
        'fantasma', () {
      for (var seed = 1; seed <= 25; seed++) {
        final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(seed)));
        final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);

        for (final action in [
          PokerAction.fold,
          const PokerAction(ActionType.call),
          PokerAction.raiseTo(scenario.decisionContext.minRaiseToBb ?? 6),
        ]) {
          final result = AnswerEvaluator.evaluate(scenario, action);
          final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);

          final lessonId = feedback.academyReviewLessonId;
          if (lessonId != null) {
            expect(Curriculum.standard().lessonById(lessonId), isNotNull,
                reason: 'seed $seed, action $action: "$lessonId" no existe en '
                    'el currículo real');
            expect(feedback.academyReviewLabel, isNotNull, reason: 'seed $seed');
          }
        }
      }
    });

    test('nunca ofrece repasar cuando la respuesta ya fue la mejor '
        '(AnswerVerdict.best)', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(4)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);

      // `recommendedAction` (la acción primaria de la estrategia de
      // referencia) es la misma sea cual sea la acción que se evalúe —
      // evaluarla a ella misma siempre da veredicto `best`.
      final probe = AnswerEvaluator.evaluate(scenario, PokerAction.fold);
      final result = AnswerEvaluator.evaluate(scenario, probe.recommendedAction);
      expect(result.verdict, AnswerVerdict.best);

      final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);
      expect(feedback.academyReviewLessonId, isNull);
      expect(feedback.hasReview, isFalse);
    });

    test('math es null en un escenario openRaise (tabla de rangos preflop, '
        'no EquityEngine): abrir de entrada, aunque haya que igualar la '
        'ciega grande, no es "encarar una apuesta real" — mostrar SPR/MDF '
        'ahí sería ruido para la decisión más simple que existe', () {
      for (var seed = 1; seed <= 10; seed++) {
        final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(seed)));
        final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
        final result = AnswerEvaluator.evaluate(scenario, PokerAction.fold);
        final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);

        expect(feedback.math, isNull, reason: 'seed $seed');
      }
    });

    test('math trae SPR/MDF cuando sí hay una subida real que encarar '
        '(defenseVsOpen: el rival abrió, no solo la ciega grande) — aunque '
        'PreflopStrategy no calcule equity acá (tabla de rangos)', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(7)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final result = AnswerEvaluator.evaluate(scenario, PokerAction.fold);
      final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);

      expect(scenario.decisionContext.toCallBb, greaterThan(0));
      expect(feedback.math, isNotNull);
      expect(feedback.math!.sprValue, isNotNull);
      expect(feedback.math!.mdfPct, isNotNull);
      // PreflopStrategy no calcula equity para esta familia (tabla de
      // rangos) — SPR/MDF no dependen de eso para existir.
      expect(feedback.math!.equityPct, isNull);
    });

    test('math trae equity real (no inventada) cuando PostflopStrategy sí '
        'la calculó — facingCbet, familia con equity real contra el rango '
        'de apertura del agresor', () {
      final scenario = ExerciseScenarioBuilder.facingCbet(deck: Deck(Random(6)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final result = AnswerEvaluator.evaluate(scenario, PokerAction.fold);
      final feedback = LabFeedbackBuilder.build(scenario, result, knowledge, registry);

      expect(feedback.math, isNotNull);
      expect(feedback.math!.equityPct, isNotNull);
      expect(feedback.math!.equityPct, result.matchedOption.math!.equityPct);
      // SPR/MDF sí aplican acá: el héroe está encarando una apuesta real.
      expect(scenario.decisionContext.toCallBb, greaterThan(0));
      expect(feedback.math!.sprValue, isNotNull);
      expect(feedback.math!.mdfPct, isNotNull);
    });
  });
}

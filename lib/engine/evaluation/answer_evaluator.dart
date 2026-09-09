import '../concepts/user_knowledge.dart';
import '../exercises/exercise.dart';
import '../strategy/strategy.dart';
import 'evaluation_result.dart';
import 'user_answer.dart';

/// Evalúa la respuesta del usuario contra la estrategia de referencia del
/// ejercicio.
///
/// Produce un [EvaluationResult] "crudo" (sin textos de feedback): de los
/// textos se encarga el [FeedbackEngine].
class AnswerEvaluator {
  const AnswerEvaluator();

  EvaluationResult evaluate(
    Exercise exercise,
    UserAnswer answer, {
    required UserKnowledge knowledge,
  }) {
    final chosen = _resolveChosenOption(exercise, answer);
    final best = exercise.strategy.primary;

    final rating = chosen?.rating ?? StrategicRating.bad;
    final decisionScore = _decisionScore(chosen, exercise.strategy);

    final reasoning = _evaluateReasoning(exercise, answer, chosen, knowledge);

    return EvaluationResult(
      decisionScore: decisionScore,
      reasoningScore: reasoning.score,
      strategicRating: rating,
      acceptable: rating.isAcceptable,
      chosenOption: chosen,
      bestOption: best,
      matchedConcepts: reasoning.matched,
      missingConcepts: reasoning.missing,
      evaluatedConcepts: exercise.evaluatedConcepts,
    );
  }

  /// Encuentra la [StrategyOption] que corresponde a lo que eligió el
  /// usuario, sea por acción, por sizing o por valor genérico.
  StrategyOption? _resolveChosenOption(Exercise exercise, UserAnswer answer) {
    final optionId = answer.selectedOptionId ??
        (answer.selectedOptionIds.isNotEmpty
            ? answer.selectedOptionIds.first
            : null);
    if (optionId == null) return null;

    AnswerOption? option;
    for (final o in exercise.options) {
      if (o.id == optionId) {
        option = o;
        break;
      }
    }
    if (option == null) return null;

    if (option.action != null) {
      return exercise.strategy.optionFor(option.action!);
    }
    if (option.sizingBb != null) {
      for (final so in exercise.strategy.options) {
        if (so.action.sizeBb != null &&
            (so.action.sizeBb! - option.sizingBb!).abs() < 0.01) {
          return so;
        }
      }
      return null;
    }

    // Ejercicios de valor (sí/no, comparaciones): se mapea el acierto a
    // una opción sintética de estrategia.
    final correct = option.value == exercise.correctValue;
    return StrategyOption(
      action: exercise.strategy.primary.action,
      frequency: correct ? 1.0 : 0.0,
      rating: correct ? StrategicRating.optimal : StrategicRating.bad,
      justifyingConcepts: exercise.strategy.primary.justifyingConcepts,
      rationaleKey: exercise.strategy.primary.rationaleKey,
    );
  }

  double _decisionScore(StrategyOption? chosen, Strategy strategy) {
    if (chosen == null) return 0.0;
    // El puntaje base viene de la valoración; se ajusta ligeramente por
    // la frecuencia relativa para premiar la línea preferida.
    final base = chosen.rating.score;
    if (chosen.rating == StrategicRating.optimal) return 1.0;
    return base.clamp(0.0, 1.0);
  }

  _ReasoningEval _evaluateReasoning(
    Exercise exercise,
    UserAnswer answer,
    StrategyOption? chosen,
    UserKnowledge knowledge,
  ) {
    // Solo se ofrecen (y evalúan) conceptos ya enseñados.
    final offered = exercise.reasoningConcepts
        .where(knowledge.isTaught)
        .toSet();
    if (offered.isEmpty) {
      return const _ReasoningEval(null, [], []);
    }

    final expected = <String>{
      ...?chosen?.justifyingConcepts,
      ...exercise.evaluatedConcepts,
    }.where((c) => offered.contains(c)).toSet();

    if (expected.isEmpty) {
      return const _ReasoningEval(null, [], []);
    }

    final selected = answer.reasoningConceptIds.toSet();
    final matched = expected.intersection(selected).toList();
    final missing = expected.difference(selected).toList();
    final wrongPicks = selected.difference(expected).length;

    // Puntaje: proporción de conceptos correctos marcados, penalizando
    // marcar conceptos que no venían al caso.
    final hitRatio = matched.length / expected.length;
    final penalty = wrongPicks == 0 ? 0.0 : (wrongPicks * 0.15).clamp(0.0, 0.5);
    final score = (hitRatio - penalty).clamp(0.0, 1.0);

    return _ReasoningEval(score, matched, missing);
  }
}

class _ReasoningEval {
  const _ReasoningEval(this.score, this.matched, this.missing);
  final double? score;
  final List<String> matched;
  final List<String> missing;
}

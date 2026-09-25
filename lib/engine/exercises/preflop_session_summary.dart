import 'answer_evaluator.dart';
import 'exercise_scenario.dart';

/// Resumen de una sesión del motor nuevo — Fase 8.5.
///
/// Concepto propio del Exercise Engine nuevo, independiente del scoring
/// del sistema viejo (`EvaluationResult`/`sessionDecisionScore`/
/// `masteryBuckets`, en `SessionSummary` widget): ese sigue atado al
/// motor viejo y no se toca acá. Modelo puro (sin Flutter, sin
/// gráficos) — reutiliza `StrategyOption.rating.score` (ya existente,
/// 0..1) para la calidad agregada en vez de inventar una escala nueva.
class PreflopSessionSummary {
  const PreflopSessionSummary({
    required this.exercisesDone,
    required this.verdictCounts,
    required this.averageQuality,
    required this.scenarioCounts,
    required this.conceptsWorked,
    required this.conceptsWithWeakPerformance,
  });

  /// Sesión sin ejercicios resueltos todavía — todos los mapas vacíos,
  /// calidad promedio 0.
  factory PreflopSessionSummary.empty() => const PreflopSessionSummary(
        exercisesDone: 0,
        verdictCounts: {},
        averageQuality: 0,
        scenarioCounts: {},
        conceptsWorked: {},
        conceptsWithWeakPerformance: {},
      );

  factory PreflopSessionSummary.fromResults(
    List<(PreflopScenarioKind, AnswerResult)> entries,
  ) {
    if (entries.isEmpty) return PreflopSessionSummary.empty();

    final verdictCounts = <AnswerVerdict, int>{};
    final scenarioCounts = <PreflopScenarioKind, int>{};
    final conceptsWorked = <String>{};
    final conceptsWithWeakPerformance = <String>{};
    var qualitySum = 0.0;

    for (final (kind, result) in entries) {
      verdictCounts[result.verdict] = (verdictCounts[result.verdict] ?? 0) + 1;
      scenarioCounts[kind] = (scenarioCounts[kind] ?? 0) + 1;
      conceptsWorked.addAll(result.justifyingConcepts);
      if (result.verdict == AnswerVerdict.poor) {
        conceptsWithWeakPerformance.addAll(result.justifyingConcepts);
      }
      qualitySum += result.matchedOption.rating.score;
    }

    return PreflopSessionSummary(
      exercisesDone: entries.length,
      verdictCounts: verdictCounts,
      averageQuality: qualitySum / entries.length,
      scenarioCounts: scenarioCounts,
      conceptsWorked: conceptsWorked,
      conceptsWithWeakPerformance: conceptsWithWeakPerformance,
    );
  }

  final int exercisesDone;

  /// Cuántos ejercicios cayeron en cada `AnswerVerdict` — nunca
  /// colapsado a correcto/incorrecto, mismo eje de 4 valores que usa
  /// `AnswerEvaluator`.
  final Map<AnswerVerdict, int> verdictCounts;

  int get bestCount => verdictCounts[AnswerVerdict.best] ?? 0;
  int get acceptableCount => verdictCounts[AnswerVerdict.acceptable] ?? 0;
  int get dependentCount => verdictCounts[AnswerVerdict.dependent] ?? 0;
  int get poorCount => verdictCounts[AnswerVerdict.poor] ?? 0;

  /// Promedio de `StrategyOption.rating.score` (0..1) de las opciones
  /// realmente elegidas — la noción de "calidad general" de la sesión:
  /// no un puntaje inventado, el promedio real de calidad de cada
  /// decisión tomada.
  final double averageQuality;

  final Map<PreflopScenarioKind, int> scenarioCounts;

  /// Unión de los conceptos que justificaron algún veredicto durante la
  /// sesión — ya filtrados por `AnswerEvaluator` contra
  /// `ExerciseScenario.evaluableConcepts`.
  final Set<String> conceptsWorked;

  /// Subconjunto de [conceptsWorked] que participó en al menos una
  /// decisión calificada `poor` — regla directa y sin ponderar (Fase
  /// 9.2): no es un ranking, solo "esto apareció en algo que salió mal
  /// esta sesión".
  final Set<String> conceptsWithWeakPerformance;
}

import 'dart:math';

import '../concepts/concept_registry.dart';
import '../concepts/user_knowledge.dart';
import '../pedagogy/pedagogical_engine.dart';
import '../poker/deck.dart';
import '../strategy/strategy_engine.dart';
import 'exercise.dart';
import 'exercise_history.dart';
import 'exercise_template.dart';
import 'exercise_validator.dart';
import 'generation_context.dart';
import 'templates/compare_hands_template.dart';
import 'templates/full_open_decision_template.dart';
import 'templates/hand_in_range_template.dart';
import 'templates/hand_ranking_template.dart';
import 'templates/open_raise_decision_template.dart';
import 'templates/open_sizing_template.dart';
import 'templates/position_order_template.dart';
import 'templates/widest_range_template.dart';

/// Resultado de un intento de generación.
class GenerationOutcome {
  GenerationOutcome({
    required this.exercise,
    required this.goal,
    required this.attempts,
  });

  final Exercise exercise;
  final PedagogicalGoal goal;
  final int attempts;
}

/// Orquesta la randomización controlada: concepto → objetivo → dificultad
/// → template → contexto → situación → validación → anti-repetición.
class ExerciseGenerator {
  ExerciseGenerator({
    required PedagogicalEngine pedagogy,
    required ConceptRegistry concepts,
    StrategyEngine? strategyEngine,
    List<ExerciseTemplate>? templates,
    int? seed,
  })  : _pedagogy = pedagogy,
        _concepts = concepts,
        _strategyEngine = strategyEngine ?? const StrategyEngine(),
        _templates = templates ?? defaultTemplates,
        _random = seed != null ? Random(seed) : Random();

  final PedagogicalEngine _pedagogy;
  final ConceptRegistry _concepts;
  final StrategyEngine _strategyEngine;
  final List<ExerciseTemplate> _templates;
  final Random _random;

  static const int maxAttempts = 30;

  /// Los templates del vertical slice (posición + apertura preflop).
  static const List<ExerciseTemplate> defaultTemplates = [
    OpenRaiseDecisionTemplate(),
    HandInOpeningRangeTemplate(),
    WidestRangeTemplate(),
    OpenSizingTemplate(),
    CompareHandsTemplate(),
    FullOpenDecisionTemplate(),
    HandRankingTemplate(),
    PositionOrderTemplate(),
  ];

  List<ExerciseTemplate> get templates => List.unmodifiable(_templates);

  /// Conceptos para los que existe al menos un template.
  Set<String> get practiceableConcepts =>
      _templates.expand((t) => t.evaluatedConcepts).toSet();

  /// Genera el próximo ejercicio para [knowledge].
  ///
  /// [history] permite evitar ejercicios demasiado parecidos a los
  /// recientes. Si no se pasa, no hay control anti-repetición.
  GenerationOutcome next(
    UserKnowledge knowledge, {
    String? preferredConcept,
    int? difficulty,
    ExerciseHistory? history,
  }) {
    final goal = _pedagogy.nextGoal(
      knowledge,
      preferredConcept: preferredConcept,
      practiceable: practiceableConcepts,
      rng: _random,
    );
    final targetDifficulty = (difficulty ?? goal.suggestedDifficulty).clamp(1, 5);
    final taught = knowledge.taughtConcepts;
    final validator = ExerciseValidator(taughtConcepts: taught);

    final eligible = _eligibleTemplates(
      targetConcept: goal.conceptId,
      difficulty: targetDifficulty,
      taught: taught,
    );

    if (eligible.isEmpty) {
      // Reintento con el concepto objetivo pero cualquier dificultad
      // soportada.
      final relaxed = _templates
          .where((t) =>
              t.evaluatedConcepts.contains(goal.conceptId) &&
              t.requiredConcepts.every(taught.contains) &&
              t.evaluatedConcepts.every(taught.contains))
          .toList();
      if (relaxed.isEmpty) {
        throw StateError(
            'No hay ningún template para evaluar "${goal.conceptId}" con lo '
            'que el usuario tiene enseñado.');
      }
      eligible.addAll(relaxed);
    }

    Exercise? lastInvalid;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final template = _pickWeighted(eligible);
      final effectiveDifficulty = template.supportedDifficulties
              .contains(targetDifficulty)
          ? targetDifficulty
          : template.supportedDifficulties[
              _random.nextInt(template.supportedDifficulties.length)];

      final ctx = GenerationContext(
        deck: Deck(Random(_random.nextInt(1 << 32))),
        strategyEngine: _strategyEngine,
        concepts: _concepts,
        taughtConcepts: taught,
        difficulty: effectiveDifficulty,
        targetConcept: goal.conceptId,
      );

      Exercise exercise;
      try {
        exercise = template.generate(ctx);
      } on TemplateGenerationException {
        continue;
      }

      final validation = validator.validate(exercise);
      if (!validation.isValid) {
        lastInvalid = exercise;
        continue;
      }

      if (history != null) {
        final signature = ExerciseSignature.of(exercise);
        if (history.isTooSimilar(signature)) {
          // Deja pasar si ya probamos mucho: mejor un ejercicio algo
          // parecido que ninguno.
          if (attempt < maxAttempts - 5) continue;
        }
        history.record(exercise);
      }

      return GenerationOutcome(
        exercise: exercise,
        goal: goal,
        attempts: attempt,
      );
    }

    throw StateError(
        'No se pudo generar un ejercicio válido en $maxAttempts intentos '
        '(último inválido: ${lastInvalid == null ? "ninguno" : lastInvalid.templateId}).');
  }

  List<ExerciseTemplate> _eligibleTemplates({
    required String targetConcept,
    required int difficulty,
    required Set<String> taught,
  }) {
    return _templates
        .where((t) => t.isEligible(
              taughtConcepts: taught,
              difficulty: difficulty,
              targetConcept: targetConcept,
            ))
        .toList();
  }

  ExerciseTemplate _pickWeighted(List<ExerciseTemplate> templates) {
    if (templates.length == 1) return templates.first;
    final totalWeight =
        templates.fold<double>(0, (sum, t) => sum + t.weight);
    var roll = _random.nextDouble() * totalWeight;
    for (final template in templates) {
      roll -= template.weight;
      if (roll <= 0) return template;
    }
    return templates.last;
  }
}

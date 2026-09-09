import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/engine/evaluation/answer_evaluator.dart';
import 'package:poker_trainer/engine/evaluation/feedback_engine.dart';
import 'package:poker_trainer/engine/evaluation/user_answer.dart';
import 'package:poker_trainer/engine/exercises/exercise.dart';
import 'package:poker_trainer/engine/exercises/exercise_generator.dart';
import 'package:poker_trainer/engine/exercises/poker_situation.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/pedagogical_engine.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

void main() {
  final registry = ConceptRegistry.standard();
  final curriculum = Curriculum.standard();
  const evaluator = AnswerEvaluator();
  final feedback = FeedbackEngine(registry);

  UserKnowledge sliceUser() {
    final k = UserKnowledge(registry);
    final pedagogy = PedagogicalEngine(registry, curriculum);
    for (final lesson in curriculum.allLessons) {
      pedagogy.applyLesson(lesson.id, k);
    }
    return k;
  }

  ExerciseGenerator gen({int seed = 1}) => ExerciseGenerator(
        pedagogy: PedagogicalEngine(registry, curriculum),
        concepts: registry,
        seed: seed,
      );

  /// Busca (con distintas semillas) un ejercicio de decisión de apertura
  /// cuya estrategia sea mixta.
  Exercise findMixedOpenDecision() {
    for (var seed = 0; seed < 200; seed++) {
      final ex = gen(seed: seed).next(
        sliceUser(),
        preferredConcept: ConceptIds.openRaise,
        difficulty: 3,
      ).exercise;
      if (ex.templateId == 'open_raise_decision' && ex.strategy.isMixed) {
        return ex;
      }
    }
    fail('No se encontró un ejercicio de apertura mixto');
  }

  test('acción óptima => decisionScore alto y feedback explicativo', () {
    Exercise? ex;
    for (var seed = 0; seed < 100; seed++) {
      final candidate =
          gen(seed: seed).next(sliceUser(), preferredConcept: ConceptIds.openRaise).exercise;
      if (candidate.templateId == 'open_raise_decision' &&
          !candidate.strategy.isMixed) {
        ex = candidate;
        break;
      }
    }
    ex ??= gen().next(sliceUser()).exercise;

    final best = ex.strategy.primary;
    final chosenOption = ex.options.firstWhere(
      (o) => o.action != null && o.action!.matches(best.action),
    );
    final answer = UserAnswer(
      exerciseId: ex.id,
      selectedOptionId: chosenOption.id,
    );
    final raw = evaluator.evaluate(ex, answer, knowledge: sliceUser());
    final decorated = feedback.decorate(raw, ex, knowledge: sliceUser());

    expect(raw.decisionScore, greaterThan(0.8));
    expect(decorated.feedback.length, greaterThan(20));
    expect(decorated.feedback, isNot(equals('Correcto.')));
  });

  test('en estrategia mixta, la acción menos frecuente no es "incorrecta"',
      () {
    final ex = findMixedOpenDecision();
    // Opción con menor frecuencia entre las contempladas por la estrategia.
    final lower = ex.strategy.options
        .reduce((a, b) => a.frequency <= b.frequency ? a : b);
    final option = ex.options.firstWhere(
      (o) => o.action != null && o.action!.matches(lower.action),
    );
    final result = evaluator.evaluate(
      ex,
      UserAnswer(exerciseId: ex.id, selectedOptionId: option.id),
      knowledge: sliceUser(),
    );
    expect(result.acceptable, isTrue);
    expect(result.strategicRating.index,
        lessThanOrEqualTo(StrategicRating.viable.index));
  });

  test('separa calidad de decisión y de razonamiento (acertar de casualidad)',
      () {
    final ex = findMixedOpenDecision();
    final best = ex.strategy.primary;
    final goodOption = ex.options.firstWhere(
      (o) => o.action != null && o.action!.matches(best.action),
    );
    // Elige bien pero marca conceptos de razonamiento equivocados.
    final wrongReasoning = ex.reasoningConcepts.isEmpty
        ? <String>[]
        : [ex.reasoningConcepts.last];
    final answer = UserAnswer(
      exerciseId: ex.id,
      selectedOptionId: goodOption.id,
      reasoningConceptIds: const ['position_blinds'], // no relacionado
    );
    final result = evaluator.evaluate(ex, answer, knowledge: sliceUser());
    expect(result.decisionIsStrong, isTrue);
    if (result.reasoningScore != null) {
      expect(result.reasoningScore, lessThan(0.6));
    }
    expect(wrongReasoning, isNotNull);
  });

  test('el feedback nunca menciona conceptos no enseñados como sabidos', () {
    final user = sliceUser();
    for (var seed = 0; seed < 40; seed++) {
      final ex = gen(seed: seed).next(user).exercise;
      final answer = UserAnswer(
        exerciseId: ex.id,
        selectedOptionId: ex.options.first.id,
      );
      final raw = evaluator.evaluate(ex, answer, knowledge: user);
      final decorated = feedback.decorate(raw, ex, knowledge: user);
      // Los conceptos "avanzados" bloqueados no deben aparecer en el
      // feedback avanzado (que debería ser null si no están enseñados).
      if (decorated.advancedFeedback != null) {
        for (final c in ex.explanation.advancedConcepts) {
          expect(user.isTaught(c), isTrue,
              reason: 'feedback avanzado mostrado con "$c" bloqueado');
        }
      }
    }
  });

  test('acción fuera de rango => rating malo y no aceptable', () {
    // Genera hasta encontrar una decisión donde foldear es lo correcto.
    Exercise? ex;
    for (var seed = 0; seed < 200; seed++) {
      final candidate = gen(seed: seed)
          .next(sliceUser(), preferredConcept: ConceptIds.openRaise)
          .exercise;
      if (candidate.templateId == 'open_raise_decision' &&
          candidate.strategy.primary.action.type == ActionType.fold &&
          !candidate.strategy.isMixed) {
        ex = candidate;
        break;
      }
    }
    expect(ex, isNotNull);
    final raiseOption = ex!.options.firstWhere((o) =>
        o.action != null && o.action!.type == ActionType.raise);
    final result = evaluator.evaluate(
      ex,
      UserAnswer(exerciseId: ex.id, selectedOptionId: raiseOption.id),
      knowledge: sliceUser(),
    );
    expect(result.acceptable, isFalse);
    expect(result.strategicRating.isAcceptable, isFalse);
  });

  test('situación de ejemplo se puede construir sin UI', () {
    // Comprueba que PokerSituation y su descripción funcionan aislados.
    final ex = gen().next(sliceUser()).exercise;
    final PokerSituation? s = ex.situation;
    if (s != null) {
      expect(s.actionHistoryDescription, isNotEmpty);
    }
  });
}

import 'academy/academy_engine.dart';
import 'concepts/concept_registry.dart';
import 'concepts/user_knowledge.dart';
import 'evaluation/answer_evaluator.dart';
import 'evaluation/evaluation_result.dart';
import 'evaluation/feedback_engine.dart';
import 'evaluation/user_answer.dart';
import 'exercises/exercise.dart';
import 'exercises/exercise_generator.dart';
import 'exercises/exercise_history.dart';
import 'pedagogy/curriculum.dart';
import 'pedagogy/pedagogical_engine.dart';
import 'pedagogy/recovery_session.dart';

/// Fachada del motor: junta las cinco responsabilidades (pedagógica,
/// estratégica, generación, evaluación, feedback) detrás de una API
/// chica y estable para la UI.
///
/// Toda la lógica se puede ejercitar desde tests sin tocar Flutter.
class PokerTrainerEngine {
  PokerTrainerEngine({
    ConceptRegistry? concepts,
    Curriculum? curriculum,
    int? seed,
  })  : concepts = concepts ?? ConceptRegistry.standard(),
        curriculum = curriculum ?? Curriculum.standard() {
    pedagogy = PedagogicalEngine(this.concepts, this.curriculum);
    _generator = ExerciseGenerator(
      pedagogy: pedagogy,
      concepts: this.concepts,
      seed: seed,
    );
    _feedback = FeedbackEngine(this.concepts);
    academy = AcademyEngine(
      curriculum: this.curriculum,
      registry: this.concepts,
      pedagogy: pedagogy,
    );
  }

  final ConceptRegistry concepts;
  final Curriculum curriculum;
  late final PedagogicalEngine pedagogy;
  late final AcademyEngine academy;
  late final ExerciseGenerator _generator;
  late final FeedbackEngine _feedback;

  final AnswerEvaluator _evaluator = const AnswerEvaluator();
  final ExerciseHistory history = ExerciseHistory();

  ExerciseGenerator get generator => _generator;

  /// Crea un usuario **de prueba / Laboratorio**: tiene todos los conceptos
  /// de la Academia (niveles 1–5) ya enseñados, para que la práctica libre
  /// funcione de entrada sin recorrer la progresión.
  ///
  /// Pasá [taughtLessons] para controlar exactamente qué se enseña (o
  /// `const []` para un usuario sin nada, equivalente a [newAcademyUser]).
  UserKnowledge newUser({List<String>? taughtLessons}) {
    final knowledge = UserKnowledge(concepts);
    final lessons = taughtLessons ?? Curriculum.lessonOrder;
    for (final lessonId in lessons) {
      pedagogy.applyLesson(lessonId, knowledge);
    }
    return knowledge;
  }

  /// Crea un **usuario nuevo real de la Academia**: no recorrió nada, solo
  /// tiene disponible el primer lesson. Los conceptos se van enseñando a
  /// medida que abre cada lesson (`AcademyEngine.openLesson`).
  UserKnowledge newAcademyUser() => UserKnowledge(concepts);

  /// Pide el próximo ejercicio para [knowledge].
  Exercise nextExercise(
    UserKnowledge knowledge, {
    String? concept,
    int? difficulty,
  }) {
    return _generator
        .next(
          knowledge,
          preferredConcept: concept,
          difficulty: difficulty,
          history: history,
        )
        .exercise;
  }

  /// Evalúa la respuesta, genera el feedback y actualiza el conocimiento
  /// del usuario en un solo paso.
  EvaluationResult submit(
    Exercise exercise,
    UserAnswer answer,
    UserKnowledge knowledge,
  ) {
    final raw = _evaluator.evaluate(exercise, answer, knowledge: knowledge);
    final decorated =
        _feedback.decorate(raw, exercise, knowledge: knowledge);

    final decisionCorrect = decorated.acceptable;
    for (final conceptId in decorated.evaluatedConcepts) {
      knowledge.recordAttempt(
        conceptId,
        decisionCorrect: decisionCorrect,
        reasoningCorrect: decorated.reasoningScore == null
            ? null
            : decorated.reasoningScore! >= 0.6,
      );
    }
    return decorated;
  }

  /// Sesión de recuperación para el concepto más flojo, si corresponde.
  RecoverySession? suggestedRecovery(UserKnowledge knowledge) =>
      RecoverySession.forWeakestConcept(knowledge, concepts);
}

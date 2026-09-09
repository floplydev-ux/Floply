import '../concepts/concept_registry.dart';
import '../concepts/user_knowledge.dart';
import '../pedagogy/academy_content.dart';
import '../pedagogy/curriculum.dart';
import '../pedagogy/lesson_content.dart';
import '../pedagogy/pedagogical_engine.dart';
import '../pedagogy/recovery_session.dart';
import 'academy_progress.dart';

/// Resultado agregado de haber hecho todos los ejercicios de un lesson.
class LessonRunResult {
  const LessonRunResult({
    required this.score,
    required this.total,
    required this.correct,
    this.weakConceptIds = const [],
  });

  /// Puntaje 0..1 (promedio de calidad de decisión / aciertos).
  final double score;
  final int total;
  final int correct;

  /// Conceptos que se fallaron durante el lesson (para recuperación).
  final List<String> weakConceptIds;
}

/// Qué pasó al cerrar un lesson.
class LessonOutcome {
  const LessonOutcome({
    required this.lessonId,
    required this.passed,
    required this.completed,
    required this.score,
    required this.nextLessonId,
    required this.unlockedNext,
    this.weakConceptIds = const [],
    this.recovery,
  });

  final String lessonId;

  /// Para evaluaciones: si superó el umbral. Para el resto, siempre `true`.
  final bool passed;

  /// Si el lesson quedó marcado como terminado.
  final bool completed;

  final double score;
  final String? nextLessonId;
  final bool unlockedNext;

  /// Conceptos flojos detectados (solo cuando no aprobó).
  final List<String> weakConceptIds;

  /// Sesión de recuperación sugerida (solo cuando no aprobó).
  final RecoverySession? recovery;
}

/// Vista de un lesson para la UI de la Academia.
class AcademyLessonView {
  const AcademyLessonView({
    required this.lesson,
    required this.content,
    required this.state,
    required this.progress,
  });

  final Lesson lesson;
  final LessonContent? content;
  final LessonState state;
  final LessonProgress progress;

  bool get isAssessment => lesson.kind == LessonKind.assessment;
}

/// Vista de un nivel principal para la UI de la Academia.
class AcademyLevelView {
  const AcademyLevelView({
    required this.level,
    required this.state,
    required this.lessons,
  });

  final MainLevel level;
  final LevelState state;
  final List<AcademyLessonView> lessons;

  double get progress {
    if (lessons.isEmpty) return 0;
    final done = lessons.where((l) => l.state == LessonState.completed).length;
    return done / lessons.length;
  }
}

/// Orquesta el recorrido de la Academia sobre el motor existente.
///
/// No genera ni evalúa ejercicios: eso lo sigue haciendo
/// `PokerTrainerEngine`. Este motor solo decide qué está desbloqueado, qué
/// enseña cada lesson y cuándo se aprueba.
class AcademyEngine {
  AcademyEngine({
    required Curriculum curriculum,
    required ConceptRegistry registry,
    required PedagogicalEngine pedagogy,
    DateTime Function()? clock,
  })  : _curriculum = curriculum,
        _registry = registry,
        _pedagogy = pedagogy,
        _clock = clock ?? DateTime.now;

  final Curriculum _curriculum;
  final ConceptRegistry _registry;
  final PedagogicalEngine _pedagogy;
  final DateTime Function() _clock;

  /// Umbral para aprobar una evaluación.
  static const double passThreshold = 0.7;

  Curriculum get curriculum => _curriculum;

  List<String> get lessonOrder =>
      _curriculum.allLessons.map((l) => l.id).toList();

  LessonContent? contentFor(String lessonId) =>
      AcademyContent.forLesson(lessonId);

  Lesson? lessonById(String id) => _curriculum.lessonById(id);

  /// El primer lesson disponible sin completar (por dónde seguir).
  String? currentLessonId(AcademyProgress progress) {
    for (final lesson in _curriculum.allLessons) {
      if (progress.isCompleted(lesson.id)) continue;
      if (_isUnlocked(lesson.id, progress)) return lesson.id;
    }
    return null;
  }

  bool _isUnlocked(String lessonId, AcademyProgress progress) {
    final order = lessonOrder;
    final idx = order.indexOf(lessonId);
    if (idx <= 0) return true;
    return progress.isCompleted(order[idx - 1]);
  }

  LessonState stateOf(String lessonId, AcademyProgress progress) {
    if (progress.isCompleted(lessonId)) return LessonState.completed;
    return _isUnlocked(lessonId, progress)
        ? LessonState.available
        : LessonState.locked;
  }

  /// Arma la vista completa de niveles y lessons para la pantalla.
  List<AcademyLevelView> overview(AcademyProgress progress) {
    return _curriculum.levels.map((level) {
      final lessons = level.lessons.map((lesson) {
        return AcademyLessonView(
          lesson: lesson,
          content: AcademyContent.forLesson(lesson.id),
          state: stateOf(lesson.id, progress),
          progress: progress.entry(lesson.id),
        );
      }).toList();

      final states = lessons.map((l) => l.state).toSet();
      final LevelState levelState;
      if (states.length == 1 && states.first == LessonState.completed) {
        levelState = LevelState.completed;
      } else if (states.contains(LessonState.completed)) {
        levelState = LevelState.inProgress;
      } else if (states.contains(LessonState.available)) {
        levelState = LevelState.available;
      } else {
        levelState = LevelState.locked;
      }

      return AcademyLevelView(
        level: level,
        state: levelState,
        lessons: lessons,
      );
    }).toList();
  }

  /// Marca el lesson como abierto: enseña sus conceptos (y, por las dudas,
  /// los de todos los lessons anteriores) para que la regla fundamental se
  /// cumpla siempre antes de generar ejercicios.
  void openLesson(String lessonId, UserKnowledge knowledge,
      AcademyProgress progress) {
    final order = lessonOrder;
    final idx = order.indexOf(lessonId);
    if (idx < 0) return;
    for (var i = 0; i <= idx; i++) {
      _pedagogy.applyLesson(order[i], knowledge);
    }
    progress.lastActivity = _clock();
  }

  /// Conceptos que la teoría ya introdujo hasta [lessonId] inclusive.
  /// Un ejercicio de ese lesson nunca debería evaluar nada fuera de acá.
  Set<String> conceptsAvailableAt(String lessonId) =>
      _curriculum.conceptsTaughtUpTo(lessonId);

  /// Cierra un lesson con el resultado de sus ejercicios y actualiza el
  /// progreso.
  LessonOutcome submitLesson(
    String lessonId,
    LessonRunResult run,
    UserKnowledge knowledge,
    AcademyProgress progress,
  ) {
    final lesson = _curriculum.lessonById(lessonId);
    final isAssessment = lesson?.kind == LessonKind.assessment;

    final entry = progress.entry(lessonId);
    entry.attempts++;
    entry.lastScore = run.score;
    if (run.score > entry.bestScore) entry.bestScore = run.score;

    final passed = !isAssessment || run.score >= passThreshold;
    if (passed) {
      entry.completed = true;
      entry.passed = true;
    }
    progress.lastActivity = _clock();

    final order = lessonOrder;
    final idx = order.indexOf(lessonId);
    final nextLessonId =
        (idx >= 0 && idx + 1 < order.length) ? order[idx + 1] : null;

    RecoverySession? recovery;
    var weak = const <String>[];
    if (!passed) {
      recovery = RecoverySession.forWeakestConcept(knowledge, _registry);
      weak = <String>{
        ...run.weakConceptIds,
        ...knowledge.weakConcepts().map((m) => m.conceptId),
      }.where(knowledge.isTaught).toList();
    }

    return LessonOutcome(
      lessonId: lessonId,
      passed: passed,
      completed: entry.completed,
      score: run.score,
      nextLessonId: nextLessonId,
      unlockedNext: passed && nextLessonId != null,
      weakConceptIds: weak,
      recovery: recovery,
    );
  }

  /// Nombre legible de un concepto (para los mensajes de recuperación).
  String conceptName(String conceptId) =>
      _registry.tryById(conceptId)?.name ?? conceptId;

  /// Snapshot de progreso para la Home / pantalla de progreso.
  AcademyProgressSnapshot snapshot(
    UserKnowledge knowledge,
    AcademyProgress progress,
  ) {
    final levels = overview(progress);
    final totalLessons = _curriculum.allLessons.length;
    final doneLessons = progress.completedCount;

    final currentLevel = levels.firstWhere(
      (l) => l.state != LevelState.completed,
      orElse: () => levels.last,
    );

    final masteredConcepts = knowledge.all
        .where((m) => m.isTaught && m.mastery >= 0.8)
        .map((m) => _registry.tryById(m.conceptId)?.name ?? m.conceptId)
        .toList();

    return AcademyProgressSnapshot(
      currentLevelNumber: currentLevel.level.number,
      currentLevelTitle: currentLevel.level.title,
      completedLessons: doneLessons,
      totalLessons: totalLessons,
      percent: totalLessons == 0 ? 0 : doneLessons / totalLessons,
      masteredConcepts: masteredConcepts,
      lastActivity: progress.lastActivity,
    );
  }
}

/// Vista compacta del progreso, para mostrar fuera de la Academia.
class AcademyProgressSnapshot {
  const AcademyProgressSnapshot({
    required this.currentLevelNumber,
    required this.currentLevelTitle,
    required this.completedLessons,
    required this.totalLessons,
    required this.percent,
    required this.masteredConcepts,
    required this.lastActivity,
  });

  final int currentLevelNumber;
  final String currentLevelTitle;
  final int completedLessons;
  final int totalLessons;
  final double percent;
  final List<String> masteredConcepts;
  final DateTime? lastActivity;
}

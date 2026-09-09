/// Estado de un sub-nivel para el usuario.
enum LessonState {
  /// Todavía no se puede abrir (falta completar el anterior).
  locked,

  /// Disponible para hacer ahora.
  available,

  /// Terminado (y, si era evaluación, aprobado).
  completed,
}

/// Estado de un nivel principal, derivado del de sus lessons.
enum LevelState { locked, available, inProgress, completed }

/// Progreso del usuario en un lesson concreto.
class LessonProgress {
  LessonProgress({
    required this.lessonId,
    this.completed = false,
    this.attempts = 0,
    this.bestScore = 0,
    this.lastScore = 0,
    this.passed = false,
  });

  final String lessonId;

  /// `true` cuando el lesson quedó terminado y desbloquea el siguiente.
  bool completed;

  /// Cuántas veces se hizo el lesson (relevante en evaluaciones que se
  /// pueden reintentar).
  int attempts;

  /// Mejor puntaje obtenido (0..1).
  double bestScore;

  /// Puntaje del último intento (0..1).
  double lastScore;

  /// Para evaluaciones: si se superó el umbral de aprobación.
  bool passed;

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'completed': completed,
        'attempts': attempts,
        'bestScore': bestScore,
        'lastScore': lastScore,
        'passed': passed,
      };

  factory LessonProgress.fromJson(Map<String, dynamic> json) => LessonProgress(
        lessonId: json['lessonId'] as String,
        completed: json['completed'] as bool? ?? false,
        attempts: json['attempts'] as int? ?? 0,
        bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0,
        lastScore: (json['lastScore'] as num?)?.toDouble() ?? 0,
        passed: json['passed'] as bool? ?? false,
      );
}

/// Todo el progreso del usuario en la Academia (aparte de su
/// [UserKnowledge], que guarda el dominio por concepto).
///
/// Serializable a JSON, sin base de datos.
class AcademyProgress {
  AcademyProgress({
    Map<String, LessonProgress>? lessons,
    this.lastActivity,
  }) : _lessons = lessons ?? {};

  final Map<String, LessonProgress> _lessons;
  DateTime? lastActivity;

  Iterable<LessonProgress> get all => _lessons.values;

  LessonProgress entry(String lessonId) => _lessons.putIfAbsent(
        lessonId,
        () => LessonProgress(lessonId: lessonId),
      );

  bool isCompleted(String lessonId) => _lessons[lessonId]?.completed ?? false;

  int get completedCount =>
      _lessons.values.where((l) => l.completed).length;

  Map<String, dynamic> toJson() => {
        'lastActivity': lastActivity?.toIso8601String(),
        'lessons': {
          for (final e in _lessons.entries) e.key: e.value.toJson(),
        },
      };

  factory AcademyProgress.fromJson(Map<String, dynamic> json) {
    final raw = (json['lessons'] as Map<String, dynamic>? ?? {});
    return AcademyProgress(
      lastActivity: (json['lastActivity'] as String?) != null
          ? DateTime.tryParse(json['lastActivity'] as String)
          : null,
      lessons: {
        for (final e in raw.entries)
          e.key: LessonProgress.fromJson(e.value as Map<String, dynamic>),
      },
    );
  }
}

import 'scripts/level_1_exercises.dart';
import 'scripts/level_2_exercises.dart';
import 'scripts/level_5_exercises.dart';
import 'table_exercise.dart';

/// Agregador de los **ejercicios interactivos sobre la mesa**.
///
/// El contenido real vive por nivel en `scripts/level_N_exercises.dart`.
/// Si un lesson tiene un set acá, sus ejercicios usan
/// `InteractiveTableExercise` en vez de `ExerciseCard`; los que no, siguen
/// con el motor / las preguntas autorales como antes.
class AcademyExerciseScripts {
  AcademyExerciseScripts._();

  static InteractiveExerciseSet? forLesson(String lessonId) => _byId[lessonId];

  static bool has(String lessonId) => _byId.containsKey(lessonId);

  /// Todos los lessonId con set de ejercicios interactivos.
  static Iterable<String> get lessonIds => _byId.keys;

  static Map<String, InteractiveExerciseSet> get all => Map.unmodifiable(_byId);

  static final Map<String, InteractiveExerciseSet> _byId = {
    ...Level1Exercises.byId,
    ...Level2Exercises.byId,
    ...Level5Exercises.byId,
  };
}

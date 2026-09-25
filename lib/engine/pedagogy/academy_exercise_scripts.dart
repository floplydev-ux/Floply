import 'scripts/level_1_exercises.dart';
import 'scripts/level_2_exercises.dart';
import 'scripts/level_3_exercises.dart';
import 'scripts/level_4_exercises.dart';
import 'scripts/level_5_exercises.dart';
import 'scripts/n1_pilot_exercises.dart';
import 'scripts/n5_exercises.dart';
import 'scripts/n6_exercises.dart';
import 'scripts/n7_exercises.dart';
import 'scripts/n8_exercises.dart';
import 'scripts/n9_exercises.dart';
import 'scripts/n10_exercises.dart';
import 'scripts/n11_exercises.dart';
import 'scripts/n12_exercises.dart';
import 'scripts/n13_exercises.dart';
import 'table_exercise.dart';
import 'theory.dart';

/// **Ejercicios interactivos sobre la mesa.**
///
/// Dos fuentes, resueltas por [forLesson] con el mismo código de subnivel:
///  1. **Autorados directo por subnivel** (PASO 4, N5-N13): cada
///     `scripts/nX_exercises.dart` expone `byId['5.1']` etc., ya con el
///     código de subnivel NUEVO — sin legacy, porque N5-N13 no vienen del
///     documento maestro de 308 temas.
///  2. **Heredados de lecciones históricas** (N1-N3 y 7.2): el contenido
///     vive en `scripts/level_N_exercises.dart`, keyado por id histórico
///     (`'1.1'`…), y [forLesson] lo resuelve vía `legacy.exercise_sets`
///     del `curriculum_spec.json`; si hereda varios, se concatenan.
class AcademyExerciseScripts {
  AcademyExerciseScripts._();

  static final CurriculumSpec _spec = CurriculumSpec.standard();

  static InteractiveExerciseSet? forLesson(String sublevelCode) {
    // El legado (re-anclado desde una lección histórica, p. ej. 7.2 ←
    // "5.4") tiene prioridad: ya existía, ya está probado, y evita que un
    // set nuevo de PASO 4 lo tape por accidente en el único subnivel de
    // N5-N13 que lo hereda.
    final ids = _spec.sublevelByCode(sublevelCode)?.legacy?.exerciseSets ??
        const <String>[];
    if (ids.isNotEmpty) {
      final exercises = <InteractiveTableExercise>[
        for (final id in ids) ...?_byOldId[id]?.exercises,
      ];
      if (exercises.isNotEmpty) return InteractiveExerciseSet(exercises);
    }

    final direct = _bySublevel[sublevelCode];
    return (direct != null && direct.exercises.isNotEmpty) ? direct : null;
  }

  static bool has(String sublevelCode) => forLesson(sublevelCode) != null;

  /// Set crudo de una lección histórica (`"2.2"`…). Para el resolver / tests.
  static InteractiveExerciseSet? byOldId(String oldLessonId) =>
      _byOldId[oldLessonId];

  /// Mapa crudo de sets históricos (id histórico → set). Para validación.
  static Map<String, InteractiveExerciseSet> get all => Map.unmodifiable(_byOldId);

  /// Todos los subniveles nuevos con set de ejercicios interactivos.
  static Iterable<String> get sublevelsWithSet => [
        for (final s in _spec.allSublevels)
          if (has(s.code)) s.code,
      ];

  /// Alias histórico de [sublevelsWithSet].
  static Iterable<String> get lessonIds => sublevelsWithSet;

  static final Map<String, InteractiveExerciseSet> _byOldId = {
    ...Level1Exercises.byId,
    ...Level2Exercises.byId,
    ...Level3Exercises.byId,
    ...Level5Exercises.byId,
  };

  /// PASO 4 (N5-N13) + el piloto de 3 bloques de 1.1 (Fase 3.1): sets
  /// autorados directo por subnivel nuevo, sin legacy de por medio.
  static final Map<String, InteractiveExerciseSet> _bySublevel = {
    ...N1PilotExercises.byId,
    ...Level4Exercises.byId,
    ...N5Exercises.byId,
    ...N6Exercises.byId,
    ...N7Exercises.byId,
    ...N8Exercises.byId,
    ...N9Exercises.byId,
    ...N10Exercises.byId,
    ...N11Exercises.byId,
    ...N12Exercises.byId,
    ...N13Exercises.byId,
  };
}

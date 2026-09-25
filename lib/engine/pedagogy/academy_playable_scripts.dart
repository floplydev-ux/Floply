import 'playable_exercise.dart';
import 'scripts/playable_pilot_exercises.dart';

/// **Ejercicios jugables sobre la mesa.**
///
/// Registro paralelo a [AcademyExerciseScripts], mismo patrón `forLesson`
/// por código de subnivel. Deliberadamente simple: a diferencia del
/// registro de ejercicios interactivos, no resuelve legado de lecciones
/// históricas — todo el contenido jugable es nuevo, autorado directo por
/// subnivel actual.
///
/// Un subnivel con set acá "tapa" (en `AcademyController._buildItems`) su
/// set equivalente en `AcademyExerciseScripts`, si lo tenía — el contenido
/// viejo no se borra, solo deja de usarse en runtime. Migrar de vuelta (o
/// deshacer el piloto) es tan simple como sacar la entrada de acá.
class AcademyPlayableScripts {
  AcademyPlayableScripts._();

  static PlayableExerciseSet? forLesson(String sublevelCode) {
    final set = byId[sublevelCode];
    return (set != null && set.exercises.isNotEmpty) ? set : null;
  }

  static bool has(String sublevelCode) => forLesson(sublevelCode) != null;

  static final Map<String, PlayableExerciseSet> byId = {
    ...PlayablePilotExercises.byId,
  };
}

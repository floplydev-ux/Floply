import 'scripts/level_1_lessons.dart';
import 'scripts/level_2_lessons.dart';
import 'scripts/level_3_lessons.dart';
import 'scripts/level_4_lessons.dart';
import 'scripts/level_5_lessons.dart';
import 'table_lesson.dart';
import 'theory.dart';

/// Guiones de **teoría interactiva sobre la mesa**.
///
/// El contenido vive por nivel histórico en `scripts/level_N_lessons.dart`.
/// Durante la migración al currículo de 326 teorías, [forLesson] recibe un
/// **código de subnivel nuevo** y devuelve el guion que ese subnivel hereda
/// (campo `legacy.table_scripts` del `curriculum_spec.json`). Si un subnivel
/// hereda varios guiones, por ahora se muestra el primero; el resto se
/// integra al redactar el contenido (PASO 4).
///
/// Convención de asientos: slot 0 = héroe abajo-centro; orden preflop
/// recorre 0 → 5 → 4 → 3 → 2 → 1.
class AcademyTableScripts {
  AcademyTableScripts._();

  static final CurriculumSpec _spec = CurriculumSpec.standard();

  /// Subniveles migrados al flujo canónico (mesa DESPUÉS de la teoría).
  /// Para estos, [forLesson] devuelve null — [isInteractiveTheory] nunca se
  /// activa — y el contenido se sirve vía [migratedClosingFor] al
  /// [AcademyClosingExamples], que lo muestra en la posición de cierre.
  static const _migrated = {
    '2.1', '3.1', '3.3', '3.4', '3.5',
    '5.1', '5.2', '5.3', '5.5',
  };

  static TableLessonScript? forLesson(String sublevelCode) {
    if (_migrated.contains(sublevelCode)) return null;
    final scripts = _spec.sublevelByCode(sublevelCode)?.legacy?.tableScripts ??
        const <String>[];
    if (scripts.isEmpty) return null;
    return _byOldId[scripts.first];
  }

  static bool has(String sublevelCode) => forLesson(sublevelCode) != null;

  /// Guion legacy de un subnivel migrado, para ser mostrado como ejemplo de
  /// cierre (DESPUÉS de la teoría) por [AcademyClosingExamples].
  /// Distinto de [forLesson]: devuelve el script aunque el subnivel esté
  /// en [_migrated], precisamente porque en esa posición sí debe mostrarse.
  static TableLessonScript? migratedClosingFor(String sublevelCode) {
    if (!_migrated.contains(sublevelCode)) return null;
    final scripts = _spec.sublevelByCode(sublevelCode)?.legacy?.tableScripts ??
        const <String>[];
    if (scripts.isEmpty) return null;
    return _byOldId[scripts.first];
  }

  /// Guion crudo de una lección histórica (`"1.1"`…). Para el resolver / tests.
  static TableLessonScript? byOldId(String oldLessonId) => _byOldId[oldLessonId];

  /// Mapa crudo de guiones históricos (id histórico → guion). Para validación.
  static Map<String, TableLessonScript> get all => Map.unmodifiable(_byOldId);

  /// Todos los subniveles nuevos con guion de teoría interactiva.
  static Iterable<String> get sublevelsWithScript => [
        for (final s in _spec.allSublevels)
          if (has(s.code)) s.code,
      ];

  /// Alias histórico de [sublevelsWithScript].
  static Iterable<String> get lessonIds => sublevelsWithScript;

  static final Map<String, TableLessonScript> _byOldId = {
    ...Level1Lessons.byId,
    ...Level2Lessons.byId,
    ...Level3Lessons.byId,
    ...Level4Lessons.byId,
    ...Level5Lessons.byId,
  };
}

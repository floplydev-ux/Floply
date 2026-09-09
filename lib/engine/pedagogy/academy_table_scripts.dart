import 'scripts/level_1_lessons.dart';
import 'scripts/level_2_lessons.dart';
import 'scripts/level_3_lessons.dart';
import 'scripts/level_4_lessons.dart';
import 'scripts/level_5_lessons.dart';
import 'table_lesson.dart';

/// Agregador de las **lecciones de teoría interactiva sobre la mesa**.
///
/// El contenido real vive por nivel en `scripts/level_N_lessons.dart`
/// (usan `TableScript` de `scripts/script_builders.dart`). Acá solo se
/// juntan y se expone la API que consume `AcademyController`.
///
/// Convención de asientos: slot 0 = héroe abajo-centro; orden preflop
/// recorre 0 → 5 → 4 → 3 → 2 → 1.
class AcademyTableScripts {
  AcademyTableScripts._();

  static TableLessonScript? forLesson(String lessonId) => _byId[lessonId];

  static bool has(String lessonId) => _byId.containsKey(lessonId);

  /// Todos los lessonId con guion de teoría interactiva.
  static Iterable<String> get lessonIds => _byId.keys;

  static Map<String, TableLessonScript> get all => Map.unmodifiable(_byId);

  static final Map<String, TableLessonScript> _byId = {
    ...Level1Lessons.byId,
    ...Level2Lessons.byId,
    ...Level3Lessons.byId,
    ...Level4Lessons.byId,
    ...Level5Lessons.byId,
  };
}

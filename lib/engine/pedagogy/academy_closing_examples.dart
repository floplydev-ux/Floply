import 'scripts/closing_example_lessons.dart';
import 'table_lesson.dart';

/// Registro de **ejemplos de cierre** (Bloque B del piloto de 3 bloques,
/// Fase 3.1) por código de SUBNIVEL — no por teoría, a diferencia de
/// [AcademyMentorLessons]/[AcademyVisualTheories]: un ejemplo de cierre
/// demuestra todas las teorías del subnivel juntas, no una sola.
///
/// Se muestra DESPUÉS de que terminan las fichas de teoría escrita del
/// subnivel y ANTES de sus ejercicios (ver
/// `AcademyController.isClosingExample`). Activar/desactivar el patrón en
/// otro subnivel es, literalmente, agregarlo o quitarlo de este mapa.
class AcademyClosingExamples {
  AcademyClosingExamples._();

  static TableLessonScript? forLesson(String sublevelCode) =>
      _byId[sublevelCode];

  static bool has(String sublevelCode) => _byId.containsKey(sublevelCode);

  static final Map<String, TableLessonScript> _byId = {
    '1.1': ClosingExampleLessons.objetivoYCartas(),
    '1.2': ClosingExampleLessons.ganarLaMano(),
    '1.3': ClosingExampleLessons.lasAcciones(),
  };
}

import 'visual_pilot_lessons.dart';
import 'visual_theory.dart';

/// Registro de **lecciones visuales** por id de teoría (`"T093"`).
///
/// Piloto: solo las 4 teorías de prueba (T093, T082, T098, T099). El resto
/// de las 326 teorías no tiene entrada acá — [forTheory] devuelve `null` y
/// la Academia sigue exactamente igual que hoy (ficha de teoría escrita
/// directa, sin pasar por la experiencia visual).
///
/// Activar/desactivar el modo visual de una teoría es, literalmente,
/// agregarla o quitarla de este mapa: no hace falta tocar el controller ni
/// el currículo.
class AcademyVisualTheories {
  AcademyVisualTheories._();

  static VisualTheoryLesson? forTheory(String theoryId) => _byId[theoryId];

  static bool has(String theoryId) => _byId.containsKey(theoryId);

  static final Map<String, VisualTheoryLesson> _byId = {
    'T093': VisualPilotLessons.set(),
    'T082': VisualPilotLessons.draws(),
    'T098': VisualPilotLessons.nuts(),
    'T099': VisualPilotLessons.nearNuts(),
  };
}

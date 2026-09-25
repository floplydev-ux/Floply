import 'mentor_lesson.dart';
import 'mentor_lessons_n1.dart';
import 'mentor_pilot_lessons.dart';

/// Registro de **clases de mentor** por id de teoría (`"T020"`).
///
/// Piloto de la Fase 3 (transformación pedagógica "libro → mentor"): las 10
/// teorías confirmadas por el usuario. El resto de las 326 no tiene entrada
/// acá — [forTheory] devuelve `null` y la Academia sigue exactamente igual
/// que hoy (piloto visual si corresponde, si no ficha de teoría escrita).
///
/// Activar/desactivar la clase de mentor de una teoría es, literalmente,
/// agregarla o quitarla de este mapa: no hace falta tocar el controller ni
/// el currículo (mismo patrón que [AcademyVisualTheories], que se mantiene
/// intacto y sin migrar en esta fase — ver el informe final).
class AcademyMentorLessons {
  AcademyMentorLessons._();

  static MentorLesson? forTheory(String theoryId) => _byId[theoryId];

  static bool has(String theoryId) => _byId.containsKey(theoryId);

  static final Map<String, MentorLesson> _byId = {
    // --- N1 "Cómo funciona una mano" (7/25) ---
    // T001-T005 (1.1), T008-T010 (1.2) y T033-T042 (1.3) migraron al piloto
    // de 3 bloques (teoría escrita + ejemplo de mesa + ejercicios, ver
    // `academy_closing_examples.dart` / `scripts/n1_pilot_exercises.dart`):
    // ya no tienen clase de mentor, así que 1.1/1.2/1.3 usan
    // `WrittenTheoryView` igual que cualquier teoría sin migrar (mismo
    // patrón que 4.1).
    'T043': MentorLessonsN1.elPreflop(),
    'T044': MentorLessonsN1.elFlop(),
    'T045': MentorLessonsN1.elTurn(),
    'T046': MentorLessonsN1.elRiver(),
    'T047': MentorLessonsN1.laRondaDeApuestas(),
    'T048': MentorLessonsN1.cambioDeInformacion(),
    'T049': MentorLessonsN1.elFinDeLaMano(),

    'T051': MentorPilotLessons.pareja(),
    'T020': MentorPilotLessons.estarEnPosicion(),
    'T073': MentorPilotLessons.manoDominada(),
    'T139': MentorPilotLessons.rfi(),
    'T108': MentorPilotLessons.reglaDel2(),
    'T109': MentorPilotLessons.reglaDel4(),
    'T175': MentorPilotLessons.cbet(),
    'T190': MentorPilotLessons.scareCard(),
    'T224': MentorPilotLessons.ventajaDeRango(),
    'T308': MentorPilotLessons.decisionIntegrada(),
  };
}

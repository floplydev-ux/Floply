/// Helper único para recorrer una clase de mentor por UI en los tests.
///
/// Nace de la Fase 3: seis sitios en cinco archivos de test tenían el mismo
/// parche copiado a mano para saber tocar la opción correcta de una
/// comprobación en vez de "CONTINUAR" a ciegas. Si la UX del mentor vuelve a
/// cambiar, este es el único lugar a actualizar — no hace falta volver a
/// tocar cada test que camina una lección.
///
/// No sabe nada de currículo ni de contenido: solo entiende los dos tipos de
/// turno (`MentorSayBeat` / `MentorCheckBeat`) y cómo el controller expone
/// su estado (`isMentorLesson`, `currentMentorBeat`, `mentorCheckAnswer`,
/// `mentorContinueLabel`, `answerMentorCheck`, `nextMentorBeat`,
/// `prevMentorBeat`).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/mentor_lesson.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';

/// Avanza la fase teoría del [controller] hasta que la teoría activa sea
/// [theoryId] Y ya se haya dejado atrás cualquier guion de mesa heredado
/// que la preceda (si `currentWrittenTheory` ya vale [theoryId] pero
/// `isInteractiveTheory` sigue `true`, todavía no llegamos de verdad —
/// ver Fase 3, BUG-1).
///
/// Funciona igual sin importar si [theoryId] termina mostrándose con clase
/// de mentor, piloto visual o ficha escrita: solo posiciona, no responde
/// preguntas por vos (para eso, [walkMentorTheoryByUi]).
Future<void> fastForwardToTheory(
  WidgetTester tester,
  AcademyController c,
  String theoryId, {
  int maxSteps = 120,
}) async {
  var guard = 0;
  while ((c.currentWrittenTheory?.id != theoryId || c.isInteractiveTheory) &&
      guard++ < maxSteps) {
    c.advanceTheory();
    await tester.pump();
  }
  expect(c.currentWrittenTheory?.id, theoryId, reason: 'no llegó a $theoryId');
  expect(c.isInteractiveTheory, isFalse,
      reason: 'se quedó en el guion de mesa heredado de camino a $theoryId');
}

/// Toca, en el turno actual, la opción/botón que corresponda:
///  * [MentorCheckBeat] sin responder → toca la opción en el índice
///    [optionIndex] (por defecto la primera; pasá el índice de la mejor si
///    te importa cuál).
///  * cualquier otro caso (turno de habla, o comprobación ya respondida) →
///    toca el botón de avance (`c.mentorContinueLabel`: "CONTINUAR" o
///    "PRACTICAR" en el último turno del subnivel).
Future<void> tapMentorAdvance(
  WidgetTester tester,
  AcademyController c, {
  int optionIndex = 0,
}) async {
  final beat = c.currentMentorBeat;
  final label = (beat is MentorCheckBeat && c.mentorCheckAnswer == null)
      ? beat.check.options[optionIndex].label
      : c.mentorContinueLabel;
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Recorre por UI (tocando los botones reales) TODOS los turnos de la clase
/// de mentor de la teoría que está mostrando ahora [c] — y solo esa: se
/// detiene apenas la teoría cambia, aunque el mentor siga activo para la
/// SIGUIENTE (dos teorías piloto pueden encadenarse sin ficha escrita en el
/// medio — ver Fase 3, T108→T109).
///
/// Devuelve la cantidad de turnos recorridos. Falla el test si no hay
/// clase de mentor activa, o si se excede [maxBeats] (señal de que algo no
/// avanza — mismo espíritu que el guard de la Fase 3, para no colgar la
/// suite si aparece un bug nuevo de la misma familia que BUG-1).
Future<int> walkMentorTheoryByUi(
  WidgetTester tester,
  AcademyController c, {
  int? maxBeats,
}) async {
  expect(c.isMentorLesson, isTrue,
      reason: 'walkMentorTheoryByUi: no hay clase de mentor activa');
  final targetId = c.currentWrittenTheory?.id;
  final total = c.mentorBeatCount;
  expect(total, greaterThan(0));
  final cap = maxBeats ?? (total * 2 + 6);

  var walked = 0;
  while (c.isMentorLesson &&
      c.currentWrittenTheory?.id == targetId &&
      walked++ < cap) {
    await tapMentorAdvance(tester, c);
    expect(tester.takeException(), isNull,
        reason: '$targetId turno $walked');
  }
  expect(walked, lessThan(cap),
      reason: '$targetId no terminó sus turnos (¿se colgó?)');
  return walked;
}

/// Combina las dos anteriores: avanza hasta [theoryId] y recorre toda su
/// clase de mentor. Uso típico en un test de "teoría por teoría":
/// ```dart
/// await fastForwardAndWalkMentor(tester, c, 'T020');
/// expect(c.currentWrittenTheory?.id, isNot('T020')); // ya avanzó
/// ```
Future<void> fastForwardAndWalkMentor(
  WidgetTester tester,
  AcademyController c,
  String theoryId,
) async {
  await fastForwardToTheory(tester, c, theoryId);
  await walkMentorTheoryByUi(tester, c);
}

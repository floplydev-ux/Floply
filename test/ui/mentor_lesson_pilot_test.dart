import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/mentor_lesson.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

/// Piloto de la Fase 3 (transformación pedagógica "libro → mentor"): las
/// teorías confirmadas (T051, T020, T073, T139, T108, T109, T175, T190,
/// T224, T308 — T001 migró en la Fase 3.1 al piloto de 3 bloques de 1.1 y
/// ya no tiene clase de mentor, ver `academy_1_1_pilot_test.dart`).
/// Verifica que la clase de mentor se muestra, se puede recorrer sin
/// excepciones/overflow, respeta "no se puede avanzar una comprobación sin
/// responder", y REEMPLAZA (no precede) la ficha escrita de esa teoría
/// puntual — a diferencia del piloto visual, que la antecede.
void main() {
  AcademyProgress upTo(String target) {
    final p = AcademyProgress();
    for (final id in Curriculum.lessonOrder) {
      if (id == target) break;
      p.entry(id).completed = true;
    }
    return p;
  }

  Future<AcademyController> open(
    WidgetTester tester,
    String sublevelId, {
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final c = AcademyController(
      engine: PokerTrainerEngine(seed: 11),
      store: InMemoryAcademyStore(),
      userName: 'Ada',
    );
    await c.load();
    c.progress = upTo(sublevelId);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.openLesson(sublevelId);
    await tester.pumpAndSettle();
    return c;
  }

  /// Avanza la fase teoría (controller-driven) hasta que la teoría
  /// redactada activa sea [theoryId] — funciona igual para teorías con
  /// clase de mentor, piloto visual o ficha escrita, porque
  /// `currentWrittenTheory` sigue la posición en el subnivel sin importar
  /// cuál sub-experiencia se esté mostrando.
  Future<void> fastForwardTo(
      WidgetTester tester, AcademyController c, String theoryId) async {
    var guard = 0;
    // `currentWrittenTheory` ya apunta a la teoría objetivo desde el primer
    // instante si esa teoría es la primera del subnivel (writtenTheoryStep
    // arranca en 0) — eso NO significa que ya se esté mostrando: si el
    // subnivel tiene guion de mesa heredado (`isInteractiveTheory`), todavía
    // hay que terminarlo antes de que se dispare la clase de mentor/ficha
    // escrita de esa teoría. Por eso el corte espera las dos condiciones.
    while ((c.currentWrittenTheory?.id != theoryId || c.isInteractiveTheory) &&
        guard++ < 80) {
      c.advanceTheory();
      await tester.pump();
    }
    expect(c.currentWrittenTheory?.id, theoryId,
        reason: 'no llegó a $theoryId');
    expect(c.isInteractiveTheory, isFalse,
        reason: 'se quedó en el guion de mesa heredado de camino a $theoryId');
  }

  /// Recorre por UI (tocando los botones reales) todos los turnos de la
  /// clase de mentor activa: si el turno es una pregunta, toca la primera
  /// opción antes de poder continuar. Se detiene al terminar la teoría
  /// actual — importante porque dos teorías piloto consecutivas (T108 →
  /// T109) pueden entrar en modo mentor una atrás de la otra sin pasar por
  /// una ficha escrita en el medio: sin este límite, un solo llamado se
  /// comería las dos.
  Future<void> walkMentorByUi(WidgetTester tester, AcademyController c) async {
    expect(c.isMentorLesson, isTrue);
    final targetId = c.currentWrittenTheory?.id;
    final total = c.mentorBeatCount;
    expect(total, greaterThan(0));

    var guard = 0;
    while (c.isMentorLesson &&
        c.currentWrittenTheory?.id == targetId &&
        guard++ < total * 2 + 6) {
      expect(find.text('${c.mentorBeatIndex + 1} / ${c.mentorBeatCount}'),
          findsOneWidget);
      final beat = c.currentMentorBeat!;

      if (beat is MentorCheckBeat && c.mentorCheckAnswer == null) {
        await tester.tap(find.text(beat.check.options.first.label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'responder turno $guard');
        continue;
      }

      await tester.tap(find.text(c.mentorContinueLabel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'turno $guard');
    }
  }

  const pilots = <(String theoryId, String sublevel)>[
    ('T051', '2.1'),
    ('T020', '3.3'),
    ('T073', '4.2'),
    ('T139', '5.3'),
    ('T108', '6.3'),
    ('T109', '6.3'),
    ('T175', '8.1'),
    ('T190', '9.1'),
    ('T224', '11.1'),
    ('T308', '13.5'),
  ];

  for (final (theoryId, sublevel) in pilots) {
    testWidgets(
        '$theoryId: clase de mentor se recorre sin excepciones y reemplaza '
        'la ficha escrita', (tester) async {
      final c = await open(tester, sublevel);
      await fastForwardTo(tester, c, theoryId);

      expect(c.isMentorLesson, isTrue,
          reason: '$theoryId debería abrir en modo mentor');
      expect(c.isWrittenTheory, isFalse,
          reason: 'mientras se muestra el mentor, no debe mostrarse también '
              'la ficha escrita');

      await walkMentorByUi(tester, c);

      // Terminados los turnos, la clase de mentor REEMPLAZÓ la ficha
      // escrita de $theoryId: nunca debería llegar a mostrarse la ficha
      // estática de esta misma teoría (si $theoryId es la última del
      // subnivel, `currentWrittenTheory` sigue apuntando a ella incluso ya
      // en la fase de ejercicios — eso es esperado, no un fallo; lo que no
      // puede pasar es `isWrittenTheory` true para $theoryId).
      final stillShowingWrittenFicha =
          c.isWrittenTheory && c.currentWrittenTheory?.id == theoryId;
      expect(stillShowingWrittenFicha, isFalse,
          reason: 'la ficha escrita de $theoryId no debería mostrarse: la '
              'clase de mentor la reemplaza');
      // No debe seguir mostrando el mentor de ESTA teoría — pero sí puede
      // haber pasado, sin fricción, al mentor de la SIGUIENTE (T108 → T109
      // son piloto las dos, consecutivas, sin ficha escrita en el medio).
      final stuckOnThisMentor =
          c.isMentorLesson && c.currentWrittenTheory?.id == theoryId;
      expect(stuckOnThisMentor, isFalse,
          reason: 'debería haber avanzado más allá de la clase de mentor '
              'de $theoryId');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('T020: ATRÁS retrocede un turno y conserva la respuesta ya '
      'elegida de la comprobación', (tester) async {
    final c = await open(tester, '3.3');
    await fastForwardTo(tester, c, 'T020');
    expect(c.mentorBeatIndex, 0);

    // Turno 0 es de habla: CONTINUAR sin responder nada.
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(c.mentorBeatIndex, 1);

    // Turno 1 es la mini decisión ("¿Qué sabemos nosotros...?").
    final check = c.currentMentorBeat;
    expect(check, isA<MentorCheckBeat>());
    expect(c.mentorCheckAnswer, isNull);
    expect(find.text('CONTINUAR'), findsNothing,
        reason: 'no se puede continuar una pregunta sin responder');

    final bestLabel =
        (check as MentorCheckBeat).check.options.first.label;
    await tester.tap(find.text(bestLabel));
    await tester.pumpAndSettle();
    expect(c.mentorCheckAnswer, 0);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(c.mentorBeatIndex, 2);

    expect(find.text('ATRÁS'), findsOneWidget);
    await tester.tap(find.text('ATRÁS'));
    await tester.pumpAndSettle();
    expect(c.mentorBeatIndex, 1);
    // La respuesta elegida antes sigue guardada: se ve el feedback, no las
    // opciones de vuelta.
    expect(c.mentorCheckAnswer, 0);
    expect(find.text('CONTINUAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('T051: el subnivel 2.1 sigue teniendo T052 después, mostrado '
      'con la ficha escrita de siempre (coexistencia con teorías sin '
      'migrar — Fase 4 todavía no migró N2 completo)', (tester) async {
    // N1 completo (Fase 4, lote 1) ya migró T001-T049: no sirve más como
    // ejemplo de "teoría sin migrar" que le sigue a una piloteada. 2.1
    // sí: T051 (piloto de Fase 3) está migrada, pero T052 en adelante
    // todavía no (quedan para el lote N2).
    final c = await open(tester, '2.1');
    await fastForwardTo(tester, c, 'T051');
    await walkMentorByUi(tester, c);

    expect(c.currentWrittenTheory?.id, 'T052');
    expect(c.isMentorLesson, isFalse);
    expect(c.hasMentorLesson, isFalse);
    expect(c.isWrittenTheory, isTrue,
        reason: 'T052 no está migrada: debe seguir yendo a la ficha '
            'escrita, exactamente como antes de la Fase 3');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'T108 → T109: el puente entre las dos teorías se recorre completo '
      '(regla del 2 → regla del 4)', (tester) async {
    final c = await open(tester, '6.3');
    await fastForwardTo(tester, c, 'T108');
    await walkMentorByUi(tester, c);

    expect(c.currentWrittenTheory?.id, 'T109');
    expect(c.isMentorLesson, isTrue);
    await walkMentorByUi(tester, c);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teorías sin clase de mentor siguen exactamente igual que '
      'antes de la Fase 3', (tester) async {
    final c = await open(tester, '4.5');
    // T087 es la primera teoría de 4.5: no tiene mentor ni piloto visual.
    expect(c.currentWrittenTheory?.id, 'T087');
    expect(c.isMentorLesson, isFalse);
    expect(c.hasMentorLesson, isFalse);
    expect(c.isWrittenTheory, isTrue);
  });

  testWidgets('T001 (migrada a 1.1, Fase 3.1): ya NO tiene clase de mentor, '
      'usa la ficha escrita como cualquier teoría sin migrar', (tester) async {
    final c = await open(tester, '1.1');
    expect(c.currentWrittenTheory?.id, 'T001');
    expect(c.isMentorLesson, isFalse);
    expect(c.hasMentorLesson, isFalse);
    expect(c.isWrittenTheory, isTrue);
  });

  testWidgets('T093 (piloto visual, sin mentor) sigue funcionando igual: '
      'visual → ficha escrita de la MISMA teoría', (tester) async {
    final c = await open(tester, '4.5');
    await fastForwardTo(tester, c, 'T093');

    expect(c.isVisualTheory, isTrue);
    expect(c.isMentorLesson, isFalse);
    var guard = 0;
    while (c.isVisualTheory && guard++ < 10) {
      await tester
          .tap(find.text(c.currentVisualStep!.buttonLabel ?? 'CONTINUAR'));
      await tester.pumpAndSettle();
    }
    expect(c.isWrittenTheory, isTrue);
    expect(c.currentWrittenTheory?.id, 'T093',
        reason: 'el piloto visual sigue ANTECEDIENDO la ficha de la misma '
            'teoría — no lo tocó la Fase 3');
    expect(tester.takeException(), isNull);
  });
}

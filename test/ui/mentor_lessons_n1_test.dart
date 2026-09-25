import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/academy_mentor_lessons.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

import '../support/mentor_walk.dart';

/// Fase 4, lote N1: verifica que las teorías del nivel con clase de mentor
/// registrada se recorren por UI real sin excepciones, usando el helper
/// compartido (no un parche por archivo, ver `mentor_walk.dart`).
///
/// T001-T005 (1.1), T008-T010 (1.2) y T033-T042 (1.3) migraron al piloto de
/// 3 bloques (teoría escrita + ejemplo de mesa + ejercicios) y ya NO tienen
/// clase de mentor — ver `academy_1_1_pilot_test.dart` /
/// `academy_1_2_pilot_test.dart` / `academy_1_3_pilot_test.dart`. De las 25
/// teorías de N1, quedan 7 con clase de mentor (todas en 1.4).
void main() {
  AcademyProgress upTo(String target) {
    final p = AcademyProgress();
    for (final id in Curriculum.lessonOrder) {
      if (id == target) break;
      p.entry(id).completed = true;
    }
    return p;
  }

  Future<AcademyController> open(WidgetTester tester, String sublevelId) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
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

  const n1Theories = <String, List<String>>{
    '1.4': ['T043', 'T044', 'T045', 'T046', 'T047', 'T048', 'T049'],
  };

  test('las 7 teorías migradas de N1 que quedan (T001-T005, T008-T010 y '
      'T033-T042 ya no tienen mentor) siguen con clase de mentor '
      'registrada', () {
    final all = n1Theories.values.expand((l) => l).toList();
    expect(all.length, 7);
    for (final id in all) {
      expect(AcademyMentorLessons.has(id), isTrue, reason: '$id sin mentor');
    }
  });

  for (final entry in n1Theories.entries) {
    final sublevel = entry.key;
    final theories = entry.value;

    testWidgets(
        '$sublevel: sus ${theories.length} teorías se recorren por UI sin '
        'excepciones', (tester) async {
      final c = await open(tester, sublevel);

      for (final id in theories) {
        await fastForwardAndWalkMentor(tester, c, id);
        expect(tester.takeException(), isNull, reason: id);
      }

      // Terminada la última teoría del subnivel, ya no queda ninguna clase
      // de mentor activa (se pasó a ejercicios o al resultado).
      expect(c.isMentorLesson, isFalse);
    });
  }
}

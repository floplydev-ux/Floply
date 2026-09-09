import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/academy_content.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/academy_table_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';
import 'package:poker_trainer/engine/poker/card.dart';

void main() {
  final curriculum = Curriculum.standard();
  final lessonIds = curriculum.allLessons.map((l) => l.id).toSet();

  test('ningún guion de mesa (teoría o ejercicio) apunta a un lessonId '
      'inexistente', () {
    for (final id in AcademyTableScripts.lessonIds) {
      expect(lessonIds.contains(id), isTrue,
          reason: 'guion de teoría "$id" no existe en el currículo');
    }
    for (final id in AcademyExerciseScripts.lessonIds) {
      expect(lessonIds.contains(id), isTrue,
          reason: 'set de ejercicios "$id" no existe en el currículo');
    }
  });

  test('cada lesson con guion de teoría entra en la fase de teoría', () {
    for (final id in AcademyTableScripts.lessonIds) {
      final lesson = curriculum.lessonById(id)!;
      expect(lesson.kind, isNot(LessonKind.assessment), reason: id);
      final content = AcademyContent.forLesson(id)!;
      // Entra en fase teoría si tiene bloques de texto O guion de mesa.
      expect(content.hasTheory || AcademyTableScripts.has(id), isTrue,
          reason: id);
    }
  });

  test('cada paso de cada guion está bien formado', () {
    for (final entry in AcademyTableScripts.all.entries) {
      final id = entry.key;
      final script = entry.value;
      expect(script.steps, isNotEmpty, reason: id);
      expect(script.length, lessThanOrEqualTo(9), reason: '$id demasiado largo');

      for (var i = 0; i < script.steps.length; i++) {
        final step = script.steps[i];
        final where = '$id paso ${i + 1}';

        expect(step.bubble.trim(), isNotEmpty, reason: where);
        expect(step.bubble.length, lessThanOrEqualTo(180),
            reason: '$where: burbuja muy larga');

        expect(step.table.seats.length, 6, reason: where);
        expect(step.table.seats.map((s) => s.slot).toSet(), {0, 1, 2, 3, 4, 5},
            reason: where);
        expect(step.table.seats.where((s) => s.isHero).length, 1,
            reason: '$where: debe haber exactamente un héroe');
        expect(step.table.buttonSlot, inInclusiveRange(0, 5), reason: where);
        expect(step.table.board.length, lessThanOrEqualTo(5), reason: where);

        for (final a in [step.anchor, ...step.highlight]) {
          if (a.kind == TableAnchorKind.seat ||
              a.kind == TableAnchorKind.bet) {
            expect(a.slot, inInclusiveRange(0, 5), reason: '$where ancla');
          }
        }

        final allCards = <String>[];
        for (final s in step.table.seats) {
          for (final code in s.cards) {
            if (code != '?') {
              expect(() => Card.parse(code), returnsNormally,
                  reason: '$where: carta "$code"');
              allCards.add(code);
            }
          }
        }
        for (final code in step.table.board) {
          expect(() => Card.parse(code), returnsNormally,
              reason: '$where: board "$code"');
          allCards.add(code);
        }
        expect(allCards.toSet().length, allCards.length,
            reason: '$where: cartas duplicadas → $allCards');
      }
    }
  });

  test('los guiones desarrollan la mano (el bote no baja dentro del guion)',
      () {
    for (final entry in AcademyTableScripts.all.entries) {
      double pot = 0;
      for (final step in entry.value.steps) {
        expect(step.table.potBb, greaterThanOrEqualTo(pot - 0.001),
            reason: '${entry.key}: el bote bajó');
        pot = step.table.potBb;
      }
    }
  });
}

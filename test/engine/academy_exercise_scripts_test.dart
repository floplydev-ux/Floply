import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/table_exercise.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';
import 'package:poker_trainer/engine/poker/card.dart';

void main() {
  final curriculum = Curriculum.standard();

  test('todos los sets de ejercicios interactivos están bien formados', () {
    for (final entry in AcademyExerciseScripts.all.entries) {
      final id = entry.key;
      final set = entry.value;

      expect(curriculum.lessonById(id), isNotNull,
          reason: 'set "$id" no existe en el currículo');
      expect(set.exercises, isNotEmpty, reason: id);

      final available = curriculum.conceptsTaughtUpTo(id);

      for (var i = 0; i < set.exercises.length; i++) {
        final ex = set.exercises[i];
        final where = '$id ej ${i + 1}';

        // Pregunta y opciones.
        expect(ex.question.trim(), isNotEmpty, reason: where);
        expect(ex.choices.length, inInclusiveRange(2, 4), reason: where);
        expect(
          ex.choices.where((c) => c.rating == ExerciseRating.best).length,
          1,
          reason: '$where: debe haber exactamente una opción "best"',
        );
        expect(ex.bestChoiceIndex, isNonNegative, reason: where);
        for (final c in ex.choices) {
          expect(c.feedback.trim(), isNotEmpty, reason: '$where opción');
        }

        // Explicación.
        expect(ex.explanation, isNotEmpty, reason: where);
        for (final s in ex.explanation) {
          expect(s.text.trim(), isNotEmpty, reason: '$where explicación');
        }

        // Regla fundamental: si evalúa un concepto, tiene que estar
        // enseñado hasta este lesson (o ser `null` = adelanto).
        if (ex.concept != null) {
          expect(available.contains(ex.concept), isTrue,
              reason: '$where evalúa "${ex.concept}" no enseñado todavía');
        }

        // Mesa 6-max coherente + cartas parseables + sin duplicados.
        for (final snap in <TableSnapshot?>[
          ex.situation,
          ex.afterDecision,
          ...ex.explanation.map((s) => s.table),
        ]) {
          if (snap == null) continue;
          expect(snap.seats.length, 6, reason: where);
          expect(snap.seats.where((s) => s.isHero).length, 1, reason: where);
          final all = <String>[];
          for (final s in snap.seats) {
            for (final code in s.cards) {
              if (code != '?') {
                expect(() => Card.parse(code), returnsNormally,
                    reason: '$where carta "$code"');
                all.add(code);
              }
            }
          }
          for (final code in snap.board) {
            expect(() => Card.parse(code), returnsNormally,
                reason: '$where board "$code"');
            all.add(code);
          }
          expect(all.toSet().length, all.length,
              reason: '$where: cartas duplicadas en la mesa → $all');
        }

        // Anclas válidas.
        final anchors = <TableAnchor>[
          ex.questionAnchor,
          ...ex.situationHighlight,
          for (final s in ex.explanation) ...[s.anchor, ...s.highlight],
        ];
        for (final a in anchors) {
          if (a.kind == TableAnchorKind.seat ||
              a.kind == TableAnchorKind.bet) {
            expect(a.slot, inInclusiveRange(0, 5), reason: '$where ancla');
          }
        }
      }
    }
  });

  test('un ejercicio de adelanto (3-bet en 5.4) usa concept: null', () {
    final set = AcademyExerciseScripts.forLesson('5.4')!;
    final threeBet =
        set.exercises.firstWhere((e) => e.choices.any((c) => c.label == '3-BET'));
    expect(threeBet.concept, isNull);
    expect(threeBet.strategyDependent, isTrue);
  });
}

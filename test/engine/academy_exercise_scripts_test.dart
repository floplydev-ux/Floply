import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/table_exercise.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';
import 'package:poker_trainer/engine/poker/card.dart';

void main() {
  final curriculum = Curriculum.standard();

  test('los sets de ejercicios interactivos (crudos) están bien formados', () {
    // "all" (crudo, por id histórico) + los sets autorados directo por
    // subnivel nuevo (PASO 4, N5-N13) — juntos cubren todo lo que
    // AcademyExerciseScripts.forLesson puede devolver.
    final bySublevel = {
      for (final code in AcademyExerciseScripts.sublevelsWithSet)
        code: AcademyExerciseScripts.forLesson(code)!,
    };
    final entries = {
      ...AcademyExerciseScripts.all,
      ...bySublevel,
    };
    for (final entry in entries.entries) {
      final id = entry.key;
      final set = entry.value;
      expect(set.exercises, isNotEmpty, reason: id);

      for (var i = 0; i < set.exercises.length; i++) {
        final ex = set.exercises[i];
        final where = '$id ej ${i + 1}';

        expect(ex.question.trim(), isNotEmpty, reason: where);
        expect(ex.choices.length, inInclusiveRange(2, 4), reason: where);
        expect(
          ex.choices.where((c) => c.rating == ExerciseRating.best).length,
          1,
          reason: '$where: exactamente una opción "best"',
        );
        expect(ex.bestChoiceIndex, isNonNegative, reason: where);
        for (final c in ex.choices) {
          expect(c.feedback.trim(), isNotEmpty, reason: '$where opción');
        }

        expect(ex.explanation, isNotEmpty, reason: where);
        for (final s in ex.explanation) {
          expect(s.text.trim(), isNotEmpty, reason: '$where explicación');
        }

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
              reason: '$where: cartas duplicadas → $all');
        }

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

  test('regla fundamental: cada subnivel con set interactivo solo evalúa '
      'conceptos ya introducidos hasta ahí', () {
    for (final code in AcademyExerciseScripts.sublevelsWithSet) {
      expect(curriculum.lessonById(code), isNotNull, reason: code);
      final available = curriculum.conceptsTaughtUpTo(code);
      final set = AcademyExerciseScripts.forLesson(code)!;
      for (final ex in set.exercises) {
        if (ex.concept != null) {
          expect(available.contains(ex.concept), isTrue,
              reason: '$code evalúa "${ex.concept}" no enseñado todavía');
        }
      }
    }
  });

  test('el ejercicio de adelanto (3-bet) usa concept: null y '
      'strategyDependent', () {
    // El set 5.4 histórico (posición / open-fold / 3-bet) quedó re-anclado a
    // N7.2 «3-bet: valor y farol».
    final set = AcademyExerciseScripts.forLesson('7.2')!;
    expect(set.exercises.length, 3);
    final threeBet = set.exercises
        .firstWhere((e) => e.choices.any((c) => c.label == '3-BET'));
    expect(threeBet.concept, isNull);
    expect(threeBet.strategyDependent, isTrue);
  });

  test(
      'checkpoint 4.6 tiene ejercicios reales (antes de la auditoría de '
      'motores, no tenía ninguno y el checkpoint auto-aprobaba con 1.0 '
      'sin que el alumno respondiera nada)', () {
    expect(AcademyExerciseScripts.has('4.6'), isTrue);
    final set = AcademyExerciseScripts.forLesson('4.6')!;
    expect(set.exercises, isNotEmpty);
    // Cubre lo que pide el objetivo del subnivel: al menos una mano
    // ganadora de cada categoría grande (no solo comparaciones triviales).
    final winningCats =
        set.exercises.map((e) => e.choices.first.label).join(' ');
    expect(winningCats, contains('escalera'));
    expect(winningCats, contains('color'));
    expect(winningCats, contains('full house'));
  });
}

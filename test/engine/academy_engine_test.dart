import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_engine.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/evaluation/user_answer.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';

void main() {
  PokerTrainerEngine makeEngine() => PokerTrainerEngine(seed: 7);

  // Resuelve todos los ejercicios de un lesson eligiendo la mejor opción,
  // devuelve el promedio de decisión (0..1).
  LessonRunResult runLessonPerfect(
    PokerTrainerEngine engine,
    String lessonId,
    dynamic knowledge,
  ) {
    final content = engine.academy.contentFor(lessonId)!;
    var sum = 0.0;
    var correct = 0;
    var total = 0;
    if (content.practice != null) {
      final spec = content.practice!;
      for (var i = 0; i < spec.exerciseCount; i++) {
        final ex = engine.nextExercise(knowledge,
            concept: spec.targetConcept, difficulty: spec.difficulty);
        final best = ex.strategy.primary;
        final opt = ex.options.firstWhere(
          (o) =>
              (o.action != null && o.action!.matches(best.action)) ||
              (ex.correctValue != null && o.value == ex.correctValue),
          orElse: () => ex.options.first,
        );
        final res = engine.submit(
          ex,
          UserAnswer(exerciseId: ex.id, selectedOptionId: opt.id),
          knowledge,
        );
        sum += res.decisionScore;
        if (res.decisionScore >= 0.6) correct++;
        total++;
      }
    } else {
      for (final check in content.checks) {
        if (check.concept != null) {
          knowledge.recordAttempt(check.concept!, decisionCorrect: true);
        }
        sum += 1;
        correct++;
        total++;
      }
    }
    return LessonRunResult(
      score: total == 0 ? 1 : sum / total,
      total: total,
      correct: correct,
    );
  }

  test('usuario nuevo: solo el primer lesson está disponible', () {
    final engine = makeEngine();
    final progress = AcademyProgress();

    expect(engine.academy.stateOf('1.1', progress), LessonState.available);
    expect(engine.academy.stateOf('1.2', progress), LessonState.locked);
    expect(engine.academy.stateOf('2.1', progress), LessonState.locked);
    expect(engine.academy.currentLessonId(progress), '1.1');

    final overview = engine.academy.overview(progress);
    expect(overview.first.state, LevelState.available);
    expect(overview[1].state, LevelState.locked);
  });

  test('usuario nuevo real no tiene ningún concepto enseñado', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    expect(k.taughtConcepts, isEmpty);
  });

  test('completar un lesson desbloquea el siguiente', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    engine.academy.openLesson('1.1', k, progress);
    final run = runLessonPerfect(engine, '1.1', k);
    final outcome = engine.academy.submitLesson('1.1', run, k, progress);

    expect(outcome.completed, isTrue);
    expect(outcome.unlockedNext, isTrue);
    expect(engine.academy.stateOf('1.1', progress), LessonState.completed);
    expect(engine.academy.stateOf('1.2', progress), LessonState.available);
  });

  test('la progresión depende del resultado: evaluación desaprobada no '
      'desbloquea', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    // Llegar hasta la evaluación 1.5.
    for (final id in ['1.1', '1.2', '1.3', '1.4']) {
      engine.academy.openLesson(id, k, progress);
      engine.academy
          .submitLesson(id, runLessonPerfect(engine, id, k), k, progress);
    }
    engine.academy.openLesson('1.5', k, progress);

    // Falla la evaluación (30%).
    final fail = engine.academy.submitLesson(
      '1.5',
      const LessonRunResult(score: 0.3, total: 5, correct: 1),
      k,
      progress,
    );
    expect(fail.passed, isFalse);
    expect(fail.completed, isFalse);
    expect(engine.academy.stateOf('1.5', progress), LessonState.available);
    expect(engine.academy.stateOf('2.1', progress), LessonState.locked);

    // Reintenta y aprueba (80%).
    final pass = engine.academy.submitLesson(
      '1.5',
      const LessonRunResult(score: 0.8, total: 5, correct: 4),
      k,
      progress,
    );
    expect(pass.passed, isTrue);
    expect(pass.completed, isTrue);
    expect(engine.academy.stateOf('2.1', progress), LessonState.available);
  });

  test('evaluación desaprobada ofrece recuperación de conceptos concretos',
      () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    // Recorrer hasta la evaluación del Nivel 4 (rangos), con ejercicios
    // reales del motor en el medio.
    for (final id in Curriculum.lessonOrder) {
      engine.academy.openLesson(id, k, progress);
      if (id == '4.5') break;
      engine.academy
          .submitLesson(id, runLessonPerfect(engine, id, k), k, progress);
    }

    // Falla la evaluación 4.5 marcando conceptos débiles explícitos.
    final outcome = engine.academy.submitLesson(
      '4.5',
      const LessonRunResult(
        score: 0.2,
        total: 6,
        correct: 1,
        weakConceptIds: ['opening_range'],
      ),
      k,
      progress,
    );
    expect(outcome.passed, isFalse);
    expect(outcome.completed, isFalse);
    expect(outcome.weakConceptIds, contains('opening_range'));
    expect(engine.academy.stateOf('5.1', progress), LessonState.locked);
  });

  test('la regla fundamental se respeta en TODO el currículo: ningún '
      'ejercicio evalúa un concepto no enseñado todavía', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    for (final lessonId in Curriculum.lessonOrder) {
      engine.academy.openLesson(lessonId, k, progress);
      final available = engine.academy.conceptsAvailableAt(lessonId);
      final taught = k.taughtConcepts;

      // Lo que la teoría hizo disponible coincide con lo enseñado.
      expect(taught, equals(available),
          reason: 'desync en $lessonId');

      final content = engine.academy.contentFor(lessonId)!;
      if (content.practice != null) {
        final spec = content.practice!;
        for (var i = 0; i < spec.exerciseCount + 2; i++) {
          final ex = engine.nextExercise(k,
              concept: spec.targetConcept, difficulty: spec.difficulty);
          for (final c in ex.evaluatedConcepts) {
            expect(available.contains(c), isTrue,
                reason: '$lessonId evaluó "$c" no enseñado');
          }
          for (final c in ex.reasoningConcepts) {
            expect(taught.contains(c), isTrue);
          }
        }
      }
      for (final check in content.checks) {
        if (check.concept != null) {
          expect(available.contains(check.concept), isTrue,
              reason: '$lessonId chequea "${check.concept}" no enseñado');
        }
      }

      final run = lessonId.endsWith('.5')
          ? const LessonRunResult(score: 1, total: 4, correct: 4)
          : runLessonPerfect(engine, lessonId, k);
      engine.academy.submitLesson(lessonId, run, k, progress);
    }

    // Al terminar, ningún concepto avanzado quedó enseñado.
    expect(k.isTaught('three_bet'), isFalse);
    expect(k.isTaught('pot_odds'), isFalse);
    expect(k.isTaught('gto'), isFalse);
  });

  test('se puede completar la Academia entera con buen desempeño', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    for (final lessonId in Curriculum.lessonOrder) {
      expect(engine.academy.stateOf(lessonId, progress),
          LessonState.available,
          reason: '$lessonId debería estar disponible al llegar');
      engine.academy.openLesson(lessonId, k, progress);
      final run = runLessonPerfect(engine, lessonId, k);
      final outcome =
          engine.academy.submitLesson(lessonId, run, k, progress);
      expect(outcome.completed, isTrue, reason: 'no completó $lessonId');
    }

    expect(progress.completedCount, Curriculum.lessonOrder.length);
    expect(engine.academy.currentLessonId(progress), isNull);
    expect(engine.academy.overview(progress).every(
        (l) => l.state == LevelState.completed), isTrue);
  });
}

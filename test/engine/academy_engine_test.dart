import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_engine.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/evaluation/user_answer.dart';
import 'package:poker_trainer/engine/pedagogy/academy_content.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';

void main() {
  PokerTrainerEngine makeEngine() => PokerTrainerEngine(seed: 7);

  final order = Curriculum.lessonOrder;

  /// Códigos de subnivel del Nivel [n], en orden.
  List<String> level(int n) =>
      Curriculum.standard().levels[n - 1].lessons.map((l) => l.id).toList();

  /// Resuelve los ejercicios de un subnivel eligiendo la mejor opción y
  /// devuelve el promedio de decisión (0..1). Los subniveles todavía sin
  /// contenido (PASO 4) devuelven 1.
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

  test('usuario nuevo: solo el primer subnivel está disponible', () {
    final engine = makeEngine();
    final progress = AcademyProgress();

    expect(engine.academy.stateOf(order[0], progress), LessonState.available);
    expect(engine.academy.stateOf(order[1], progress), LessonState.locked);
    expect(engine.academy.currentLessonId(progress), order[0]);

    final overview = engine.academy.overview(progress);
    expect(overview.length, 13);
    expect(overview.first.state, LevelState.available);
    expect(overview[1].state, LevelState.locked);
  });

  test('usuario nuevo real no tiene ningún concepto enseñado', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    expect(k.taughtConcepts, isEmpty);
  });

  test('completar un subnivel desbloquea el siguiente', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    engine.academy.openLesson(order[0], k, progress);
    final run = runLessonPerfect(engine, order[0], k);
    final outcome = engine.academy.submitLesson(order[0], run, k, progress);

    expect(outcome.completed, isTrue);
    expect(outcome.unlockedNext, isTrue);
    expect(engine.academy.stateOf(order[0], progress), LessonState.completed);
    expect(engine.academy.stateOf(order[1], progress), LessonState.available);
  });

  test('el checkpoint de un nivel (último subnivel) gatea el nivel siguiente',
      () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    final n1 = level(1);
    final checkpoint = n1.last; // subnivel-evaluación del Nivel 1
    final firstOfN2 = level(2).first;

    // Completar el Nivel 1 hasta el checkpoint.
    for (final id in n1.sublist(0, n1.length - 1)) {
      engine.academy.openLesson(id, k, progress);
      engine.academy
          .submitLesson(id, runLessonPerfect(engine, id, k), k, progress);
    }
    engine.academy.openLesson(checkpoint, k, progress);

    // Falla el checkpoint (30%).
    final fail = engine.academy.submitLesson(
      checkpoint,
      const LessonRunResult(score: 0.3, total: 5, correct: 1),
      k,
      progress,
    );
    expect(fail.passed, isFalse);
    expect(fail.completed, isFalse);
    expect(engine.academy.stateOf(checkpoint, progress), LessonState.available);
    expect(engine.academy.stateOf(firstOfN2, progress), LessonState.locked);

    // Reintenta y aprueba (80%).
    final pass = engine.academy.submitLesson(
      checkpoint,
      const LessonRunResult(score: 0.8, total: 5, correct: 4),
      k,
      progress,
    );
    expect(pass.passed, isTrue);
    expect(pass.completed, isTrue);
    expect(engine.academy.stateOf(firstOfN2, progress), LessonState.available);
  });

  test('checkpoint desaprobado ofrece recuperación de conceptos concretos', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    // Recorrer hasta el checkpoint del Nivel 5 (rangos y apertura).
    final n5 = level(5);
    final checkpoint = n5.last;
    for (final id in order) {
      engine.academy.openLesson(id, k, progress);
      if (id == checkpoint) break;
      engine.academy
          .submitLesson(id, runLessonPerfect(engine, id, k), k, progress);
    }

    final outcome = engine.academy.submitLesson(
      checkpoint,
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
    expect(engine.academy.stateOf(level(6).first, progress),
        LessonState.locked);
  });

  test('la regla fundamental se respeta en TODO el currículo: ningún '
      'ejercicio evalúa un concepto no enseñado todavía', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    for (final lessonId in order) {
      engine.academy.openLesson(lessonId, k, progress);
      final available = engine.academy.conceptsAvailableAt(lessonId);

      // Lo enseñado coincide con lo que el currículo hizo disponible.
      expect(k.taughtConcepts, equals(available),
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
        }
      }
      for (final check in content.checks) {
        if (check.concept != null) {
          expect(available.contains(check.concept), isTrue,
              reason: '$lessonId chequea "${check.concept}" no enseñado');
        }
      }

      engine.academy.submitLesson(
          lessonId, runLessonPerfect(engine, lessonId, k), k, progress);
    }
  });

  test('los conceptos avanzados no se enseñan antes de su nivel', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    // Recorrer hasta el final del Nivel 5 (apertura preflop).
    for (final id in order) {
      engine.academy.openLesson(id, k, progress);
      if (id == level(6).first) break;
      engine.academy
          .submitLesson(id, runLessonPerfect(engine, id, k), k, progress);
    }
    // Todavía no se enseñaron: matemática (N6), 3-bet (N7), GTO (N11).
    expect(k.isTaught('pot_odds'), isFalse);
    expect(k.isTaught('three_bet'), isFalse);
    expect(k.isTaught('gto'), isFalse);
    // Pero sí lo de posición y apertura.
    expect(k.isTaught('position_advantage'), isTrue);
    expect(k.isTaught('open_raise'), isTrue);
  });

  test('se puede completar la Academia entera con buen desempeño', () {
    final engine = makeEngine();
    final k = engine.newAcademyUser();
    final progress = AcademyProgress();

    for (final lessonId in order) {
      expect(engine.academy.stateOf(lessonId, progress), LessonState.available,
          reason: '$lessonId debería estar disponible al llegar');
      engine.academy.openLesson(lessonId, k, progress);
      final run = runLessonPerfect(engine, lessonId, k);
      final outcome =
          engine.academy.submitLesson(lessonId, run, k, progress);
      expect(outcome.completed, isTrue, reason: 'no completó $lessonId');
    }

    expect(progress.completedCount, order.length);
    expect(engine.academy.currentLessonId(progress), isNull);
    expect(engine.academy.overview(progress).every(
        (l) => l.state == LevelState.completed), isTrue);
  });

  test('AcademyContent expone el contenido crudo histórico para el resolver',
      () {
    // El material de las 25 lecciones no se pierde.
    expect(AcademyContent.legacyOf('4.3'), isNotNull); // teoría en texto
    expect(AcademyContent.legacyOf('1.1')?.theory, isNotEmpty);
  });
}

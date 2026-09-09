import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';

void main() {
  AcademyController make(AcademyStore store) => AcademyController(
        engine: PokerTrainerEngine(seed: 3),
        store: store,
      );

  /// Índice de la opción "correcta" de un ítem (motor, check o interactivo).
  int bestChoice(AcademyItem item) {
    if (item.isInteractive) return item.interactive!.bestChoiceIndex;
    if (item.isEngine) {
      final ex = item.exercise!;
      final best = ex.strategy.primary;
      final i = ex.options.indexWhere(
        (o) =>
            (o.action != null && o.action!.matches(best.action)) ||
            (ex.correctValue != null && o.value == ex.correctValue),
      );
      return i < 0 ? 0 : i;
    }
    return item.check!.correctIndex;
  }

  /// Resuelve el ítem actual (cualquier modalidad) eligiendo [choice].
  void answer(AcademyController c, int choice) {
    final item = c.currentItem!;
    if (item.isInteractive) {
      c.answerInteractive(choice);
      c.advanceInteractive();
    } else {
      c.toggleOption(choice);
      c.confirm();
    }
  }

  /// Abre un lesson y lo resuelve entero eligiendo siempre bien.
  Future<void> completeLesson(AcademyController c, String lessonId) async {
    c.openLesson(lessonId);
    while (c.phase == AcademyPhase.theory) {
      c.isInteractiveTheory ? c.nextTableStep() : c.startExercises();
    }
    while (c.phase == AcademyPhase.exercise ||
        c.phase == AcademyPhase.feedback) {
      if (c.phase == AcademyPhase.exercise) {
        answer(c, bestChoice(c.currentItem!));
      } else {
        c.nextItem();
      }
    }
    expect(c.phase, AcademyPhase.result);
  }

  test('usuario nuevo: arranca en el mapa con 1.1 disponible', () async {
    final c = make(InMemoryAcademyStore());
    await c.load();
    expect(c.loading, isFalse);
    expect(c.phase, AcademyPhase.map);
    expect(c.currentLessonId, '1.1');
    expect(c.academy.stateOf('1.2', c.progress), LessonState.locked);
  });

  test('teoría → ejercicios → resultado → siguiente lesson desbloqueado',
      () async {
    final c = make(InMemoryAcademyStore());
    await c.load();

    c.openLesson('1.1');
    expect(c.phase, AcademyPhase.theory);
    expect(c.isInteractiveTheory, isTrue);

    // Recorrer la teoría interactiva sobre la mesa.
    while (c.phase == AcademyPhase.theory) {
      c.nextTableStep();
    }
    expect(c.phase, AcademyPhase.exercise);

    // Resolver el ejercicio interactivo.
    while (c.phase == AcademyPhase.exercise) {
      answer(c, bestChoice(c.currentItem!));
    }

    expect(c.phase, AcademyPhase.result);
    expect(c.lastOutcome!.completed, isTrue);

    c.exitLesson();
    expect(c.academy.stateOf('1.2', c.progress), LessonState.available);
  });

  test('un lesson sin migrar sigue consumiendo ejercicios del motor', () async {
    final c = make(InMemoryAcademyStore());
    await c.load();

    // 3.2 todavía no está migrado a la mesa interactiva.
    for (final id in [
      '1.1', '1.2', '1.3', '1.4', '1.5', //
      '2.1', '2.2', '2.3', '2.4', '2.5', //
      '3.1'
    ]) {
      await completeLesson(c, id);
      c.exitLesson();
    }

    c.openLesson('3.2');
    while (c.phase == AcademyPhase.theory) {
      c.isInteractiveTheory ? c.nextTableStep() : c.startExercises();
    }
    expect(c.currentItem, isNotNull);
    expect(c.currentItem!.isEngine, isTrue);

    await completeLesson(c, '3.2');
    c.exitLesson();
    expect(c.academy.stateOf('3.3', c.progress), LessonState.available);
  });

  test('evaluación desaprobada: no completa y ofrece recuperación', () async {
    final c = make(InMemoryAcademyStore());
    await c.load();

    for (final id in ['1.1', '1.2', '1.3', '1.4']) {
      await completeLesson(c, id);
      c.exitLesson();
    }

    // Hacer la evaluación 1.5 respondiendo SIEMPRE mal.
    c.openLesson('1.5');
    while (c.phase == AcademyPhase.theory) {
      c.isInteractiveTheory ? c.nextTableStep() : c.startExercises();
    }
    while (c.phase == AcademyPhase.exercise ||
        c.phase == AcademyPhase.feedback) {
      if (c.phase == AcademyPhase.exercise) {
        final wrong =
            (bestChoice(c.currentItem!) + 1) % c.currentItem!.options.length;
        answer(c, wrong);
      } else {
        c.nextItem();
      }
    }
    expect(c.phase, AcademyPhase.result);
    expect(c.lastOutcome!.passed, isFalse);
    expect(c.lastOutcome!.completed, isFalse);
    expect(c.academy.stateOf('1.5', c.progress), LessonState.available);

    // Reintentar y aprobar.
    await completeLesson(c, '1.5');
    expect(c.lastOutcome!.passed, isTrue);
    c.exitLesson();
    expect(c.academy.stateOf('2.1', c.progress), LessonState.available);
  });

  test('el progreso sobrevive al reinicio de la app', () async {
    final store = InMemoryAcademyStore();

    final first = make(store);
    await first.load();
    await completeLesson(first, '1.1');
    first.exitLesson();
    // dar tiempo a que _persist() (async) termine
    await Future<void>.delayed(Duration.zero);

    final second = make(store);
    await second.load();
    expect(second.academy.stateOf('1.1', second.progress),
        LessonState.completed);
    expect(second.academy.stateOf('1.2', second.progress),
        LessonState.available);
    expect(second.currentLessonId, '1.2');
  });

  test('resetProgress vuelve a foja cero', () async {
    final store = InMemoryAcademyStore();
    final c = make(store);
    await c.load();
    await completeLesson(c, '1.1');
    c.exitLesson();

    await c.resetProgress();
    expect(c.progress.completedCount, 0);
    expect(c.knowledge.taughtConcepts, isEmpty);
    expect(c.currentLessonId, '1.1');
  });
}

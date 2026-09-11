import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
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
      c.advanceTheory();
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

  test('teoría → ejercicios → resultado → siguiente subnivel desbloqueado',
      () async {
    final c = make(InMemoryAcademyStore());
    await c.load();

    // N1.1 es teoría-solo; N1.2 tiene teoría interactiva + un ejercicio.
    await completeLesson(c, '1.1');
    c.exitLesson();

    c.openLesson('1.2');
    expect(c.phase, AcademyPhase.theory);
    expect(c.isInteractiveTheory, isTrue);
    // N1.2: guion de mesa → fichas de teoría redactada → ejercicios.
    while (c.isInteractiveTheory) {
      c.nextTableStep();
    }
    expect(c.isWrittenTheory, isTrue);
    while (c.phase == AcademyPhase.theory) {
      c.advanceTheory();
    }
    expect(c.phase, AcademyPhase.exercise);

    while (c.phase == AcademyPhase.exercise) {
      answer(c, bestChoice(c.currentItem!));
    }

    expect(c.phase, AcademyPhase.result);
    expect(c.lastOutcome!.completed, isTrue);

    c.exitLesson();
    expect(c.academy.stateOf('1.3', c.progress), LessonState.available);
  });

  test(
      'un subnivel con guion interactivo autorado (PASO 4) lo usa por '
      'encima de la PracticeSpec heredada del motor', () async {
    final c = make(InMemoryAcademyStore());
    await c.load();

    // N5.3 (decisión de abrir / RFI) hereda una PracticeSpec del motor
    // (legacy), pero PASO 4 le agregó un ejercicio interactivo propio
    // sobre la mesa — ese es el que debe usarse: más rico que una
    // pregunta genérica del motor, para la misma decisión (RFI).
    for (final id in Curriculum.lessonOrder) {
      if (id == '5.3') break;
      await completeLesson(c, id);
      c.exitLesson();
    }

    c.openLesson('5.3');
    while (c.phase == AcademyPhase.theory) {
      c.advanceTheory();
    }
    expect(c.currentItem, isNotNull);
    expect(c.currentItem!.isInteractive, isTrue);

    await completeLesson(c, '5.3');
    c.exitLesson();
    expect(c.academy.stateOf('5.4', c.progress), LessonState.available);
  });

  test('checkpoint desaprobado: no completa y ofrece recuperación', () async {
    final c = make(InMemoryAcademyStore());
    await c.load();

    for (final id in ['1.1', '1.2', '1.3']) {
      await completeLesson(c, id);
      c.exitLesson();
    }

    // Hacer el checkpoint del Nivel 1 (1.4) respondiendo SIEMPRE mal.
    c.openLesson('1.4');
    while (c.phase == AcademyPhase.theory) {
      c.advanceTheory();
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
    expect(c.academy.stateOf('1.4', c.progress), LessonState.available);
    expect(c.academy.stateOf('2.1', c.progress), LessonState.locked);

    // Reintentar y aprobar.
    await completeLesson(c, '1.4');
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

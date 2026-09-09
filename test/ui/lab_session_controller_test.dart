import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';

void main() {
  LabSessionController make() => LabSessionController(
        engine: PokerTrainerEngine(seed: 1),
        sessionLength: 5,
      );

  test('el flujo idle -> question -> feedback -> summary funciona', () {
    final c = make();
    expect(c.phase, LabPhase.idle);

    c.start();
    expect(c.phase, LabPhase.question);
    expect(c.current, isNotNull);

    for (var i = 0; i < 5; i++) {
      expect(c.phase, LabPhase.question);
      final exercise = c.current!;
      final best = exercise.strategy.primary;
      final option = exercise.options.firstWhere(
        (o) =>
            (o.action != null && o.action!.matches(best.action)) ||
            (exercise.correctValue != null &&
                o.value == exercise.correctValue),
        orElse: () => exercise.options.first,
      );
      c.toggleOption(option.id, single: true);
      expect(c.canConfirm, isTrue);
      c.confirm();
      expect(c.phase, LabPhase.feedback);
      expect(c.lastResult!.feedback, isNotEmpty);
      c.next();
    }

    expect(c.phase, LabPhase.summary);
    expect(c.results.length, 5);
    expect(c.sessionDecisionScore, greaterThan(0));
  });

  test('no se puede confirmar sin elegir una opción', () {
    final c = make();
    c.start();
    expect(c.canConfirm, isFalse);
    c.confirm();
    expect(c.phase, LabPhase.question);
  });

  test('elegir mal repetidamente deja constancia de conceptos débiles', () {
    final c = make();
    c.start();
    for (var i = 0; i < 5; i++) {
      final exercise = c.current!;
      final best = exercise.strategy.primary;
      final bad = exercise.options.firstWhere(
        (o) =>
            (o.action != null && !o.action!.matches(best.action)) ||
            (exercise.correctValue != null &&
                o.value != null &&
                o.value != exercise.correctValue),
        orElse: () => exercise.options.last,
      );
      c.toggleOption(bad.id, single: true);
      c.confirm();
      c.next();
    }
    expect(c.phase, LabPhase.summary);
    // Con 5 fallos, el promedio de decisión debería ser bajo.
    expect(c.sessionDecisionScore, lessThan(0.7));
  });
}

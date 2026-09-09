import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/evaluation/user_answer.dart';
import 'package:poker_trainer/engine/exercises/exercise_history.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';

void main() {
  test('flujo completo: pedir -> responder bien -> progreso sube', () {
    final engine = PokerTrainerEngine(seed: 1);
    final user = engine.newUser();

    expect(user.isTaught(ConceptIds.openingRange), isTrue);
    expect(user.isTaught(ConceptIds.threeBet), isFalse);

    for (var i = 0; i < 20; i++) {
      final ex = engine.nextExercise(user);
      final best = ex.strategy.primary;
      // Responder siempre con la línea preferida.
      final option = ex.options.firstWhere(
        (o) =>
            (o.action != null && o.action!.matches(best.action)) ||
            (ex.correctValue != null && o.value == ex.correctValue),
        orElse: () => ex.options.first,
      );
      final result = engine.submit(
        ex,
        UserAnswer(
          exerciseId: ex.id,
          selectedOptionId: option.id,
          reasoningConceptIds: ex.reasoningConcepts,
        ),
        user,
      );
      expect(result.feedback, isNotEmpty);
      expect(result.evaluatedConcepts, isNotEmpty);
    }

    // Tras responder bien repetidamente, algo debería estar dominado o
    // al menos en práctica con buena precisión.
    final openingRange = user.masteryOf(ConceptIds.openingRange);
    expect(openingRange.attempts, greaterThan(0));
    expect(openingRange.decisionAccuracy, greaterThan(0.7));
  });

  test('anti-memorización: 15 ejercicios seguidos no son idénticos', () {
    final engine = PokerTrainerEngine(seed: 2);
    final user = engine.newUser();
    final signatures = <String>[];
    for (var i = 0; i < 15; i++) {
      final ex = engine.nextExercise(user);
      final sig =
          '${ex.templateId}|${ex.prompt}';
      // Nunca exactamente igual al anterior.
      if (signatures.isNotEmpty) {
        expect(sig == signatures.last, isFalse);
      }
      signatures.add(sig);
    }
    // Buena diversidad global.
    expect(signatures.toSet().length, greaterThan(10));
  });

  test('responder mal genera una sesión de recuperación', () {
    final engine = PokerTrainerEngine(seed: 3);
    final user = engine.newUser();

    for (var i = 0; i < 12; i++) {
      final ex = engine.nextExercise(user);
      // Elegir siempre una opción incorrecta si existe.
      final best = ex.strategy.primary;
      final bad = ex.options.firstWhere(
        (o) =>
            (o.action != null && !o.action!.matches(best.action)) ||
            (ex.correctValue != null &&
                o.value != null &&
                o.value != ex.correctValue),
        orElse: () => ex.options.last,
      );
      engine.submit(
        ex,
        UserAnswer(exerciseId: ex.id, selectedOptionId: bad.id),
        user,
      );
    }

    final recovery = engine.suggestedRecovery(user);
    expect(recovery, isNotNull);
    expect(recovery!.title, contains('recuperación'));
    expect(recovery.exerciseCount, greaterThan(0));
  });

  test('ExerciseHistory calcula similitud y detecta repetición', () {
    final engine = PokerTrainerEngine(seed: 5);
    final user = engine.newUser();
    final history = ExerciseHistory();

    final first = engine.generator.next(user, history: history).exercise;
    final sig = ExerciseSignature.of(first);
    // Su propia huella es idéntica a sí misma...
    expect(sig.similarityTo(sig), 1.0);
    // ...y como ya quedó registrada, se detecta como demasiado similar.
    expect(history.isTooSimilar(sig), isTrue);

    // Una huella de otro template no colisiona.
    final other = ExerciseSignature(
      templateId: 'otro_template',
      type: sig.type,
      targetConcept: sig.targetConcept,
      difficulty: sig.difficulty,
      position: null,
      handClass: null,
      handNotation: null,
      stackBucket: null,
      correctActionLabel: null,
      variantKey: 'otro_template|x',
    );
    expect(history.isTooSimilar(other), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/engine/exercises/exercise_generator.dart';
import 'package:poker_trainer/engine/exercises/exercise_history.dart';
import 'package:poker_trainer/engine/exercises/exercise_validator.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/pedagogical_engine.dart';

void main() {
  final registry = ConceptRegistry.standard();
  final curriculum = Curriculum.standard();

  UserKnowledge sliceUser() {
    final k = UserKnowledge(registry);
    final pedagogy = PedagogicalEngine(registry, curriculum);
    // Un usuario que completó los 5 niveles de la Academia: tiene todos
    // los conceptos de apertura preflop enseñados.
    for (final lesson in curriculum.allLessons) {
      pedagogy.applyLesson(lesson.id, k);
    }
    return k;
  }

  ExerciseGenerator makeGenerator({int seed = 1}) => ExerciseGenerator(
        pedagogy: PedagogicalEngine(registry, curriculum),
        concepts: registry,
        seed: seed,
      );

  test('genera un ejercicio válido para el slice inicial', () {
    final gen = makeGenerator();
    final outcome = gen.next(sliceUser());
    final validator =
        ExerciseValidator(taughtConcepts: sliceUser().taughtConcepts);
    expect(validator.validate(outcome.exercise).isValid, isTrue);
  });

  test('nunca evalúa un concepto no enseñado', () {
    final gen = makeGenerator(seed: 99);
    final user = sliceUser();
    final taught = user.taughtConcepts;
    for (var i = 0; i < 60; i++) {
      final ex = gen.next(user, history: null).exercise;
      for (final c in ex.evaluatedConcepts) {
        expect(taught.contains(c), isTrue,
            reason: 'Ejercicio ${ex.templateId} evaluó "$c" no enseñado');
      }
      for (final c in ex.reasoningConcepts) {
        expect(taught.contains(c), isTrue);
      }
    }
  });

  test('nunca genera cartas duplicadas en la situación', () {
    final gen = makeGenerator(seed: 7);
    final user = sliceUser();
    for (var i = 0; i < 80; i++) {
      final ex = gen.next(user).exercise;
      final s = ex.situation;
      if (s != null) {
        final cards = s.knownCards;
        expect(cards.toSet().length, cards.length);
      }
    }
  });

  test('produce variedad: muchos ejercicios distintos', () {
    final gen = makeGenerator(seed: 3);
    final user = sliceUser();
    final prompts = <String>{};
    final hands = <String>{};
    for (var i = 0; i < 40; i++) {
      final ex = gen.next(user).exercise;
      prompts.add(ex.prompt);
      final h = ex.situation?.heroCards.notation;
      if (h != null) hands.add(h);
    }
    expect(prompts.length, greaterThan(18));
    expect(hands.length, greaterThan(8));
  });

  test('anti-repetición: no repite la misma mano+template consecutivamente',
      () {
    final gen = makeGenerator(seed: 5);
    final user = sliceUser();
    final history = ExerciseHistory();
    final seen = <String>[];
    for (var i = 0; i < 30; i++) {
      final ex = gen.next(user, history: history).exercise;
      final key = '${ex.templateId}|${ex.situation?.heroCards.notation}';
      // No debería aparecer idéntico al inmediatamente anterior.
      if (seen.isNotEmpty && ex.situation?.heroCards.notation != null) {
        expect(key == seen.last, isFalse,
            reason: 'Repitió $key');
      }
      seen.add(key);
    }
  });

  test('respeta el concepto preferido cuando es evaluable', () {
    final gen = makeGenerator(seed: 11);
    final user = sliceUser();
    for (var i = 0; i < 15; i++) {
      final ex =
          gen.next(user, preferredConcept: ConceptIds.openSizing).exercise;
      expect(ex.evaluatedConcepts, contains(ConceptIds.openSizing));
    }
  });

  test('la dificultad pedida se refleja en el ejercicio', () {
    final gen = makeGenerator(seed: 13);
    final user = sliceUser();
    final ex = gen.next(user, difficulty: 1).exercise;
    expect(ex.difficulty, 1);
  });

  test('un usuario sin conceptos enseñados no puede pedir ejercicios', () {
    final gen = makeGenerator();
    expect(() => gen.next(UserKnowledge(registry)), throwsStateError);
  });

  test(
      'determinismo end-to-end: la misma semilla da exactamente la misma '
      'secuencia de ejercicios (no solo a nivel Deck)', () {
    String fingerprint(dynamic exercise) {
      final s = exercise.situation;
      final situationPart = s == null
          ? 'no-situation'
          : '${s.heroPosition}|${s.heroCards.notation}|${s.board.join(",")}|'
              '${s.potBb}|${s.effectiveStackBb}';
      final optionsPart = exercise.options
          .map((o) => '${o.id}:${o.label}:${o.action}:${o.sizingBb}')
          .join(';');
      return '${exercise.templateId}#${exercise.difficulty}#'
          '${exercise.prompt}#$situationPart#$optionsPart';
    }

    final user = sliceUser();
    final genA = makeGenerator(seed: 42);
    final genB = makeGenerator(seed: 42);
    final historyA = ExerciseHistory();
    final historyB = ExerciseHistory();

    final fingerprintsA = [
      for (var i = 0; i < 20; i++)
        fingerprint(genA.next(user, history: historyA).exercise),
    ];
    final fingerprintsB = [
      for (var i = 0; i < 20; i++)
        fingerprint(genB.next(user, history: historyB).exercise),
    ];

    expect(fingerprintsA, fingerprintsB);
  });

  test('semillas distintas producen secuencias distintas', () {
    final user = sliceUser();
    final genA = makeGenerator(seed: 42);
    final genB = makeGenerator(seed: 43);

    final promptsA = [for (var i = 0; i < 20; i++) genA.next(user).exercise.prompt];
    final promptsB = [for (var i = 0; i < 20; i++) genB.next(user).exercise.prompt];

    expect(promptsA, isNot(equals(promptsB)));
  });
}

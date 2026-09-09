import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_concept_mastery.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';

void main() {
  final registry = ConceptRegistry.standard();

  group('ConceptRegistry', () {
    test('el grafo es válido (sin ciclos ni referencias colgantes)', () {
      // Si el constructor no lanzó, el grafo es sano.
      expect(registry.all, isNotEmpty);
    });

    test('prerrequisitos transitivos de 3-bet bluff incluyen los básicos', () {
      final pres = registry.allPrerequisites(ConceptIds.threeBetBluff);
      expect(pres, contains(ConceptIds.threeBet));
      expect(pres, contains(ConceptIds.blockers));
      expect(pres, contains(ConceptIds.openRaise));
    });

    test('orden topológico respeta prerrequisitos', () {
      final order = registry.topologicalOrder().map((c) => c.id).toList();
      for (final concept in registry.all) {
        for (final pre in concept.prerequisites) {
          expect(order.indexOf(pre), lessThan(order.indexOf(concept.id)),
              reason: '$pre debe venir antes que ${concept.id}');
        }
      }
    });

    test('isUnlockable respeta el conjunto de dominados', () {
      expect(
        registry.isUnlockable(ConceptIds.openingRange, {}),
        isFalse,
      );
      expect(
        registry.isUnlockable(ConceptIds.openingRange, {
          ConceptIds.positionAdvantage,
          ConceptIds.handRanking,
        }),
        isTrue,
      );
    });
  });

  group('UserKnowledge (regla fundamental)', () {
    test('un concepto no enseñado no es evaluable', () {
      final k = UserKnowledge(registry);
      expect(k.isTaught(ConceptIds.threeBet), isFalse);
      k.teach(ConceptIds.openingRange);
      expect(k.isTaught(ConceptIds.openingRange), isTrue);
      expect(k.isTaught(ConceptIds.threeBet), isFalse);
    });

    test('recordAttempt no hace nada sobre conceptos bloqueados', () {
      final k = UserKnowledge(registry);
      k.recordAttempt(ConceptIds.ev, decisionCorrect: true);
      expect(k.masteryOf(ConceptIds.ev).attempts, 0);
    });

    test('la práctica sostenida lleva a mastered', () {
      final k = UserKnowledge(registry);
      k.teach(ConceptIds.openingRange);
      for (var i = 0; i < 12; i++) {
        k.recordAttempt(ConceptIds.openingRange, decisionCorrect: true);
      }
      expect(k.stateOf(ConceptIds.openingRange), MasteryState.mastered);
    });

    test('fallar mucho un concepto lo mantiene en práctica', () {
      final k = UserKnowledge(registry);
      k.teach(ConceptIds.openingRange);
      for (var i = 0; i < 10; i++) {
        k.recordAttempt(ConceptIds.openingRange, decisionCorrect: i % 3 == 0);
      }
      expect(k.stateOf(ConceptIds.openingRange), MasteryState.practicing);
      expect(k.weakConcepts(), isNotEmpty);
    });

    test('serialización ida y vuelta', () {
      final k = UserKnowledge(registry);
      k.teach(ConceptIds.openingRange);
      k.recordAttempt(ConceptIds.openingRange, decisionCorrect: true);
      final restored = UserKnowledge.fromJson(registry, k.toJson());
      expect(restored.isTaught(ConceptIds.openingRange), isTrue);
      expect(restored.masteryOf(ConceptIds.openingRange).attempts, 1);
    });
  });
}

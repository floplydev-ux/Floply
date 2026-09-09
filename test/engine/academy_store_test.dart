import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';

void main() {
  final registry = ConceptRegistry.standard();

  test('el progreso sobrevive a guardar y volver a cargar', () async {
    final store = InMemoryAcademyStore();

    final knowledge = UserKnowledge(registry);
    knowledge.teach(ConceptIds.rules);
    knowledge.recordAttempt(ConceptIds.rules, decisionCorrect: true);

    final progress = AcademyProgress(lastActivity: DateTime(2026, 9, 9));
    progress.entry('1.1')
      ..completed = true
      ..bestScore = 0.9
      ..attempts = 1
      ..passed = true;

    final data = AcademySaveData(knowledge: knowledge, progress: progress);
    await store.save(data);

    // Nueva instancia de store sembrada con el mismo blob: simula reinicio.
    final reopened = InMemoryAcademyStore(data.encode());
    final restored = await reopened.load(registry);

    expect(restored, isNotNull);
    expect(restored!.knowledge.isTaught(ConceptIds.rules), isTrue);
    expect(restored.knowledge.masteryOf(ConceptIds.rules).attempts, 1);
    expect(restored.progress.isCompleted('1.1'), isTrue);
    expect(restored.progress.entry('1.1').bestScore, 0.9);
    expect(restored.progress.lastActivity, DateTime(2026, 9, 9));
  });

  test('cargar de un store vacío devuelve null', () async {
    final store = InMemoryAcademyStore();
    expect(await store.load(registry), isNull);
  });

  test('encode/decode es estable', () {
    final knowledge = UserKnowledge(registry);
    knowledge.teach(ConceptIds.handRanking);
    final data = AcademySaveData(
      knowledge: knowledge,
      progress: AcademyProgress()..entry('2.1').completed = true,
    );
    final raw = data.encode();
    final back = AcademySaveData.decode(registry, raw);
    expect(back, isNotNull);
    expect(back!.knowledge.isTaught(ConceptIds.handRanking), isTrue);
    expect(back.progress.isCompleted('2.1'), isTrue);
  });

  test('clear borra el progreso', () async {
    final store = InMemoryAcademyStore();
    await store.save(AcademySaveData(
      knowledge: UserKnowledge(registry),
      progress: AcademyProgress(),
    ));
    await store.clear();
    expect(await store.load(registry), isNull);
  });
}

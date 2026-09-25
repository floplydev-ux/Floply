import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_concept_mastery.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/persistence/syncing_academy_store.dart';

/// Store que puede simular estar sin conexión (para probar el
/// fallback offline de [SyncingAcademyStore]).
class _FlakyStore implements AcademyStore {
  _FlakyStore(this._inner);
  final AcademyStore _inner;
  bool offline = false;

  @override
  Future<AcademySaveData?> load(ConceptRegistry registry) async {
    if (offline) throw Exception('sin conexión');
    return _inner.load(registry);
  }

  @override
  Future<void> save(AcademySaveData data) async {
    if (offline) throw Exception('sin conexión');
    await _inner.save(data);
  }

  @override
  Future<void> clear() async {
    if (offline) throw Exception('sin conexión');
    await _inner.clear();
  }
}

void main() {
  final registry = ConceptRegistry.standard();

  AcademySaveData dataWith({
    Map<String, LessonProgress> lessons = const {},
    Map<String, UserConceptMastery> mastery = const {},
  }) {
    return AcademySaveData(
      knowledge: UserKnowledge(registry, mastery),
      progress: AcademyProgress(lessons: lessons),
    );
  }

  LessonProgress lesson(
    String id, {
    bool completed = false,
    double bestScore = 0,
    int attempts = 0,
  }) =>
      LessonProgress(
          lessonId: id,
          completed: completed,
          bestScore: bestScore,
          attempts: attempts);

  UserConceptMastery mastery(
    String id, {
    MasteryState state = MasteryState.introduced,
    int attempts = 0,
    int decisionHits = 0,
  }) =>
      UserConceptMastery(
          conceptId: id,
          state: state,
          attempts: attempts,
          decisionHits: decisionHits);

  group('reconcile — casos A/B/C de la Fase 13', () {
    test('A) sin remoto + con local -> sube el local tal cual', () async {
      final local = InMemoryAcademyStore();
      final remote = InMemoryAcademyStore();
      await local
          .save(dataWith(lessons: {'1.1': lesson('1.1', completed: true)}));

      final store = SyncingAcademyStore(local: local, remote: remote);
      final merged = await store.reconcile(registry);

      expect(merged.progress.isCompleted('1.1'), isTrue);
      final onRemote = await remote.load(registry);
      expect(onRemote!.progress.isCompleted('1.1'), isTrue);
    });

    test('B) con remoto + sin local -> baja el remoto tal cual', () async {
      final local = InMemoryAcademyStore();
      final remote = InMemoryAcademyStore();
      await remote
          .save(dataWith(lessons: {'2.1': lesson('2.1', completed: true)}));

      final store = SyncingAcademyStore(local: local, remote: remote);
      final merged = await store.reconcile(registry);

      expect(merged.progress.isCompleted('2.1'), isTrue);
      final onLocal = await local.load(registry);
      expect(onLocal!.progress.isCompleted('2.1'), isTrue);
    });

    test(
        'C) ambos con datos -> merge conserva el estado más avanzado por '
        'lección (completada gana sobre no completada)', () async {
      final local = InMemoryAcademyStore();
      final remote = InMemoryAcademyStore();
      await local.save(dataWith(lessons: {
        '1.1': lesson('1.1', completed: true, bestScore: 0.9),
        '1.2': lesson('1.2', completed: false, bestScore: 0.3),
      }));
      await remote.save(dataWith(lessons: {
        '1.1': lesson('1.1', completed: false, bestScore: 0.5),
        '1.3': lesson('1.3', completed: true, bestScore: 1.0),
      }));

      final store = SyncingAcademyStore(local: local, remote: remote);
      final merged = await store.reconcile(registry);

      // 1.1: completa en local, incompleta en remoto -> gana completa.
      expect(merged.progress.isCompleted('1.1'), isTrue);
      expect(merged.progress.entry('1.1').bestScore, 0.9);
      // 1.2: solo en local -> se conserva.
      expect(merged.progress.isCompleted('1.2'), isFalse);
      // 1.3: solo en remoto -> se conserva.
      expect(merged.progress.isCompleted('1.3'), isTrue);
    });

    test(
        'C) el mejor puntaje gana cuando ninguna de las dos está '
        'completada', () async {
      final local = InMemoryAcademyStore();
      final remote = InMemoryAcademyStore();
      await local
          .save(dataWith(lessons: {'3.1': lesson('3.1', bestScore: 0.4)}));
      await remote
          .save(dataWith(lessons: {'3.1': lesson('3.1', bestScore: 0.7)}));

      final store = SyncingAcademyStore(local: local, remote: remote);
      final merged = await store.reconcile(registry);

      expect(merged.progress.entry('3.1').bestScore, 0.7);
    });

    test(
        'C) dominio por concepto: conserva el estado más avanzado, no '
        'mezcla campos de cada lado', () async {
      final local = InMemoryAcademyStore();
      final remote = InMemoryAcademyStore();
      await local.save(dataWith(mastery: {
        ConceptIds.openRaise: mastery(ConceptIds.openRaise,
            state: MasteryState.practicing, attempts: 5, decisionHits: 4),
      }));
      await remote.save(dataWith(mastery: {
        ConceptIds.openRaise: mastery(ConceptIds.openRaise,
            state: MasteryState.mastered, attempts: 10, decisionHits: 9),
      }));

      final store = SyncingAcademyStore(local: local, remote: remote);
      final merged = await store.reconcile(registry);

      final m = merged.knowledge.masteryOf(ConceptIds.openRaise);
      expect(m.state, MasteryState.mastered);
      // Gana el lado "mastered" completo, no una mezcla de intentos.
      expect(m.attempts, 10);
      expect(m.decisionHits, 9);
    });

    test(
        'idempotente: reconciliar dos veces seguidas da el mismo '
        'resultado, sin duplicar nada', () async {
      final local = InMemoryAcademyStore();
      final remote = InMemoryAcademyStore();
      await local
          .save(dataWith(lessons: {'1.1': lesson('1.1', completed: true)}));
      await remote
          .save(dataWith(lessons: {'2.1': lesson('2.1', completed: true)}));

      final store = SyncingAcademyStore(local: local, remote: remote);
      final first = await store.reconcile(registry);
      final second = await store.reconcile(registry);

      expect(second.progress.all.length, first.progress.all.length);
      expect(second.toJson(), first.toJson());
    });
  });

  group('offline (Fase 15)', () {
    test('load() cae al local si el remoto no responde', () async {
      final localInner = InMemoryAcademyStore();
      await localInner
          .save(dataWith(lessons: {'1.1': lesson('1.1', completed: true)}));
      final remote = _FlakyStore(InMemoryAcademyStore())..offline = true;

      final store = SyncingAcademyStore(local: localInner, remote: remote);
      final data = await store.load(registry);

      expect(data, isNotNull);
      expect(data!.progress.isCompleted('1.1'), isTrue);
    });

    test(
        'save() no pierde progreso si el remoto no responde: queda en '
        'local para el próximo intento', () async {
      final local = InMemoryAcademyStore();
      final remote = _FlakyStore(InMemoryAcademyStore())..offline = true;
      final store = SyncingAcademyStore(local: local, remote: remote);

      await store
          .save(dataWith(lessons: {'1.1': lesson('1.1', completed: true)}));

      final onLocal = await local.load(registry);
      expect(onLocal!.progress.isCompleted('1.1'), isTrue);
    });
  });
}

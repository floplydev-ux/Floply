import '../engine/academy/academy_progress.dart';
import '../engine/academy/academy_store.dart';
import '../engine/concepts/concept_registry.dart';
import '../engine/concepts/user_concept_mastery.dart';
import '../engine/concepts/user_knowledge.dart';

/// Decorador de `AcademyStore` (la interfaz YA EXISTENTE) que compone un
/// almacén local (`FileAcademyStore`) con uno remoto (`FirestoreAcademyStore`)
/// — LOCAL CACHE + REMOTE SYNC (Fase 15), sin que `AcademyController` note
/// la diferencia: sigue siendo un `AcademyStore` más.
///
/// Regla de oro: **nunca perder progreso**. `save` escribe primero local
/// (nunca depende de red) e intenta el remoto best-effort; si no hay red,
/// el próximo `save`/`reconcile` reintenta solo. `load` prioriza el
/// remoto (multi-dispositivo) pero cae al local si no hay red — la
/// Academia sigue funcionando offline.
class SyncingAcademyStore implements AcademyStore {
  SyncingAcademyStore({required this.local, required this.remote});

  final AcademyStore local;
  final AcademyStore remote;

  @override
  Future<AcademySaveData?> load(ConceptRegistry registry) async {
    try {
      final remoteData = await remote.load(registry);
      if (remoteData != null) {
        await local.save(remoteData);
        return remoteData;
      }
    } catch (_) {
      // Sin red: seguimos con lo que haya en el caché local.
    }
    return local.load(registry);
  }

  @override
  Future<void> save(AcademySaveData data) async {
    await local.save(data);
    try {
      await remote.save(data);
    } catch (_) {
      // Offline: el guardado remoto queda pendiente — el próximo save (o
      // reconcile, al reabrir con red) lo retoma. No se pierde nada: ya
      // quedó en el local.
    }
  }

  @override
  Future<void> clear() async {
    await local.clear();
    try {
      await remote.clear();
    } catch (_) {
      // best-effort, igual que save/load.
    }
  }

  /// Fase 12/13 — se llama UNA VEZ, justo después de autenticar (nunca en
  /// cada `load`): concilia lo que había en el dispositivo (posiblemente
  /// de uso como invitado) con lo que ya existe en la cuenta remota.
  ///
  ///  - A) sin remoto + con local  → sube el local tal cual.
  ///  - B) con remoto + sin local  → baja el remoto tal cual.
  ///  - C) ambos                  → merge campo a campo (ver [_merge]).
  ///
  /// Idempotente: correrlo dos veces da el mismo resultado (todo está
  /// keyado por ids de lección/concepto ya existentes, nunca se agregan
  /// ids nuevos acá — ver [_mergeLessonProgress]/[_mergeConceptMastery]).
  Future<AcademySaveData> reconcile(ConceptRegistry registry) async {
    final localData = await local.load(registry);
    final remoteData = await remote.load(registry);

    final AcademySaveData merged;
    if (remoteData == null && localData == null) {
      merged = AcademySaveData(
        knowledge: UserKnowledge(registry),
        progress: AcademyProgress(),
      );
    } else if (remoteData == null) {
      merged = localData!; // A
    } else if (localData == null) {
      merged = remoteData; // B
    } else {
      merged = _merge(registry, localData, remoteData); // C
    }

    await local.save(merged);
    await remote.save(merged);
    return merged;
  }

  // ----------------------------------------------------------------
  // Reglas de merge
  // ----------------------------------------------------------------

  AcademySaveData _merge(
    ConceptRegistry registry,
    AcademySaveData a,
    AcademySaveData b,
  ) {
    return AcademySaveData(
      progress: _mergeProgress(a.progress, b.progress),
      knowledge: _mergeKnowledge(registry, a.knowledge, b.knowledge),
    );
  }

  /// Progreso de lecciones: conserva el estado más avanzado por lección
  /// (completada gana sobre no completada, mejor puntaje gana el resto).
  AcademyProgress _mergeProgress(AcademyProgress a, AcademyProgress b) {
    final aById = {for (final l in a.all) l.lessonId: l};
    final bById = {for (final l in b.all) l.lessonId: l};
    final ids = {...aById.keys, ...bById.keys};

    final merged = <String, LessonProgress>{};
    for (final id in ids) {
      final la = aById[id];
      final lb = bById[id];
      if (la == null) {
        merged[id] = lb!;
      } else if (lb == null) {
        merged[id] = la;
      } else {
        merged[id] = _mergeLessonProgress(la, lb);
      }
    }

    return AcademyProgress(
      lessons: merged,
      lastActivity: _latest(a.lastActivity, b.lastActivity),
    );
  }

  LessonProgress _mergeLessonProgress(LessonProgress a, LessonProgress b) {
    final aIsBest = a.bestScore >= b.bestScore;
    final best = aIsBest ? a : b;
    return LessonProgress(
      lessonId: a.lessonId,
      completed: a.completed || b.completed,
      passed: a.passed || b.passed,
      attempts: a.attempts > b.attempts ? a.attempts : b.attempts,
      bestScore: a.bestScore > b.bestScore ? a.bestScore : b.bestScore,
      lastScore: best.lastScore,
    );
  }

  /// Dominio por concepto: fusiona por concepto tomando el lado "más
  /// avanzado" completo (estado, después intentos, después dominio) en
  /// vez de mezclar campos sueltos de cada lado — así nunca se rompe la
  /// relación interna aciertos/intentos de cada [UserConceptMastery].
  UserKnowledge _mergeKnowledge(
    ConceptRegistry registry,
    UserKnowledge a,
    UserKnowledge b,
  ) {
    final aById = {for (final m in a.all) m.conceptId: m};
    final bById = {for (final m in b.all) m.conceptId: m};
    final ids = {...aById.keys, ...bById.keys};

    final merged = <String, UserConceptMastery>{};
    for (final id in ids) {
      final ma = aById[id];
      final mb = bById[id];
      if (ma == null) {
        merged[id] = mb!;
      } else if (mb == null) {
        merged[id] = ma;
      } else {
        merged[id] = _mergeConceptMastery(ma, mb);
      }
    }

    return UserKnowledge(registry, merged);
  }

  static const Map<MasteryState, int> _stateOrder = {
    MasteryState.locked: 0,
    MasteryState.introduced: 1,
    MasteryState.practicing: 2,
    MasteryState.mastered: 3,
  };

  UserConceptMastery _mergeConceptMastery(
    UserConceptMastery a,
    UserConceptMastery b,
  ) {
    final cmp = _stateOrder[a.state]!.compareTo(_stateOrder[b.state]!);
    final UserConceptMastery winner;
    if (cmp != 0) {
      winner = cmp > 0 ? a : b;
    } else if (a.attempts != b.attempts) {
      winner = a.attempts > b.attempts ? a : b;
    } else {
      winner = a.mastery >= b.mastery ? a : b;
    }
    return UserConceptMastery(
      conceptId: winner.conceptId,
      state: winner.state,
      attempts: winner.attempts,
      decisionHits: winner.decisionHits,
      reasoningAttempts: winner.reasoningAttempts,
      reasoningHits: winner.reasoningHits,
      mistakes: winner.mistakes,
      lastPracticed: _latest(a.lastPracticed, b.lastPracticed),
    );
  }

  DateTime? _latest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}

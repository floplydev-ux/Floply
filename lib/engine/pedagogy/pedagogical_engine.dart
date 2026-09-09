import 'dart:math';

import '../concepts/concept_registry.dart';
import '../concepts/user_concept_mastery.dart';
import '../concepts/user_knowledge.dart';
import 'curriculum.dart';

/// Un objetivo pedagógico concreto para el próximo ejercicio.
class PedagogicalGoal {
  const PedagogicalGoal({
    required this.conceptId,
    required this.reason,
    required this.suggestedDifficulty,
  });

  final String conceptId;
  final GoalReason reason;
  final int suggestedDifficulty;
}

enum GoalReason {
  /// Concepto recién introducido, hay que practicarlo.
  freshIntroduction,

  /// Concepto en práctica que todavía no se domina.
  buildingMastery,

  /// Concepto débil detectado: sesión de recuperación.
  recovery,

  /// Repaso de un concepto ya dominado (spaced practice).
  spacedReview,
}

/// Decide QUÉ debería practicar/evaluar el usuario y con qué dificultad.
///
/// Es el guardián de la regla fundamental: nunca propone un objetivo
/// sobre un concepto que el usuario no tiene enseñado.
class PedagogicalEngine {
  PedagogicalEngine(this._registry, this._curriculum);

  final ConceptRegistry _registry;
  final Curriculum _curriculum;

  Curriculum get curriculum => _curriculum;
  ConceptRegistry get registry => _registry;

  /// Conceptos que se le pueden exigir al usuario ahora mismo.
  Set<String> evaluableConcepts(UserKnowledge knowledge) =>
      knowledge.taughtConcepts;

  bool canEvaluate(String conceptId, UserKnowledge knowledge) =>
      knowledge.isTaught(conceptId);

  /// Filtra una lista de conceptos dejando solo los que se pueden
  /// evaluar. Es la función que todo generador/evaluador debe usar antes
  /// de exigir un concepto.
  List<String> keepEvaluable(
    Iterable<String> conceptIds,
    UserKnowledge knowledge,
  ) =>
      conceptIds.where(knowledge.isTaught).toList();

  /// Conceptos listos para desbloquear: prerrequisitos dominados pero
  /// todavía `locked`.
  List<String> unlockableConcepts(UserKnowledge knowledge) {
    final mastered = knowledge.masteredConcepts;
    return _registry.all
        .where((c) =>
            knowledge.stateOf(c.id) == MasteryState.locked &&
            _registry.isUnlockable(c.id, mastered))
        .map((c) => c.id)
        .toList();
  }

  /// Elige el próximo objetivo pedagógico. Si [preferredConcept] viene y
  /// es evaluable, se respeta.
  ///
  /// [practiceable] restringe los candidatos a conceptos para los que
  /// existe al menos un ejercicio (lo pasa el generador). Los conceptos
  /// enseñados sin cobertura de ejercicios (p. ej. "reglas") no se eligen
  /// como objetivo pero siguen contando para desbloquear otros.
  PedagogicalGoal nextGoal(
    UserKnowledge knowledge, {
    String? preferredConcept,
    Set<String>? practiceable,
    Random? rng,
  }) {
    bool ok(String id) =>
        knowledge.isTaught(id) &&
        (practiceable == null || practiceable.contains(id));

    if (preferredConcept != null && ok(preferredConcept)) {
      return PedagogicalGoal(
        conceptId: preferredConcept,
        reason: GoalReason.buildingMastery,
        suggestedDifficulty: _difficultyFor(knowledge, preferredConcept),
      );
    }

    // Entre varios candidatos de la misma prioridad, se rota (con [rng] si
    // se pasó) para no machacar siempre el mismo concepto.
    UserConceptMastery? rotate(List<UserConceptMastery> candidates) {
      if (candidates.isEmpty) return null;
      if (rng == null) return candidates.first;
      return candidates[rng.nextInt(candidates.length)];
    }

    // 1. Conceptos débiles → recuperación (siempre el más flojo primero).
    final weak =
        knowledge.weakConcepts().where((m) => ok(m.conceptId)).toList();
    if (weak.isNotEmpty) {
      return PedagogicalGoal(
        conceptId: weak.first.conceptId,
        reason: GoalReason.recovery,
        suggestedDifficulty: 2,
      );
    }

    // 2. Conceptos recién introducidos (los menos practicados).
    final fresh = knowledge.all
        .where((m) => m.state == MasteryState.introduced && ok(m.conceptId))
        .toList()
      ..sort((a, b) => a.attempts.compareTo(b.attempts));
    if (fresh.isNotEmpty) {
      final minAttempts = fresh.first.attempts;
      final target =
          rotate(fresh.where((m) => m.attempts <= minAttempts + 1).toList())!;
      return PedagogicalGoal(
        conceptId: target.conceptId,
        reason: GoalReason.freshIntroduction,
        suggestedDifficulty: 1,
      );
    }

    // 3. Conceptos en práctica, priorizando los menos dominados.
    final practicing = knowledge.all
        .where((m) => m.state == MasteryState.practicing && ok(m.conceptId))
        .toList()
      ..sort((a, b) => a.mastery.compareTo(b.mastery));
    if (practicing.isNotEmpty) {
      final worst = practicing.first.mastery;
      final target = rotate(
          practicing.where((m) => m.mastery <= worst + 0.15).toList())!;
      return PedagogicalGoal(
        conceptId: target.conceptId,
        reason: GoalReason.buildingMastery,
        suggestedDifficulty: _difficultyFor(knowledge, target.conceptId),
      );
    }

    // 4. Todo dominado → repaso espaciado.
    final mastered = knowledge.all
        .where((m) => m.state == MasteryState.mastered && ok(m.conceptId))
        .toList()
      ..sort((a, b) => (a.lastPracticed ?? DateTime(0))
          .compareTo(b.lastPracticed ?? DateTime(0)));
    if (mastered.isNotEmpty) {
      final target = rotate(mastered.take(3).toList())!;
      return PedagogicalGoal(
        conceptId: target.conceptId,
        reason: GoalReason.spacedReview,
        suggestedDifficulty: 3,
      );
    }

    throw StateError(
        'El usuario no tiene ningún concepto practicable enseñado: enseñá al '
        'menos un concepto con ejercicios antes de pedir práctica.');
  }

  int _difficultyFor(UserKnowledge knowledge, String conceptId) {
    final mastery = knowledge.masteryOf(conceptId).mastery;
    if (mastery < 0.35) return 1;
    if (mastery < 0.6) return 2;
    if (mastery < 0.8) return 3;
    return 4;
  }

  /// Aplica un sub-nivel: marca como enseñados sus conceptos nuevos.
  void applyLesson(String lessonId, UserKnowledge knowledge) {
    final lesson = _curriculum.lessonById(lessonId);
    if (lesson == null) return;
    knowledge.teachAll(lesson.conceptsIntroduced);
  }
}

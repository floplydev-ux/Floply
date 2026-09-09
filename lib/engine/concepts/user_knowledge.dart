import 'concept_registry.dart';
import 'user_concept_mastery.dart';

/// El estado de conocimiento completo de un usuario: qué conceptos tiene
/// desbloqueados y cómo le va con cada uno.
///
/// Es la fuente de verdad de la **regla fundamental del motor**: solo se
/// puede evaluar al usuario con conceptos cuyo estado no sea `locked`.
class UserKnowledge {
  UserKnowledge(this._registry, [Map<String, UserConceptMastery>? initial])
      : _mastery = initial ?? {};

  final ConceptRegistry _registry;
  final Map<String, UserConceptMastery> _mastery;

  Iterable<UserConceptMastery> get all => _mastery.values;

  UserConceptMastery _entry(String conceptId) => _mastery.putIfAbsent(
        conceptId,
        () => UserConceptMastery(conceptId: conceptId),
      );

  MasteryState stateOf(String conceptId) =>
      _mastery[conceptId]?.state ?? MasteryState.locked;

  UserConceptMastery masteryOf(String conceptId) => _entry(conceptId);

  /// La regla fundamental: ¿se le puede exigir este concepto al usuario?
  bool isTaught(String conceptId) => stateOf(conceptId) != MasteryState.locked;

  bool areAllTaught(Iterable<String> conceptIds) =>
      conceptIds.every(isTaught);

  /// Conceptos que el usuario ya conoce (introduced/practicing/mastered).
  Set<String> get taughtConcepts =>
      _mastery.values
          .where((m) => m.state != MasteryState.locked)
          .map((m) => m.conceptId)
          .toSet();

  /// Conceptos dominados (mastered), usados para desbloquear otros.
  Set<String> get masteredConcepts => _mastery.values
      .where((m) => m.state == MasteryState.mastered)
      .map((m) => m.conceptId)
      .toSet();

  /// Marca un concepto como enseñado (pasa de `locked` a `introduced`).
  /// No baja el estado si ya estaba más avanzado.
  void teach(String conceptId) {
    if (!_registry.has(conceptId)) {
      throw ArgumentError('Concepto desconocido: "$conceptId"');
    }
    final entry = _entry(conceptId);
    if (entry.state == MasteryState.locked) {
      entry.state = MasteryState.introduced;
    }
  }

  void teachAll(Iterable<String> conceptIds) => conceptIds.forEach(teach);

  /// Fuerza el estado de un concepto (útil en tests y en la carga inicial).
  void setState(String conceptId, MasteryState state) {
    _entry(conceptId).state = state;
  }

  /// Registra el resultado de un intento sobre un concepto.
  void recordAttempt(
    String conceptId, {
    required bool decisionCorrect,
    bool? reasoningCorrect,
  }) {
    if (!isTaught(conceptId)) {
      // Defensa: nunca se debería registrar sobre un concepto bloqueado.
      return;
    }
    _entry(conceptId).record(
      decisionCorrect: decisionCorrect,
      reasoningCorrect: reasoningCorrect,
    );
  }

  /// Conceptos enseñados cuyo dominio está por debajo de [threshold].
  List<UserConceptMastery> weakConcepts({double threshold = 0.7}) {
    final weak = _mastery.values
        .where((m) =>
            m.state != MasteryState.locked &&
            m.attempts >= 3 &&
            m.mastery < threshold)
        .toList();
    weak.sort((a, b) => a.mastery.compareTo(b.mastery));
    return weak;
  }

  Map<String, dynamic> toJson() => {
        'mastery': {
          for (final entry in _mastery.entries) entry.key: entry.value.toJson(),
        },
      };

  factory UserKnowledge.fromJson(
    ConceptRegistry registry,
    Map<String, dynamic> json,
  ) {
    final raw = (json['mastery'] as Map<String, dynamic>? ?? {});
    return UserKnowledge(registry, {
      for (final entry in raw.entries)
        entry.key: UserConceptMastery.fromJson(
          entry.value as Map<String, dynamic>,
        ),
    });
  }
}

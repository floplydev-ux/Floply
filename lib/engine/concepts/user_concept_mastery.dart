/// En qué punto de aprendizaje está el usuario respecto de un concepto.
enum MasteryState {
  /// Todavía no se cumplen los prerrequisitos: no se puede evaluar.
  locked,

  /// Ya se presentó en teoría pero casi no se practicó.
  introduced,

  /// En práctica activa; el usuario acierta a veces.
  practicing,

  /// Dominado de forma consistente.
  mastered,
}

/// Métricas y estado de aprendizaje del usuario para un concepto puntual.
class UserConceptMastery {
  UserConceptMastery({
    required this.conceptId,
    this.state = MasteryState.locked,
    this.attempts = 0,
    this.decisionHits = 0,
    this.reasoningAttempts = 0,
    this.reasoningHits = 0,
    this.mistakes = 0,
    this.lastPracticed,
  });

  final String conceptId;
  MasteryState state;

  int attempts;
  int decisionHits;
  int reasoningAttempts;
  int reasoningHits;
  int mistakes;
  DateTime? lastPracticed;

  /// Nivel de dominio 0..1, combinando volumen y acierto.
  double get mastery {
    if (attempts == 0) return 0;
    final accuracy = decisionAccuracy;
    // Se necesita algo de volumen para llegar a 1.0.
    final volumeFactor = (attempts / 12).clamp(0.0, 1.0);
    return (accuracy * (0.4 + 0.6 * volumeFactor)).clamp(0.0, 1.0);
  }

  double get decisionAccuracy =>
      attempts == 0 ? 0 : decisionHits / attempts;

  double get reasoningAccuracy =>
      reasoningAttempts == 0 ? 0 : reasoningHits / reasoningAttempts;

  bool get isTaught => state != MasteryState.locked;

  /// Registra un intento sobre este concepto y recalcula el estado.
  void record({
    required bool decisionCorrect,
    bool? reasoningCorrect,
  }) {
    attempts++;
    if (decisionCorrect) {
      decisionHits++;
    } else {
      mistakes++;
    }
    if (reasoningCorrect != null) {
      reasoningAttempts++;
      if (reasoningCorrect) reasoningHits++;
    }
    lastPracticed = DateTime.now();
    _recomputeState();
  }

  void _recomputeState() {
    if (state == MasteryState.locked) return;

    final dominated =
        attempts >= 8 && decisionAccuracy >= 0.85 && mastery >= 0.8;
    if (dominated) {
      state = MasteryState.mastered;
      return;
    }

    // Un concepto que estaba dominado y se empieza a fallar vuelve a
    // práctica; uno recién introducido pasa a práctica en el primer
    // intento.
    if (state == MasteryState.mastered && decisionAccuracy < 0.7) {
      state = MasteryState.practicing;
    } else if (state == MasteryState.introduced && attempts >= 1) {
      state = MasteryState.practicing;
    }
  }

  Map<String, dynamic> toJson() => {
        'conceptId': conceptId,
        'state': state.name,
        'attempts': attempts,
        'decisionHits': decisionHits,
        'reasoningAttempts': reasoningAttempts,
        'reasoningHits': reasoningHits,
        'mistakes': mistakes,
        'lastPracticed': lastPracticed?.toIso8601String(),
      };

  factory UserConceptMastery.fromJson(Map<String, dynamic> json) {
    return UserConceptMastery(
      conceptId: json['conceptId'] as String,
      state: MasteryState.values.byName(json['state'] as String),
      attempts: json['attempts'] as int? ?? 0,
      decisionHits: json['decisionHits'] as int? ?? 0,
      reasoningAttempts: json['reasoningAttempts'] as int? ?? 0,
      reasoningHits: json['reasoningHits'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      lastPracticed: (json['lastPracticed'] as String?) != null
          ? DateTime.parse(json['lastPracticed'] as String)
          : null,
    );
  }
}

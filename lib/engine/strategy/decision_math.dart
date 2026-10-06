/// Valores matemáticos reales de una decisión — nunca inventados: cada
/// campo se completa solo cuando el motor (o una fórmula directa sobre
/// datos ya reales del escenario, ver `LabFeedbackBuilder`) realmente lo
/// calculó. Vive en `StrategyOption.math` cuando el motor de estrategia
/// ya lo produjo (equity real, pot odds), o se completa después en
/// `LabFeedbackBuilder` con aritmética directa sobre `DecisionContext`
/// (SPR, MDF) — nunca un segundo motor paralelo.
class DecisionMath {
  const DecisionMath({
    this.equityPct,
    this.requiredEquityPct,
    this.edgePct,
    this.potBb,
    this.toCallBb,
    this.betBb,
    this.stackBb,
    this.sprValue,
    this.mdfPct,
  });

  /// Equity real de la mano del héroe contra el rango de referencia
  /// (`EquityEngine.handVsRange`, 0..100).
  final double? equityPct;

  /// Equity mínima necesaria para que pagar sea matemáticamente
  /// defendible (`toCallBb / (potBb + toCallBb)`, 0..100).
  final double? requiredEquityPct;

  /// `equityPct - requiredEquityPct` — cuánto margen (o déficit) hay.
  final double? edgePct;

  final double? potBb;
  final double? toCallBb;
  final double? betBb;
  final double? stackBb;

  /// Stack-to-pot ratio: stack efectivo / bote.
  final double? sprValue;

  /// Frecuencia mínima de defensa (Minimum Defense Frequency),
  /// `potBb / (potBb + betBb)`, 0..100.
  final double? mdfPct;

  bool get hasAny =>
      equityPct != null ||
      requiredEquityPct != null ||
      potBb != null ||
      toCallBb != null ||
      betBb != null ||
      sprValue != null ||
      mdfPct != null;

  DecisionMath copyWith({
    double? equityPct,
    double? requiredEquityPct,
    double? edgePct,
    double? potBb,
    double? toCallBb,
    double? betBb,
    double? stackBb,
    double? sprValue,
    double? mdfPct,
  }) =>
      DecisionMath(
        equityPct: equityPct ?? this.equityPct,
        requiredEquityPct: requiredEquityPct ?? this.requiredEquityPct,
        edgePct: edgePct ?? this.edgePct,
        potBb: potBb ?? this.potBb,
        toCallBb: toCallBb ?? this.toCallBb,
        betBb: betBb ?? this.betBb,
        stackBb: stackBb ?? this.stackBb,
        sprValue: sprValue ?? this.sprValue,
        mdfPct: mdfPct ?? this.mdfPct,
      );
}

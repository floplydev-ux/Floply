/// El resultado de calcular el valor esperado (EV) de apostar o subir —
/// a diferencia de [EVResult] (EV de pagar un call), acá entra un
/// término que un call nunca necesita: la **fold equity** (la
/// probabilidad de que el rival se retire y el héroe se lleve el bote
/// sin showdown).
///
/// **Alcance deliberado (ver `EV_AVANZADO_AUDITORIA_DISENO.md`,
/// Modelo A)**: solo modela dos ramas — el rival foldea, o el rival
/// paga. La rama "el rival sube" queda explícitamente afuera del
/// cálculo (no se inventa un valor para ella) — [unmodeledProbability]
/// expone cuánta probabilidad quedó sin modelar para que la UI pueda
/// mostrarlo con honestidad, nunca para que el cálculo la trate como
/// cero valor real.
class EVBetResult {
  const EVBetResult({
    required this.foldProbability,
    required this.callProbability,
    required this.potBeforeBetBb,
    required this.betSizeBb,
    required this.equityIfCalled,
  });

  /// Probabilidad (0..1) de que el rival se retire ante esta apuesta.
  final double foldProbability;

  /// Probabilidad (0..1) de que el rival pague esta apuesta (sin subir).
  final double callProbability;

  /// El bote tal cual está justo antes de que el héroe haga esta
  /// apuesta — no incluye la apuesta en sí.
  final double potBeforeBetBb;

  /// Cuánto apuesta o sube el héroe (el incremento, no un total
  /// acumulado de calles anteriores).
  final double betSizeBb;

  /// Equity del héroe **si el rival paga** — típicamente
  /// `EquityEngine.handVsRange(...).equity` contra el rango de
  /// continuación del rival, nunca contra su rango de apertura sin
  /// angostar (ver el informe de diseño, punto 4).
  final double equityIfCalled;

  /// Cuánta probabilidad no fue asignada a fold ni a call — la rama
  /// "el rival sube", que este cálculo no resuelve. `0.0` si
  /// `foldProbability + callProbability == 1.0`.
  double get unmodeledProbability => 1 - foldProbability - callProbability;

  /// El bote si el rival paga: lo que había, más la apuesta del héroe,
  /// más el call del rival (mismo tamaño que la apuesta, en este
  /// modelo simplificado sin re-raise).
  double get finalPotIfCalledBb => potBeforeBetBb + 2 * betSizeBb;

  /// Contribución de la rama "el rival foldea": el héroe se lleva todo
  /// el bote que ya había, sin necesidad de equity — no hay showdown.
  double get evFoldBb => foldProbability * potBeforeBetBb;

  /// Contribución de la rama "el rival paga": la misma fórmula que
  /// [EVResult.evBb], ponderada por [callProbability].
  double get evCallBb =>
      callProbability * (equityIfCalled * finalPotIfCalledBb - betSizeBb);

  /// EV total de la apuesta, sumando ambas ramas modeladas. Si
  /// [unmodeledProbability] > 0, este número es una cota parcial, no el
  /// EV completo de la apuesta — la UI tiene que decirlo.
  double get evBb => evFoldBb + evCallBb;

  static const double _epsilon = 1e-9;

  bool get isProfitable => evBb > _epsilon;
  bool get isBreakEven => evBb.abs() <= _epsilon;
  bool get isLosing => evBb < -_epsilon;

  @override
  String toString() =>
      'EVBetResult(fold: ${(foldProbability * 100).toStringAsFixed(1)}%, '
      'call: ${(callProbability * 100).toStringAsFixed(1)}%, '
      'unmodeled: ${(unmodeledProbability * 100).toStringAsFixed(1)}%, '
      'ev: ${evBb.toStringAsFixed(4)} bb)';
}

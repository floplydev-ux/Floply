/// El resultado de calcular pot odds — nunca se mezcla con equity ni con
/// EV (`requiredEquity` es la equity MÍNIMA necesaria para que pagar sea
/// break-even, no la equity real de ninguna mano; eso es trabajo de
/// `EquityEngine`, y `EVEngine` es quien los combina).
///
/// Guarda únicamente los dos datos de entrada — mismo criterio que
/// `EquityResult`/`EVResult`: todo lo demás es un getter derivado, así
/// la fórmula existe en un solo lugar y no puede desincronizarse de lo
/// que el resultado expone.
class PotOddsResult {
  const PotOddsResult({
    required this.potBeforeCallBb,
    required this.callAmountBb,
  });

  /// El bote antes de que el héroe pague — ya incluye lo que apostó el
  /// rival en esta calle.
  final double potBeforeCallBb;

  /// Lo que el héroe tiene que poner para seguir en la mano.
  final double callAmountBb;

  /// El bote DESPUÉS de que el héroe paga — `potBeforeCallBb +
  /// callAmountBb`. `potBeforeCallBb >= 0` siempre (validado por
  /// `PotOddsEngine.calculate`), así que `finalPotBb >= callAmountBb`
  /// también siempre — no es una regla de negocio, es la definición.
  double get finalPotBb => potBeforeCallBb + callAmountBb;

  /// Equity mínima, en `[0, 1]`, que necesita el héroe para que pagar
  /// sea break-even a largo plazo: `callAmountBb / finalPotBb`. `0.0` si
  /// `finalPotBb == 0` (fuerza `callAmountBb == 0`: nada que pagar, no
  /// `NaN` por una división por cero silenciosa).
  double get requiredEquity => finalPotBb == 0 ? 0.0 : callAmountBb / finalPotBb;

  /// La "X" en "X:1" — cuánto bote hay por cada unidad que el héroe
  /// arriesga (`potBeforeCallBb / callAmountBb`). `null` si no hay nada
  /// que pagar (`callAmountBb == 0`, la razón no está definida).
  double? get potOddsRatio => callAmountBb == 0 ? null : potBeforeCallBb / callAmountBb;

  @override
  String toString() =>
      'PotOddsResult(pot: $potBeforeCallBb, call: $callAmountBb, '
      'requiredEquity: ${(requiredEquity * 100).toStringAsFixed(1)}%)';
}

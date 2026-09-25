/// El resultado de calcular el valor esperado (EV) de pagar un call,
/// dada una equity conocida.
///
/// Guarda únicamente los tres datos de entrada — `evBb` es un getter
/// derivado, nunca un campo aparte (mismo criterio que ya usan
/// `EquityResult.total` y `PotOddsResult.finalPotBb`): así la fórmula
/// solo existe en un lugar y no puede desincronizarse de lo que el
/// resultado expone.
class EVResult {
  const EVResult({
    required this.equity,
    required this.finalPotBb,
    required this.callAmountBb,
  });

  /// Probabilidad de ganar la mano (heads-up), en `[0, 1]` — típicamente
  /// `EquityResult.equity`, pero `EVEngine` nunca lo exige: solo
  /// necesita el número, nunca reconstruye la probabilidad a partir de
  /// wins/ties/losses.
  final double equity;

  /// El bote DESPUÉS de que el héroe paga el call — típicamente
  /// `PotOddsResult.finalPotBb`. `callAmountBb` ya está incluido acá.
  final double finalPotBb;

  /// Lo que le costó al héroe pagar.
  final double callAmountBb;

  /// `equity * finalPotBb - callAmountBb`. `callAmountBb` se resta una
  /// sola vez: como ya está incluido dentro de `finalPotBb`, no vuelve a
  /// descontarse por segunda vez en ningún otro término (nunca
  /// `* (1 - equity)` ni ninguna variante).
  double get evBb => equity * finalPotBb - callAmountBb;

  /// Tolerancia para comparar `evBb` contra cero. No es un umbral de
  /// negocio ("cerca de cero alcanza") — es una cota del error de
  /// representación de `double` en la multiplicación/resta de `evBb`, a
  /// las magnitudes con las que trabaja este motor (BB de una mesa de
  /// póker, nunca astronómicas). Si en el futuro `finalPotBb` maneja
  /// valores extremadamente grandes, esta cota debería revisarse con
  /// ese caso en mente, no ampliarse "por las dudas".
  static const double _epsilon = 1e-9;

  /// Solo matemática: `evBb` es mayor a cero (más allá del ruido de
  /// `double`). No es una recomendación de póker — no significa "pagá",
  /// solo describe el resultado bajo los supuestos que se le pasaron a
  /// [EVResult] vía `EVEngine.calculateCall`.
  bool get isProfitable => evBb > _epsilon;

  /// `evBb` es indistinguible de cero dentro de la tolerancia de
  /// `double` — matemáticamente breakeven hasta el error de
  /// representación de la fórmula, no "está cerca".
  bool get isBreakEven => evBb.abs() <= _epsilon;

  bool get isLosing => evBb < -_epsilon;

  @override
  String toString() =>
      'EVResult(equity: ${(equity * 100).toStringAsFixed(2)}%, '
      'finalPot: $finalPotBb bb, call: $callAmountBb bb, '
      'ev: ${evBb.toStringAsFixed(4)} bb)';
}

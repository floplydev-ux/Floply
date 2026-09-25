/// Convierte entre un tamaño de apuesta en BB y su fracción del bote —
/// el cálculo genérico de sizing postflop que hoy no existe en ningún
/// otro lugar del motor.
///
/// **No duplica el sizing preflop**: `OpeningRanges.sizingFor`/
/// `.isReasonableSizing` ya resuelven eso (tamaño de apertura por
/// posición, con sus propios límites razonables) y siguen siendo la
/// única fuente de verdad para RFI — nada de esta clase los reemplaza
/// ni los envuelve. `BetSizingEngine` es específicamente el
/// complemento postflop: "bet/raise como % del bote", que preflop no
/// necesita (ahí se piensa en BB, no en fracción de pot).
class BetSizingEngine {
  const BetSizingEngine._();

  /// El monto en BB que representa apostar [fraction] del bote.
  /// `fraction: 1.0` es un bet del tamaño exacto del bote,
  /// `fraction: 0.5` la mitad, etc.
  ///
  /// Lanza [ArgumentError] si [potBb] o [fraction] son negativos o no
  /// finitos.
  static double potSizedBet(double potBb, {double fraction = 1.0}) {
    _validateNonNegativeFinite(potBb, 'potBb');
    _validateNonNegativeFinite(fraction, 'fraction');
    return potBb * fraction;
  }

  /// La fracción del bote que representa [sizeBb] — inverso de
  /// [potSizedBet], para mostrar "esto es 66% del pot" dado un tamaño
  /// concreto (p. ej. el que ya eligió un rival en `GameState`).
  ///
  /// Lanza [ArgumentError] si [sizeBb] es negativo/no finito, o si
  /// [potBb] no es estrictamente positivo — un bote de 0 no tiene una
  /// fracción de sí mismo definida (no es un caso degenerado válido
  /// como sí lo son `PotOddsEngine`/`EVEngine` con pot 0: acá dividir
  /// por 0 no representa ninguna situación real de mesa, apostar algo
  /// contra un bote vacío no es "apostar el X% del bote").
  static double asFractionOfPot(double sizeBb, double potBb) {
    _validateNonNegativeFinite(sizeBb, 'sizeBb');
    _validateNonNegativeFinite(potBb, 'potBb');
    if (potBb <= 0) {
      throw ArgumentError.value(potBb, 'potBb',
          'BetSizingEngine.asFractionOfPot: potBb debe ser mayor que 0.');
    }
    return sizeBb / potBb;
  }

  static void _validateNonNegativeFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name,
          'BetSizingEngine: $name debe ser un número finito.');
    }
    if (value < 0) {
      throw ArgumentError.value(
          value, name, 'BetSizingEngine: $name no puede ser negativo.');
    }
  }
}

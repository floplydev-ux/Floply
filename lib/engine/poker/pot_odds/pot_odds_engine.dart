import 'pot_odds_result.dart';

/// Calcula pot odds — pura aritmética sobre pot/call, sin depender de
/// `GameState` ni de ninguna capa de `exercises/` (regla del motor:
/// `poker/` nunca importa de `exercises/`, ver el doc-comment de
/// `TemplateGenerationException`). Un futuro caller en `exercises/` o
/// `screens/` que tenga un `DecisionContext` real solo necesita
/// `PotOddsEngine.calculate(potBeforeCallBb: context.potBb, callAmountBb:
/// context.toCallBb)` — no hace falta un adaptador dedicado acá.
class PotOddsEngine {
  const PotOddsEngine._();

  /// [potBeforeCallBb] es el bote antes de que el héroe pague — ya
  /// incluye cualquier apuesta del rival en esta calle. [callAmountBb]
  /// es lo que le cuesta al héroe seguir en la mano.
  ///
  /// Ejemplo: pot 15bb (10bb que había + 5bb que apostó el rival), call
  /// 5bb -> finalPotBb = 20, requiredEquity = 5/20 = 25%.
  ///
  /// Lanza [ArgumentError] si algún monto es negativo o no es finito
  /// (`NaN`/`Infinity`) — un motor matemático no debería poder aceptar
  /// una entrada que ya es inválida y devolver un resultado sin sentido
  /// más adelante.
  static PotOddsResult calculate({
    required double potBeforeCallBb,
    required double callAmountBb,
  }) {
    _validateNonNegativeFinite(potBeforeCallBb, 'potBeforeCallBb');
    _validateNonNegativeFinite(callAmountBb, 'callAmountBb');
    return PotOddsResult(
      potBeforeCallBb: potBeforeCallBb,
      callAmountBb: callAmountBb,
    );
  }

  static void _validateNonNegativeFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(
          value, name, 'PotOddsEngine: $name debe ser un número finito.');
    }
    if (value < 0) {
      throw ArgumentError.value(
          value, name, 'PotOddsEngine: $name no puede ser negativo.');
    }
  }
}

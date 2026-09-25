import 'ev_bet_result.dart';
import 'ev_result.dart';

/// Expected value (EV) de una decisión — puro cálculo matemático, sin
/// depender de `EquityEngine`, `PotOddsEngine` ni de sus resultados.
///
/// Dos casos, dos resultados: [calculateCall] (Fase 5, EV de pagar) da
/// un [EVResult]; [calculateBet] (EV Avanzado — Tools V2, ver
/// `EV_AVANZADO_AUDITORIA_DISENO.md`) da un [EVBetResult], porque
/// apostar/subir tiene un término que pagar nunca necesita: la fold
/// equity. Deliberadamente dos métodos con dos tipos de resultado, no
/// uno solo con campos opcionales — cada uno modela una decisión
/// distinta con una fórmula distinta.
///
/// **Decisión de arquitectura (auditoría de Fase 5, vigente también
/// para [calculateBet])**: recibe `double`s sueltos, no `EquityResult`/
/// `PotOddsResult`. Mismo criterio que ya aplicó `PotOddsEngine` en la
/// Fase 4 (no acoplarse a un objeto más pesado del que hace falta, para
/// poder usarse desde Tools/Laboratorio/tests con solo unos pocos
/// números): acá el mismo razonamiento aplica un nivel más arriba.
/// `EquityEngine`/`PotOddsEngine` no conocen a `EVEngine` y `EVEngine`
/// tampoco necesita conocer sus tipos de resultado — un caller que sí
/// tiene un `EquityResult`/`PotOddsResult` simplemente pasa
/// `.equity`/`.finalPotBb`/`.callAmountBb`. La composición de los
/// motores vive en quien los llama, nunca en ninguno de ellos.
class EVEngine {
  const EVEngine._();

  /// EV de pagar un call heads-up: `equity * finalPotBb - callAmountBb`.
  ///
  /// [equity] es la probabilidad de ganar (típicamente
  /// `EquityResult.equity` — este engine nunca la reconstruye a partir
  /// de wins/ties/losses, la recibe ya calculada). [finalPotBb] es el
  /// bote DESPUÉS de que el héroe paga (típicamente
  /// `PotOddsResult.finalPotBb`) — `callAmountBb` ya está adentro de ese
  /// número, así que nunca se vuelve a restar por segunda vez ni se
  /// multiplica por `(1 - equity)`.
  ///
  /// Casos borde, decididos explícitamente (mismo criterio que
  /// `PotOddsEngine.calculate` en la Fase 4, para no introducir una
  /// inconsistencia entre ambas fases):
  ///  * `callAmountBb == 0`: se acepta — un call de costo cero (ej. un
  ///    check representado como "call de 0") es un escenario legítimo
  ///    del dominio, igual que ya lo es en `PotOddsEngine`. La fórmula
  ///    da `EV == equity * finalPotBb` sin ninguna rama especial.
  ///  * `finalPotBb == 0` (fuerza `callAmountBb == 0`, ver la validación
  ///    de abajo): `EV == 0` para cualquier `equity` — no hay nada que
  ///    ganar ni perder. Se acepta como caso degenerado pero válido,
  ///    igual que `PotOddsResult.requiredEquity` acepta `finalPotBb ==
  ///    0`.
  ///
  /// Lanza [ArgumentError] si:
  ///  * [equity] no está en `[0, 1]`, o no es finito;
  ///  * [finalPotBb] o [callAmountBb] son negativos o no finitos;
  ///  * `finalPotBb < callAmountBb` — matemáticamente imposible: el bote
  ///    después de pagar el call siempre incluye ese mismo call
  ///    (`finalPotBb == potBeforeCallBb + callAmountBb` con
  ///    `potBeforeCallBb >= 0`, ver `PotOddsResult`), así que nunca puede
  ///    ser menor que él. No es una regla de negocio: es la definición
  ///    de `finalPotBb`.
  static EVResult calculateCall({
    required double equity,
    required double finalPotBb,
    required double callAmountBb,
  }) {
    _validateEquity(equity);
    _validateNonNegativeFinite(finalPotBb, 'finalPotBb');
    _validateNonNegativeFinite(callAmountBb, 'callAmountBb');
    if (finalPotBb < callAmountBb) {
      throw ArgumentError(
          'EVEngine.calculateCall: finalPotBb ($finalPotBb) no puede ser '
          'menor que callAmountBb ($callAmountBb) — finalPotBb ya incluye '
          'el call, así que nunca puede ser más chico que él.');
    }
    return EVResult(
      equity: equity,
      finalPotBb: finalPotBb,
      callAmountBb: callAmountBb,
    );
  }

  /// EV de apostar o subir — a diferencia de [calculateCall], modela dos
  /// ramas ponderadas por probabilidad (fold del rival, call del
  /// rival), nunca una equity única. Ver el doc-comment de
  /// [EVBetResult] para el alcance deliberado (la rama "el rival sube"
  /// queda fuera del cálculo) y `EV_AVANZADO_AUDITORIA_DISENO.md` para
  /// la justificación completa de diseño.
  ///
  /// [foldProbability]/[callProbability]/[equityIfCalled] son datos que
  /// **el caller tiene que proveer** — este motor nunca los infiere ni
  /// les pone un valor por default. Ver el punto 4 del informe de
  /// diseño: inventar una frecuencia de fold/call sin que el usuario la
  /// haya puesto sería fabricar una estadística de póker sin sustento.
  ///
  /// Lanza [ArgumentError] si:
  ///  * [foldProbability] o [callProbability] no están en `[0, 1]`, o no
  ///    son finitos;
  ///  * `foldProbability + callProbability > 1` (más allá de una
  ///    tolerancia de punto flotante) — dos probabilidades no pueden
  ///    sumar más de 1;
  ///  * [potBeforeBetBb] o [betSizeBb] son negativos o no finitos;
  ///  * [betSizeBb] es `0` — una apuesta de tamaño cero no es una
  ///    apuesta real (eso es un check, sin ramas de fold/call que
  ///    calcular);
  ///  * [equityIfCalled] no está en `[0, 1]`, o no es finito.
  static EVBetResult calculateBet({
    required double foldProbability,
    required double callProbability,
    required double potBeforeBetBb,
    required double betSizeBb,
    required double equityIfCalled,
  }) {
    _validateProbability(foldProbability, 'foldProbability');
    _validateProbability(callProbability, 'callProbability');
    if (foldProbability + callProbability > 1 + 1e-9) {
      throw ArgumentError(
          'EVEngine.calculateBet: foldProbability + callProbability no '
          'puede superar 1.0 (suman ${foldProbability + callProbability}).');
    }
    _validateNonNegativeFinite(potBeforeBetBb, 'potBeforeBetBb');
    _validateNonNegativeFinite(betSizeBb, 'betSizeBb');
    if (betSizeBb == 0) {
      throw ArgumentError.value(betSizeBb, 'betSizeBb',
          'EVEngine.calculateBet: una apuesta de 0 no es una apuesta real '
          '(eso es un check, sin ramas de fold/call).');
    }
    _validateProbability(equityIfCalled, 'equityIfCalled');
    return EVBetResult(
      foldProbability: foldProbability,
      callProbability: callProbability,
      potBeforeBetBb: potBeforeBetBb,
      betSizeBb: betSizeBb,
      equityIfCalled: equityIfCalled,
    );
  }

  static void _validateProbability(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(
          value, name, 'EVEngine: $name debe ser un número finito.');
    }
    if (value < 0 || value > 1) {
      throw ArgumentError.value(
          value, name, 'EVEngine: $name debe estar entre 0.0 y 1.0.');
    }
  }

  static void _validateEquity(double equity) {
    if (!equity.isFinite) {
      throw ArgumentError.value(
          equity, 'equity', 'EVEngine: equity debe ser un número finito.');
    }
    if (equity < 0 || equity > 1) {
      throw ArgumentError.value(
          equity, 'equity', 'EVEngine: equity debe estar entre 0.0 y 1.0.');
    }
  }

  static void _validateNonNegativeFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(
          value, name, 'EVEngine: $name debe ser un número finito.');
    }
    if (value < 0) {
      throw ArgumentError.value(
          value, name, 'EVEngine: $name no puede ser negativo.');
    }
  }
}

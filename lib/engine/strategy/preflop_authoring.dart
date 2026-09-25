import 'strategy.dart';

/// Vista agrupada de [StrategicRating], usada únicamente por la fórmula
/// del veredicto pedagógico (`preflopVerdict`, en
/// `exercises/preflop_verdict.dart`) — nunca reemplaza a [StrategicRating]
/// como escala de calidad: el feedback sigue pudiendo usar los 5 niveles
/// originales (emoji/label), esto solo los agrupa en 3 bandas para decidir
/// BEST/ACCEPTABLE/DEPENDS/ERROR.
///
/// Ver "FLOPly — Fase 0.5" (informe de diseño, sección C) para la
/// justificación completa de por qué la calidad NUNCA se deriva de la
/// frecuencia (eso es [MixShare]) — al revés de lo que hacía el motor
/// preflop viejo (`_facingRaiseStrategy`/`_openOverLimpersStrategy`, que
/// sí calculaba `rating` a partir de un umbral de frecuencia).
enum QualityTier { top, mid, low }

extension StrategicRatingTier on StrategicRating {
  /// Agrupa los 5 niveles de [StrategicRating] en las 3 bandas que usa
  /// la fórmula del veredicto.
  QualityTier get tier => switch (this) {
        StrategicRating.optimal || StrategicRating.veryGood => QualityTier.top,
        StrategicRating.viable => QualityTier.mid,
        StrategicRating.dubious || StrategicRating.bad => QualityTier.low,
      };
}

/// Qué tan presente está una acción en una estrategia mixta real — un
/// dato del RANGO, nunca de la calidad de una mano concreta.
///
/// Deliberadamente no son floats: usar `0.35`/`0.65` sugeriría una
/// precisión de solver que estas tablas no tienen (son consenso teórico
/// simplificado o heurística documentada, nunca un solve real). Las
/// bandas alcanzan para lo que este dato hace — alimentar el texto "esto
/// es una situación mixta" y la guarda de coherencia de autoría
/// ([isCoherentCell]) — nunca la fórmula del veredicto, que depende solo
/// de [QualityTier] y [ContextSensitivity].
enum MixShare {
  /// Única acción real para esta clase de mano en este spot (~100%).
  pure,

  /// Parte mayoritaria de un mix real (banda representativa 65-85%).
  primary,

  /// Parte minoritaria de un mix real (banda representativa 15-35%).
  secondary,

  /// Aparece en algún solver real con frecuencia marginal, pero FLOPly
  /// no la enseña como línea recomendada.
  negligible;

  /// Punto medio representativo de la banda, solo para texto informativo
  /// ("esto pasa ~X% de las veces") — nunca para decidir un veredicto.
  double get representativeFrequency => switch (this) {
        MixShare.pure => 1.0,
        MixShare.primary => 0.75,
        MixShare.secondary => 0.25,
        MixShare.negligible => 0.05,
      };

  /// Categoriza una [frequency] cruda (0..1, la que ya trae
  /// `StrategyOption.frequency`) en su banda de [MixShare] — el puente
  /// entre el dato continuo que ya calcula cada generador de estrategia
  /// y la vista categórica que usa [isCoherentCell]. Nunca al revés: la
  /// banda es una lectura de la frecuencia, la frecuencia nunca se
  /// reconstruye a partir de la banda.
  static MixShare fromFrequency(double frequency) {
    if (frequency >= 0.85) return MixShare.pure;
    if (frequency >= 0.5) return MixShare.primary;
    if (frequency >= 0.15) return MixShare.secondary;
    return MixShare.negligible;
  }
}

/// Variables del spot que pueden justificar `DEPENDS` (ver
/// `preflopVerdict`). Que un factor exista acá no alcanza para justificar
/// `DEPENDS` por sí solo: además tiene que no estar expuesto al alumno en
/// la presentación del ejercicio ([ContextSensitivity.disclosedToStudent]).
/// Posición, stack y sizing siempre están visibles en la mesa — en la
/// práctica casi nunca deberían ser el factor que dispara `DEPENDS`; se
/// listan igual porque son variables reales de la teoría, no porque se
/// espere usarlas seguido para ese fin.
enum ContextFactor {
  position,
  villainRange,
  opponentProfile,
  stackDepth,
  openSize,
  sizing,
  playersBehind,
}

/// Reemplaza el booleano `contextSensitive: true/false` de la primera
/// propuesta de diseño: un booleano solo no alcanza para evitar que
/// `DEPENDS` se convierta en una forma de decir "no sabemos" (informe de
/// Fase 0.5, sección D). Exige nombrar el/los factores concretos y
/// declarar si el alumno puede verlos en el ejercicio.
class ContextSensitivity {
  const ContextSensitivity.stable()
      : factors = const [],
        disclosedToStudent = true;

  /// [factors] no puede estar vacío — `DEPENDS` siempre necesita un
  /// motivo nombrado, nunca es una categoría "por si acaso".
  ContextSensitivity.dependent(
    this.factors, {
    this.disclosedToStudent = false,
  }) : assert(factors.isNotEmpty,
            'ContextSensitivity.dependent necesita al menos un ContextFactor '
            '— DEPENDS siempre tiene que poder señalar de qué depende.');

  final List<ContextFactor> factors;

  /// `true` si el valor concreto de estos factores para ESTE ejercicio ya
  /// es visible para el alumno (posición/stack/sizing siempre lo son). Si
  /// es `true`, el factor deja de justificar `DEPENDS`: la decisión ya se
  /// puede resolver con la información que el alumno tiene.
  final bool disclosedToStudent;

  bool get isDependent => factors.isNotEmpty;
}

/// Por qué una acción concreta pertenece a una tabla de rango — nunca se
/// infiere de la fuerza absoluta de la mano ni del `ActionType` solo (ver
/// secciones 8-9 del informe de Fase 0.5, y la auditoría de Fase 1 sobre
/// por qué "mano fuerte ⇒ 3-bet por valor" es un error conceptual).
enum StrategyRole {
  /// Re-subir con manos fuertes que ganan valor de manos peores que
  /// siguen pagando — requiere que esas manos peores existan de verdad.
  value,

  /// Re-subir como farol: bloqueadores + jugabilidad + fold equity, nunca
  /// solo "tiene un As".
  bluff,

  /// Pagar para continuar en la mano — el "call" con intención de
  /// defensa, no de farol ni de valor puro.
  defend,

  fold,

  /// Igual que [value] pero un nivel más arriba: value contra un rango de
  /// 3-bet del rival, no contra su rango de apertura.
  fourBetValue,

  /// Igual que [bluff] pero re-subiendo sobre un 3-bet ajeno.
  fourBetBluff,

  /// Todo-in con manos fuertes a stack corto — la contraparte de [value]
  /// cuando la única subida legal ya es un jam.
  jamValue,

  /// Todo-in como farol a stack corto — la contraparte de [bluff] en el
  /// mismo contexto.
  jamBluff,
}

/// Guarda de coherencia de autoría (informe de Fase 0.5, sección C): una
/// celda de tabla no puede declarar una acción como la línea óptima
/// (`QualityTier.top`) y al mismo tiempo decir que casi nunca se juega
/// (`MixShare.negligible`) — esas dos afirmaciones se contradicen. Existe
/// para que un test de tabla pueda detectar el error de autoría exacto
/// que producía el motor viejo (`rating` calculado a partir de un umbral
/// de `frequency`) si alguien lo repitiera sin querer.
bool isCoherentCell({
  required StrategicRating quality,
  required MixShare mixShare,
}) {
  if (mixShare == MixShare.negligible && quality.tier == QualityTier.top) {
    return false;
  }
  return true;
}

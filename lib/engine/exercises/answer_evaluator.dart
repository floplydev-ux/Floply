import '../poker/poker_action.dart';
import '../strategy/strategy.dart';
import 'exercise_scenario.dart';
import 'preflop_verdict.dart';
import 'scenario_strategy.dart';

/// El veredicto pedagógico de una respuesta — nunca binario.
///
/// No es el mismo tipo que `ExerciseRating` (`pedagogy/
/// table_exercise.dart`): ese vive acoplado a los tipos de UI del
/// sistema viejo (`PlayableTableExercise`/`ActionChoice`); este motor es
/// nuevo y todavía no está cableado a ninguna UI — acoplarlo ahora sería
/// prematuro. Comparte las 3 categorías centrales (`best`/`acceptable`/
/// `poor`) más `dependent`, que sale de `Strategy.isMixed` (ya existe):
/// cuando la situación admite más de una respuesta con frecuencia
/// apreciable, no tiene sentido calificarla como un único "correcto".
enum AnswerVerdict { best, acceptable, poor, dependent }

/// El resultado de evaluar una decisión.
class AnswerResult {
  const AnswerResult({
    required this.verdict,
    required this.matchedOption,
    required this.justifyingConcepts,
    required this.chosenAction,
    required this.recommendedAction,
  });

  final AnswerVerdict verdict;

  /// La opción de la [Strategy] de referencia que corresponde a la
  /// acción elegida (para poder mostrar `feedback`/`rationaleKey` más
  /// adelante).
  final StrategyOption matchedOption;

  /// Conceptos que justifican el veredicto — ya intersecados con
  /// `ExerciseScenario.evaluableConcepts`: nunca un concepto que el
  /// escenario no declaró.
  final List<String> justifyingConcepts;

  /// La acción que el alumno eligió — el mismo parámetro que recibió
  /// [AnswerEvaluator.evaluate], guardado acá para que un consumidor
  /// (p. ej. `PreflopSessionSummary`) no necesite volver a pasarlo por
  /// separado.
  final PokerAction chosenAction;

  /// La acción primaria de la estrategia de referencia
  /// (`Strategy.primary.action`) — qué habría jugado la estrategia
  /// óptima en esta situación exacta.
  final PokerAction recommendedAction;
}

/// Evalúa la decisión del alumno contra la estrategia de referencia del
/// escenario.
///
/// No implementa GTO ni un solver, no calcula EV: delega en
/// [ScenarioStrategy] (que a su vez despacha a `PreflopStrategy` o
/// `PostflopStrategy` según la calle — reemplazable sin que este
/// evaluador cambie de forma) para la estrategia, y en [preflopVerdict]
/// ("FLOPly — Fase 0.5") para traducir la calidad de la opción elegida
/// a un veredicto. El nombre de [preflopVerdict] quedó de cuando solo
/// existía preflop — la función en sí es street-agnóstica (solo mira
/// `QualityTier`/`ContextSensitivity`), por eso `PostflopStrategy`
/// también la reutiliza sin cambios.
///
/// **Cableado de la Fase 0.5** (antes de esto, el veredicto `dependent`
/// se calculaba de la frecuencia: `strategy.isMixed && option.frequency
/// >= 0.15`, mezclando "qué tan seguido se juega" con "es una decisión
/// que depende del contexto" — dos preguntas distintas). Ahora el
/// veredicto sale directo de [StrategyOption.rating] +
/// [StrategyOption.contextSensitivity], que es lo que cada generador de
/// estrategia ya declara por opción — este evaluador no vuelve a mirar
/// `frequency` para decidir nada, solo el motor que arma la estrategia.
///
/// **Corrección de Open Raise (Campo de Entrenamiento)**: usa
/// [Strategy.optionForSized] en vez de `optionFor` a secas — una subida
/// con un tamaño razonable pero distinto al único tamaño "ideal" que una
/// familia preflop tenga codificado ya no cae a la opción de peor
/// calificación de TODA la estrategia (que podía ser un tipo de acción
/// completamente distinto, p. ej. fold): se evalúa contra la mejor
/// opción que comparta el mismo tipo de acción. Separa así validez de la
/// ACCIÓN (qué tipo conviene) de validez del TAMAÑO (qué tan cerca del
/// ideal), sin inventar ninguna regla nueva de póker.
class AnswerEvaluator {
  const AnswerEvaluator._();

  static AnswerResult evaluate(ExerciseScenario scenario, PokerAction chosenAction) {
    final strategy =
        ScenarioStrategy.forDecision(scenario.initialState, scenario.heroSlot);

    final option = strategy.optionForSized(chosenAction);

    return AnswerResult(
      verdict: preflopVerdict(
        quality: option.rating,
        contextSensitivity: option.contextSensitivity,
      ),
      matchedOption: option,
      justifyingConcepts: option.justifyingConcepts
          .where(scenario.evaluableConcepts.contains)
          .toList(),
      chosenAction: chosenAction,
      recommendedAction: strategy.primary.action,
    );
  }
}

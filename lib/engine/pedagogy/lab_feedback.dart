import '../strategy/decision_math.dart';
import '../strategy/strategy.dart' show StrategicRating;

/// Devolución pedagógica estructurada post-respuesta de un ejercicio de
/// Laboratorio — Decisión → Por qué → Números → Concepto → Repasá en
/// Academia. Vive en `pedagogy/` (junto a `ExerciseRating`/
/// `ExerciseExplainStep`, sus vecinos naturales) porque es el tipo que se
/// embebe como campo opcional en `ActionChoice`/`BetSizeOption`
/// (`playable_exercise.dart`) — armarlo es trabajo de `exercises/`
/// (`LabFeedbackBuilder`, que sí depende de `pedagogy/`, nunca al revés).
///
/// Puramente aditivo: solo [LabFeedbackBuilder] arma uno, y solo
/// `ExerciseScenarioAdapter` (el único caller de Laboratorio) lo puebla en
/// `ActionChoice.richFeedback` — Academia nunca construye uno, así que su
/// sola presencia ya alcanza para que la devolución nueva sea exclusiva de
/// Laboratorio sin bifurcar el widget compartido.
class LabFeedback {
  const LabFeedback({
    required this.expectedLabel,
    required this.strategicRating,
    required this.whyText,
    this.math,
    this.conceptTitle,
    this.conceptExplanation,
    this.academyReviewLessonId,
    this.academyReviewLabel,
  });

  /// La acción que la estrategia de referencia habría jugado acá (p. ej.
  /// `"RAISE 8bb"`) — siempre presente, sea cual sea el veredicto.
  final String expectedLabel;

  /// La calificación real de 5 niveles (Óptima/Muy buena/Viable/Dudosa/
  /// Mala) de la opción que el alumno eligió — `StrategyOption.rating`
  /// tal cual la calculó la estrategia de referencia, nunca colapsada al
  /// veredicto de 3 niveles (`ExerciseRating`/ratingBadge) que ya usa el
  /// badge ✓/✕ de arriba. Pedido explícito: mostrar la graduación real,
  /// no solo "correcto/incorrecto".
  final StrategicRating strategicRating;

  /// El "por qué" en tono de mentor, ya resuelto: texto real del banco de
  /// rationale (interpolado con los datos de esta mano cuando la clave lo
  /// usa) o, si la clave todavía no tiene texto propio, el mismo fallback
  /// genérico por veredicto que ya usaba el feedback plano.
  final String whyText;

  /// `null` cuando ni el motor de estrategia ni la aritmética directa
  /// sobre `DecisionContext` (SPR/MDF) tienen ningún número real que
  /// mostrar para esta decisión — nunca se inventa uno para rellenar.
  final DecisionMath? math;

  /// Nombre y descripción reales del primer concepto ya enseñado que
  /// justifica el veredicto — texto reutilizado tal cual de
  /// `ConceptRegistry`, nunca redactado de nuevo acá.
  final String? conceptTitle;
  final String? conceptExplanation;

  /// `null` cuando no corresponde repasar nada: la respuesta ya fue la
  /// mejor, o el concepto no tiene una lección real y verificable
  /// (`Curriculum.standard().lessonById`) que citar.
  final String? academyReviewLessonId;
  final String? academyReviewLabel;

  bool get hasReview => academyReviewLessonId != null;
}

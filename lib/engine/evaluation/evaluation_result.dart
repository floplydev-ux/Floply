import '../strategy/strategy.dart';

/// El resultado de evaluar la respuesta del usuario.
///
/// No es un simple booleano: distingue calidad de la decisión y calidad
/// del razonamiento, y trae el material para un feedback progresivo.
class EvaluationResult {
  EvaluationResult({
    required this.decisionScore,
    required this.strategicRating,
    required this.acceptable,
    required this.chosenOption,
    required this.bestOption,
    this.reasoningScore,
    this.matchedConcepts = const [],
    this.missingConcepts = const [],
    this.evaluatedConcepts = const [],
    this.feedback = '',
    this.advancedFeedback,
    this.conceptSummary,
    this.frequencyNote,
  });

  /// Qué tan buena fue la acción elegida (0..1).
  final double decisionScore;

  /// Qué tan bien entendió el usuario por qué (0..1). `null` si el
  /// ejercicio no evaluó razonamiento.
  final double? reasoningScore;

  /// Valoración estratégica de la acción elegida.
  final StrategicRating strategicRating;

  /// `true` si la acción elegida es al menos "viable".
  final bool acceptable;

  /// La opción de estrategia que corresponde a lo que eligió el usuario
  /// (`null` si eligió algo que la estrategia ni contempla).
  final StrategyOption? chosenOption;

  /// La mejor opción disponible.
  final StrategyOption bestOption;

  /// Conceptos del razonamiento que el usuario marcó y eran correctos.
  final List<String> matchedConcepts;

  /// Conceptos correctos que el usuario no marcó.
  final List<String> missingConcepts;

  /// Conceptos que este ejercicio evaluó (para actualizar mastery).
  final List<String> evaluatedConcepts;

  /// Feedback en el nivel del usuario. Nunca vacío tras pasar por el
  /// [FeedbackEngine].
  final String feedback;

  /// Feedback avanzado, solo si los conceptos correspondientes ya se
  /// enseñaron.
  final String? advancedFeedback;

  /// Frase corta con el concepto central.
  final String? conceptSummary;

  /// Nota sobre frecuencia (p. ej. "esta acción es viable pero menos
  /// frecuente que CALL").
  final String? frequencyNote;

  /// Acertó la decisión "en serio" (óptima o muy buena).
  bool get decisionIsStrong =>
      strategicRating.index <= StrategicRating.veryGood.index;

  /// Eligió bien pero probablemente no entiende del todo por qué.
  bool get luckyGuess =>
      decisionIsStrong && reasoningScore != null && reasoningScore! < 0.5;

  bool get isOptimal => strategicRating == StrategicRating.optimal;
}

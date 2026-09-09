/// Modelo de un **ejercicio interactivo sobre la mesa de póker**.
///
/// Es el equivalente a `TableLessonScript` pero orientado a una decisión
/// del usuario: situación → pregunta → opciones → respuesta → explicación
/// sobre la misma mesa. Reutiliza [TableSnapshot], [TableAnchor] y el
/// sistema de highlights de la teoría; no crea una segunda mesa.
///
/// Es contenido autoral (como `ComprehensionCheck`): la lógica de mostrar,
/// evaluar y avanzar vive en `AcademyController`, no acá.
library;

import 'table_lesson.dart';

/// Calidad de una opción. **No es binaria**: hay decisiones que en una
/// estrategia real pueden variar según el rango del rival.
enum ExerciseRating {
  /// La mejor respuesta pedagógica en esta situación.
  best,

  /// Defendible / también válida, pero no la preferida.
  acceptable,

  /// Claramente peor.
  poor,
}

/// Una opción de respuesta, con su valoración y su explicación propia.
class ExerciseChoice {
  const ExerciseChoice({
    required this.label,
    required this.rating,
    required this.feedback,
  });

  /// Texto del botón: `FOLD`, `CALL`, `3-BET`, `OPEN`, `ALL-IN`.
  final String label;

  final ExerciseRating rating;

  /// Por qué esta opción es (o no) buena. Se muestra apenas responde.
  final String feedback;
}

/// Un paso de explicación tras responder: una burbuja sobre la mesa.
class ExerciseExplainStep {
  const ExerciseExplainStep({
    required this.text,
    required this.anchor,
    this.highlight = const [],
    this.table,
    this.dimOthers = true,
  });

  final String text;
  final TableAnchor anchor;
  final List<TableAnchor> highlight;

  /// Foto de la mesa para este paso. Si es `null`, se usa
  /// [InteractiveTableExercise.afterDecision] (o la situación inicial).
  final TableSnapshot? table;

  final bool dimOthers;
}

/// Un ejercicio interactivo completo.
class InteractiveTableExercise {
  const InteractiveTableExercise({
    required this.situation,
    required this.question,
    required this.choices,
    required this.explanation,
    this.questionAnchor = TableAnchor.heroCards,
    this.situationHighlight = const [],
    this.afterDecision,
    this.concept,
    this.strategyDependent = false,
  });

  /// Mesa inicial (posiciones, cartas del héroe, acción previa, bote…).
  final TableSnapshot situation;

  /// La pregunta, en una burbuja.
  final String question;

  final TableAnchor questionAnchor;

  /// Qué se resalta mientras el usuario decide.
  final List<TableAnchor> situationHighlight;

  final List<ExerciseChoice> choices;

  /// Mesa después de aplicar la decisión (opcional: fichas al bote, etc.).
  final TableSnapshot? afterDecision;

  /// Pasos de explicación tras responder (después del feedback de la
  /// opción elegida).
  final List<ExerciseExplainStep> explanation;

  /// Concepto que refuerza. `recordAttempt` es no-op si no está enseñado,
  /// así que la regla fundamental se respeta igual.
  final String? concept;

  /// `true` si la mejor jugada depende del rango/estrategia y no hay una
  /// única respuesta absolutamente correcta. Cambia el texto del feedback
  /// ("buena elección" en vez de "correcto").
  final bool strategyDependent;

  int get bestChoiceIndex =>
      choices.indexWhere((c) => c.rating == ExerciseRating.best);
}

/// El conjunto de ejercicios interactivos de un lesson.
class InteractiveExerciseSet {
  const InteractiveExerciseSet(this.exercises);

  final List<InteractiveTableExercise> exercises;

  int get length => exercises.length;
  bool get isEmpty => exercises.isEmpty;
}

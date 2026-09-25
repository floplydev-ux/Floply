/// Modelo de un **ejercicio jugable**: el alumno decide una acción real de
/// póker (FOLD/CHECK/CALL/BET/RAISE…) directamente sobre la mesa, en vez de
/// responder una pregunta con opciones de texto.
///
/// Es una evolución de [InteractiveTableExercise] para situaciones donde
/// "sentirse jugando la mano" enseña mejor que responder un cuestionario —
/// no lo reemplaza: para preguntas de comprensión ("¿contra qué comparás tu
/// mano?", "¿cuántos combos hay?") ese formato sigue siendo el correcto.
/// Reutiliza exactamente la misma mesa ([TableSnapshot]/[TableAnchor]), la
/// misma escala de calidad de 3 niveles ([ExerciseRating]) y el mismo tipo
/// de paso de devolución ([ExerciseExplainStep]) — no inventa una segunda
/// arquitectura de ejercicios ni una segunda escala de evaluación.
library;

import '../poker/poker_action.dart' show ActionType;
import 'table_exercise.dart' show ExerciseRating, ExerciseExplainStep;
import 'table_lesson.dart';

export '../poker/poker_action.dart' show ActionType;
export 'table_exercise.dart' show ExerciseRating, ExerciseExplainStep;

/// La acción de póker de un [ActionChoice] — mismo tipo canónico que usa
/// todo el motor generado (ver `poker/poker_action.dart`), no una copia
/// paralela. La interfaz **no** tiene una lista fija de botones: solo
/// muestra las acciones que trae [PlayableTableExercise.actions] para esa
/// situación puntual. Agregar una acción nueva no requiere tocar ningún
/// widget.
typedef PokerAction = ActionType;

/// Un tamaño posible para un BET/RAISE, con su propia calidad y feedback.
/// Reutiliza [ExerciseRating]: el tamaño no tiene una escala de evaluación
/// distinta a la de cualquier otra decisión.
class BetSizeOption {
  const BetSizeOption({
    required this.label,
    required this.rating,
    required this.feedback,
    this.afterDecision,
  });

  /// `"1/2 pot"`, `"2.5 BB"`, `"Pot"`… lo que el concepto necesite enseñar.
  /// No hay una lista de tamaños fija: cada ejercicio declara los suyos.
  final String label;

  final ExerciseRating rating;

  /// Por qué este tamaño en particular es (o no) razonable acá.
  final String feedback;

  /// Mesa tras elegir este tamaño puntual (p. ej. el bote actualizado).
  /// Si es `null`, se usa el `afterDecision` de la [ActionChoice] elegida
  /// o, en su defecto, el de [PlayableTableExercise].
  final TableSnapshot? afterDecision;
}

/// Una opción de "¿por qué elegiste esta acción?" — el segundo eje de
/// evaluación, independiente de si la acción en sí fue buena. Misma escala
/// [ExerciseRating]: no se inventa una segunda taxonomía de calidad para el
/// razonamiento.
class ReasoningOption {
  const ReasoningOption({
    required this.label,
    required this.rating,
    required this.feedback,
  });

  /// La justificación tal como la vería el alumno, p. ej. "Estoy en el
  /// botón, la posición con el rango más ancho."
  final String label;

  final ExerciseRating rating;

  /// Por qué esa justificación es (o no) la razón correcta, aunque la
  /// acción elegida haya sido la mejor.
  final String feedback;
}

/// Una acción disponible en la situación: su calidad, su feedback, sus
/// tamaños posibles (si aplica) y las razones que se le pueden ofrecer al
/// alumno para justificarla.
class ActionChoice {
  const ActionChoice({
    required this.action,
    required this.label,
    required this.rating,
    required this.feedback,
    this.reasoning = const [],
    this.sizeOptions = const [],
    this.afterDecision,
  });

  final PokerAction action;

  /// Texto del botón. Normalmente el nombre de [action] en mayúsculas, pero
  /// editable para casos como "3-BET", "ALL-IN" o "ABRIR".
  final String label;

  final ExerciseRating rating;

  /// Por qué esta acción es (o no) buena en esta situación.
  final String feedback;

  /// Si no está vacía, elegir esta acción abre un paso intermedio para
  /// elegir el tamaño antes de poder confirmar (ver [needsSizing]).
  final List<BetSizeOption> sizeOptions;

  /// Las razones que se le ofrecen al alumno para justificar esta acción
  /// puntual — distintas acciones suelen admitir razones distintas. Vacía
  /// si el ejercicio no tiene paso de razonamiento (p. ej. Laboratorio):
  /// ahí se pasa directo de la decisión a la devolución.
  final List<ReasoningOption> reasoning;

  /// Mesa tras confirmar esta acción (sin tamaño elegido, o como fallback
  /// si el tamaño elegido no trae el suyo propio).
  final TableSnapshot? afterDecision;

  bool get needsSizing => sizeOptions.isNotEmpty;
}

/// Un ejercicio jugable completo: la situación, las acciones legales y la
/// devolución. Flujo: elegir acción → elegir tamaño (si aplica) → elegir
/// razonamiento → devolución completa (calidad de la acción + calidad del
/// razonamiento, por separado).
class PlayableTableExercise {
  const PlayableTableExercise({
    required this.situation,
    required this.actions,
    required this.explanation,
    this.prompt = '¿Qué hacés?',
    this.questionAnchor = TableAnchor.heroCards,
    this.situationHighlight = const [],
    this.afterDecision,
    this.concept,
    this.strategyDependent = false,
  });

  /// Mesa inicial: posiciones, cartas del héroe, acción previa, bote…
  final TableSnapshot situation;

  /// Texto de la burbuja mientras el alumno decide. Corto a propósito: la
  /// mesa ya da el contexto, esto solo dispara la decisión.
  final String prompt;

  final TableAnchor questionAnchor;
  final List<TableAnchor> situationHighlight;

  /// Las acciones legales de esta situación puntual. La mesa (el contenido,
  /// no un motor de reglas de póker) decide cuáles corresponden acá — no
  /// hace falta un simulador completo para eso.
  final List<ActionChoice> actions;

  /// Mesa tras la decisión, si ninguna [ActionChoice]/[BetSizeOption] trae
  /// la suya propia.
  final TableSnapshot? afterDecision;

  /// Pasos de explicación tras la devolución inmediata — misma mecánica
  /// que en [InteractiveTableExercise]: reutilizado, no reinventado.
  final List<ExerciseExplainStep> explanation;

  /// Concepto que refuerza. Igual que en [InteractiveTableExercise],
  /// `recordAttempt` es no-op si el alumno todavía no lo aprendió: la
  /// regla de no evaluar conceptos adelantados se respeta sola.
  final String? concept;

  /// `true` si la mejor jugada depende del rango/estrategia y no hay una
  /// única respuesta absolutamente correcta (cambia el copy del veredicto,
  /// igual que en [InteractiveTableExercise]).
  final bool strategyDependent;
}

/// El conjunto de ejercicios jugables de un lesson — mismo shape que
/// `InteractiveExerciseSet`.
class PlayableExerciseSet {
  const PlayableExerciseSet(this.exercises);

  final List<PlayableTableExercise> exercises;

  int get length => exercises.length;
  bool get isEmpty => exercises.isEmpty;
}

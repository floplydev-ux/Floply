import '../poker/poker_action.dart';
import '../strategy/strategy.dart';
import 'poker_situation.dart';

/// Tipos de ejercicio que el motor puede representar. No todos están
/// implementados todavía: la base es extensible.
enum ExerciseType {
  chooseAction('Elegí la acción'),
  chooseSizing('Elegí el tamaño'),
  handInRange('¿Está en el rango?'),
  compareRangeWidth('Comparar amplitud de rangos'),
  compareHands('Comparar manos'),
  multipleChoice('Opción múltiple'),
  orderActions('Ordenar acciones'),
  selectCombos('Seleccionar combos'),
  calculation('Cálculo'),
  fullDecision('Decisión completa');

  const ExerciseType(this.label);
  final String label;
}

/// Una opción de respuesta ofrecida al usuario.
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.label,
    this.action,
    this.sizingBb,
    this.value,
  });

  final String id;
  final String label;

  /// Acción asociada (para ejercicios de decisión / sizing).
  final PokerAction? action;

  /// Tamaño asociado (para ejercicios de sizing).
  final double? sizingBb;

  /// Valor genérico (bool para sí/no, String para comparaciones, etc.).
  final Object? value;

  @override
  String toString() => '$id:$label';
}

/// El bloque de explicación de un ejercicio, en dos niveles.
///
/// El [FeedbackEngine] elige cuál mostrar según los conceptos que el
/// usuario ya aprendió: el avanzado solo aparece si [advancedConcepts]
/// están todos enseñados.
class ExerciseExplanation {
  const ExerciseExplanation({
    required this.basic,
    this.advanced,
    this.advancedConcepts = const [],
    this.conceptSummary,
  });

  /// Explicación en términos de los conceptos del nivel actual.
  final String basic;

  /// Explicación más profunda, opcional.
  final String? advanced;

  /// Conceptos que la explicación avanzada da por sabidos.
  final List<String> advancedConcepts;

  /// Frase corta que resume el concepto central de la situación.
  final String? conceptSummary;
}

/// Un ejercicio concreto listo para presentar y evaluar.
///
/// Contiene tanto lo que ve el usuario (enunciado, opciones, situación)
/// como la "verdad" contra la que se evalúa ([strategy]).
class Exercise {
  Exercise({
    required this.id,
    required this.templateId,
    required this.type,
    required this.difficulty,
    required this.prompt,
    required this.options,
    required this.strategy,
    required this.explanation,
    required this.evaluatedConcepts,
    this.requiredConcepts = const [],
    this.optionalConcepts = const [],
    this.situation,
    this.reasoningConcepts = const [],
    this.correctValue,
    this.meta = const {},
  });

  final String id;
  final String templateId;
  final ExerciseType type;
  final int difficulty;

  final String prompt;
  final List<AnswerOption> options;

  /// La estrategia de referencia (ground truth).
  final Strategy strategy;

  final ExerciseExplanation explanation;

  /// Conceptos que este ejercicio efectivamente evalúa (ya filtrados a
  /// los que el usuario tiene enseñados).
  final List<String> evaluatedConcepts;

  /// Conceptos que el ejercicio necesita que el usuario conozca para
  /// siquiera ser presentado.
  final List<String> requiredConcepts;

  /// Conceptos que enriquecen el ejercicio pero no son obligatorios.
  final List<String> optionalConcepts;

  final PokerSituation? situation;

  /// Chips de "¿por qué?" que se le ofrecen al usuario para evaluar su
  /// razonamiento (subconjunto de conceptos enseñados).
  final List<String> reasoningConcepts;

  /// Para ejercicios que no son de acción (sí/no, comparaciones): el
  /// valor correcto esperado.
  final Object? correctValue;

  final Map<String, Object?> meta;

  /// La opción que corresponde a la acción/valor preferido, si existe
  /// entre las ofrecidas.
  AnswerOption? get preferredOption {
    final primaryAction = strategy.primary.action;
    for (final option in options) {
      if (option.action != null && option.action!.matches(primaryAction)) {
        return option;
      }
      if (correctValue != null && option.value == correctValue) {
        return option;
      }
    }
    return null;
  }
}

import '../poker/poker_action.dart';
import 'preflop_authoring.dart';

/// Qué tan buena es una acción, en una escala que NO es binaria.
///
/// En póker suele haber varias acciones estratégicamente válidas: el
/// motor tiene que poder decir "esto es defendible pero peor" en vez de
/// simplemente "incorrecto".
enum StrategicRating {
  /// Óptimo / preferido: la acción de mayor EV o mayor frecuencia.
  optimal(1.0, '🟢', 'Óptima'),

  /// Muy buena: EV prácticamente idéntico al óptimo.
  veryGood(0.88, '🟢', 'Muy buena'),

  /// Viable: estratégicamente válida pero menos frecuente.
  viable(0.68, '🟡', 'Viable'),

  /// Dudosa: defendible en algún contexto pero con problemas claros.
  dubious(0.4, '🟠', 'Dudosa'),

  /// Mala: claramente inferior.
  bad(0.12, '🔴', 'Mala');

  const StrategicRating(this.score, this.emoji, this.label);

  /// Puntaje 0..1 asociado, usado para la nota de decisión.
  final double score;
  final String emoji;
  final String label;

  bool get isAcceptable => index <= StrategicRating.viable.index;
}

/// Una opción dentro de la estrategia de una situación: la acción, con qué
/// frecuencia se juega, qué tan buena es y qué conceptos la justifican.
class StrategyOption {
  const StrategyOption({
    required this.action,
    required this.frequency,
    required this.rating,
    this.justifyingConcepts = const [],
    this.rationaleKey,
    this.role,
    this.contextSensitivity = const ContextSensitivity.stable(),
  });

  final PokerAction action;

  /// Frecuencia con la que una estrategia mixta toma esta acción (0..1).
  /// Puramente descriptiva desde "FLOPly — Fase 0.5": nunca determina
  /// [rating] (ver el doc-comment de `preflopVerdict`,
  /// `exercises/preflop_verdict.dart` — la calidad de una acción no se
  /// deriva de qué tan seguido se juega).
  final double frequency;

  final StrategicRating rating;

  /// Ids de conceptos que explican por qué esta acción es (o no) buena.
  /// El feedback solo menciona los que el usuario ya aprendió.
  final List<String> justifyingConcepts;

  /// Clave para buscar el texto de feedback correspondiente.
  final String? rationaleKey;

  /// Por qué esta acción pertenece a la estrategia — ver
  /// `strategy/preflop_authoring.dart`. `null` cuando el tipo de
  /// ejercicio no tiene una noción de "rol" (comparar manos, ordenar
  /// posiciones, etc.) — no todo `StrategyOption` representa una
  /// decisión de value/bluff/defend.
  final StrategyRole? role;

  /// Si la calidad de esta acción depende de una variable que el
  /// ejercicio no le muestra al alumno (ver
  /// `strategy/preflop_authoring.dart`) — por defecto estable (no
  /// depende de nada). Es lo que `preflopVerdict` usa, junto con
  /// [rating], para decidir `AnswerVerdict.dependent`.
  final ContextSensitivity contextSensitivity;

  bool get isPrimary => rating == StrategicRating.optimal;

  StrategyOption copyWith({
    StrategicRating? rating,
    double? frequency,
    StrategyRole? role,
    ContextSensitivity? contextSensitivity,
  }) {
    return StrategyOption(
      action: action,
      frequency: frequency ?? this.frequency,
      rating: rating ?? this.rating,
      justifyingConcepts: justifyingConcepts,
      rationaleKey: rationaleKey,
      role: role ?? this.role,
      contextSensitivity: contextSensitivity ?? this.contextSensitivity,
    );
  }

  @override
  String toString() =>
      '${action.label} ${(frequency * 100).round()}% ${rating.label}';
}

/// La estrategia completa para una situación: el conjunto de acciones
/// posibles con su valoración. Es la "verdad" contra la que se evalúa.
class Strategy {
  Strategy(this.options, {this.summaryKey}) {
    if (options.isEmpty) {
      throw ArgumentError.value(
          options, 'options', 'Una estrategia necesita al menos una opción');
    }
  }

  final List<StrategyOption> options;

  /// Clave de texto para el resumen conceptual de la situación.
  final String? summaryKey;

  /// La acción preferida (óptima, o la de mayor frecuencia si no hay
  /// ninguna marcada como óptima).
  StrategyOption get primary {
    final optimal = options.where((o) => o.rating == StrategicRating.optimal);
    if (optimal.isNotEmpty) {
      return optimal.reduce((a, b) => a.frequency >= b.frequency ? a : b);
    }
    return options.reduce((a, b) => a.frequency >= b.frequency ? a : b);
  }

  /// `true` si hay más de una acción que se juega con frecuencia
  /// apreciable: estrategia mixta.
  bool get isMixed =>
      options.where((o) => o.frequency >= 0.15).length > 1;

  /// Busca la opción que corresponde a [action] (comparando tipo y, con
  /// tolerancia, tamaño). Devuelve `null` si la acción no está contemplada.
  StrategyOption? optionFor(PokerAction action) {
    for (final option in options) {
      if (option.action.matches(action)) return option;
    }
    return null;
  }

  /// Suma de frecuencias; debería estar cerca de 1.0 para ejercicios de
  /// elección de acción.
  double get totalFrequency =>
      options.fold(0.0, (sum, o) => sum + o.frequency);
}

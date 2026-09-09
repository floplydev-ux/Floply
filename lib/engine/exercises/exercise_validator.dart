import '../poker/poker_action.dart';
import '../poker/street.dart';
import 'exercise.dart';

/// El resultado de validar un ejercicio.
class ValidationResult {
  ValidationResult(this.errors);
  ValidationResult.ok() : errors = const [];

  final List<String> errors;
  bool get isValid => errors.isEmpty;

  @override
  String toString() =>
      isValid ? 'ValidationResult.ok' : 'ValidationResult(${errors.join("; ")})';
}

/// Comprueba que un ejercicio generado sea coherente antes de mostrarlo.
///
/// Si algo falla, el generador descarta el ejercicio y reintenta.
class ExerciseValidator {
  const ExerciseValidator({required this.taughtConcepts});

  /// Conceptos que el usuario tiene enseñados: no se puede evaluar nada
  /// fuera de este conjunto.
  final Set<String> taughtConcepts;

  ValidationResult validate(Exercise exercise) {
    final errors = <String>[];

    _checkConcepts(exercise, errors);
    _checkDifficulty(exercise, errors);
    _checkOptions(exercise, errors);
    _checkStrategy(exercise, errors);
    _checkExplanation(exercise, errors);
    _checkSituation(exercise, errors);

    return ValidationResult(errors);
  }

  void _checkConcepts(Exercise exercise, List<String> errors) {
    if (exercise.evaluatedConcepts.isEmpty) {
      errors.add('El ejercicio no evalúa ningún concepto.');
    }
    for (final c in exercise.evaluatedConcepts) {
      if (!taughtConcepts.contains(c)) {
        errors.add('Evalúa el concepto no enseñado "$c".');
      }
    }
    for (final c in exercise.requiredConcepts) {
      if (!taughtConcepts.contains(c)) {
        errors.add('Requiere el concepto no enseñado "$c".');
      }
    }
    for (final c in exercise.reasoningConcepts) {
      if (!taughtConcepts.contains(c)) {
        errors.add('Ofrece razonar con el concepto no enseñado "$c".');
      }
    }
  }

  void _checkDifficulty(Exercise exercise, List<String> errors) {
    if (exercise.difficulty < 1 || exercise.difficulty > 5) {
      errors.add('Dificultad fuera de rango: ${exercise.difficulty}.');
    }
  }

  void _checkOptions(Exercise exercise, List<String> errors) {
    final needsOptions = exercise.type != ExerciseType.calculation;
    if (needsOptions && exercise.options.length < 2) {
      errors.add('Tiene menos de 2 opciones.');
    }
    final ids = exercise.options.map((o) => o.id).toSet();
    if (ids.length != exercise.options.length) {
      errors.add('Hay opciones con id repetido.');
    }
    final labels = exercise.options.map((o) => o.label).toSet();
    if (labels.length != exercise.options.length) {
      errors.add('Hay opciones con etiqueta repetida.');
    }

    // Toda opción de acción/sizing debe poder mapearse a la estrategia.
    for (final option in exercise.options) {
      if (option.action != null &&
          exercise.strategy.optionFor(option.action!) == null) {
        errors.add('La opción "${option.label}" no está contemplada en la '
            'estrategia.');
      }
    }
  }

  void _checkStrategy(Exercise exercise, List<String> errors) {
    final strategy = exercise.strategy;
    if (strategy.options.isEmpty) {
      errors.add('La estrategia no tiene opciones.');
      return;
    }

    if (exercise.type == ExerciseType.chooseAction ||
        exercise.type == ExerciseType.fullDecision) {
      final total = strategy.totalFrequency;
      if ((total - 1.0).abs() > 0.05) {
        errors.add('Las frecuencias de la estrategia suman $total (≈1 '
            'esperado).');
      }
    }

    for (final so in strategy.options) {
      if (so.frequency < 0 || so.frequency > 1) {
        errors.add('Frecuencia inválida: ${so.frequency}.');
      }
      final size = so.action.sizeBb;
      if (size != null && size <= 0) {
        errors.add('Tamaño de acción inválido: $size.');
      }
    }
  }

  void _checkExplanation(Exercise exercise, List<String> errors) {
    if (exercise.explanation.basic.trim().isEmpty) {
      errors.add('La explicación básica está vacía.');
    }
    // Una explicación avanzada sin conceptos declarados no se podría
    // "esconder" cuando el usuario no está listo: es un error de diseño.
    if (exercise.explanation.advanced != null &&
        exercise.explanation.advancedConcepts.isEmpty) {
      errors.add('Hay explicación avanzada sin conceptos declarados.');
    }
  }

  void _checkSituation(Exercise exercise, List<String> errors) {
    final s = exercise.situation;
    if (s == null) return;

    // Cartas duplicadas.
    final cards = s.knownCards;
    if (cards.toSet().length != cards.length) {
      errors.add('Hay cartas duplicadas en la situación.');
    }

    // Cantidad de cartas de board coherente con la calle.
    if (s.board.length != s.street.boardCards) {
      errors.add('El board tiene ${s.board.length} cartas para '
          '${s.street.label}.');
    }

    // Stack razonable.
    if (s.effectiveStackBb < 8 || s.effectiveStackBb > 500) {
      errors.add('Stack efectivo irreal: ${s.effectiveStackBb}bb.');
    }

    // Historial de acciones coherente para preflop first-in.
    if (s.street == Street.preflop && s.isFirstIn) {
      final expectedFolds = s.heroPosition.playersBefore;
      if (s.actionHistory.length != expectedFolds) {
        errors.add('Historial: ${s.actionHistory.length} folds para '
            '${s.heroPosition.abbreviation} (se esperaban $expectedFolds).');
      }
      for (final prior in s.actionHistory) {
        if (prior.action.type != ActionType.fold) {
          errors.add('En una situación first-in solo puede haber folds '
              'previos.');
        }
      }
      // Las posiciones que foldearon deben ser exactamente las anteriores.
      final foldedPositions = s.actionHistory.map((a) => a.position).toSet();
      final expectedPositions = s.heroPosition.earlierPositions.toSet();
      if (foldedPositions.length == expectedPositions.length &&
          !foldedPositions.containsAll(expectedPositions)) {
        errors.add('Las posiciones que foldearon no coinciden con las '
            'anteriores al héroe.');
      }
    }

    // Sizings ofrecidos válidos.
    for (final size in s.availableRaiseSizes) {
      if (size <= 0 || size > s.effectiveStackBb) {
        errors.add('Sizing ofrecido inválido: ${size}bb.');
      }
    }
  }
}

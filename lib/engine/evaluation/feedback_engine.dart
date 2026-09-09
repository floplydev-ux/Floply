import '../concepts/concept_ids.dart';
import '../concepts/concept_registry.dart';
import '../concepts/user_knowledge.dart';
import '../exercises/exercise.dart';
import '../strategy/strategy.dart';
import 'evaluation_result.dart';

/// Construye el feedback textual a partir de un [EvaluationResult] crudo.
///
/// Reglas:
///  * nunca dice solo "Correcto" / "Incorrecto": siempre explica;
///  * el feedback básico solo usa conceptos ya enseñados;
///  * el feedback avanzado aparece solo si TODOS sus conceptos ya se
///    enseñaron.
class FeedbackEngine {
  FeedbackEngine(this._registry);

  final ConceptRegistry _registry;

  /// Devuelve una copia del [result] con los textos de feedback llenos.
  EvaluationResult decorate(
    EvaluationResult result,
    Exercise exercise, {
    required UserKnowledge knowledge,
  }) {
    final chosen = result.chosenOption;
    final best = result.bestOption;

    final headline = _isFactual(exercise.type)
        ? _factualHeadline(result)
        : _headline(result);
    final rationale = _rationaleText(
      chosen?.rationaleKey ?? best.rationaleKey,
      knowledge,
    );

    final buffer = StringBuffer(headline);
    if (rationale != null) {
      buffer.write(' ');
      buffer.write(rationale);
    }

    // En ejercicios de hecho (ranking, orden, ¿está en rango?) la
    // explicación concreta de la situación es lo más útil: se agrega
    // siempre que exista y solo use conceptos del nivel del usuario.
    if (_isFactual(exercise.type) &&
        exercise.explanation.basic.trim().isNotEmpty) {
      buffer.write(' ');
      buffer.write(exercise.explanation.basic.trim());
    }

    // Si eligió algo no óptimo, aclarar cuál era la línea preferida.
    if (!result.isOptimal && chosen?.action != best.action) {
      buffer.write(' ');
      buffer.write(_preferredLine(exercise, best));
    }

    final frequencyNote = _frequencyNote(exercise.strategy, chosen);
    if (frequencyNote != null) {
      buffer.write(' ');
      buffer.write(frequencyNote);
    }

    if (result.luckyGuess) {
      buffer.write(
          ' Ojo: la acción es buena, pero por lo que marcaste parece que '
          'todavía no tenés claro el porqué.');
    } else if (result.missingConcepts.isNotEmpty) {
      final names = result.missingConcepts
          .map((id) => _registry.tryById(id)?.name ?? id)
          .join(', ');
      buffer.write(' También entra en juego: $names.');
    }

    final advanced = _advancedText(exercise.explanation, knowledge);

    return EvaluationResult(
      decisionScore: result.decisionScore,
      reasoningScore: result.reasoningScore,
      strategicRating: result.strategicRating,
      acceptable: result.acceptable,
      chosenOption: result.chosenOption,
      bestOption: result.bestOption,
      matchedConcepts: result.matchedConcepts,
      missingConcepts: result.missingConcepts,
      evaluatedConcepts: result.evaluatedConcepts,
      feedback: buffer.toString(),
      advancedFeedback: advanced,
      conceptSummary: exercise.explanation.conceptSummary,
      frequencyNote: frequencyNote,
    );
  }

  bool _isFactual(ExerciseType type) =>
      type == ExerciseType.handInRange ||
      type == ExerciseType.compareRangeWidth ||
      type == ExerciseType.compareHands ||
      type == ExerciseType.multipleChoice;

  String _factualHeadline(EvaluationResult r) =>
      r.decisionScore >= 0.99 ? '✅ Correcto.' : '❌ No es así.';

  String _headline(EvaluationResult r) {
    switch (r.strategicRating) {
      case StrategicRating.optimal:
        return '${r.strategicRating.emoji} Acción óptima.';
      case StrategicRating.veryGood:
        return '${r.strategicRating.emoji} Muy buena decisión.';
      case StrategicRating.viable:
        return '${r.strategicRating.emoji} Es una jugada viable.';
      case StrategicRating.dubious:
        return '${r.strategicRating.emoji} Es defendible, pero problemática.';
      case StrategicRating.bad:
        return '${r.strategicRating.emoji} No es una buena jugada acá.';
    }
  }

  String _preferredLine(Exercise exercise, StrategyOption best) {
    return 'La línea preferida es ${best.action.label}.';
  }

  String? _frequencyNote(Strategy strategy, StrategyOption? chosen) {
    if (chosen == null || !strategy.isMixed) return null;
    final pct = (chosen.frequency * 100).round();
    if (pct <= 0) return null;
    if (chosen.rating == StrategicRating.optimal) {
      return 'Es una situación de estrategia mixta: esta acción es la más '
          'frecuente (~$pct%).';
    }
    return 'Es una situación de estrategia mixta: esta acción es válida '
        'aunque menos frecuente (~$pct%).';
  }

  String? _rationaleText(String? key, UserKnowledge knowledge) {
    final entry = _rationales[key];
    if (entry == null) return null;
    return entry.basic;
  }

  String? _advancedText(
    ExerciseExplanation explanation,
    UserKnowledge knowledge,
  ) {
    if (explanation.advanced == null) return null;
    final ok = explanation.advancedConcepts.every(knowledge.isTaught);
    return ok ? explanation.advanced : null;
  }

  static final Map<String, _Rationale> _rationales = {
    'open.raise.in_range': const _Rationale(
      basic:
          'La mano está dentro del rango con el que conviene abrir desde esta '
          'posición.',
    ),
    'open.fold.too_strong': const _Rationale(
      basic:
          'Foldear tira una mano que claramente vale para abrir: estás '
          'regalando valor.',
    ),
    'open.raise.frontier': const _Rationale(
      basic:
          'Es una mano de borde: abrir está bien, aunque no siempre sea la '
          'jugada.',
    ),
    'open.fold.frontier': const _Rationale(
      basic:
          'Es una mano de borde: foldear también es defendible desde esta '
          'posición.',
    ),
    'open.fold.out_of_range': const _Rationale(
      basic:
          'La mano queda fuera del rango de apertura de esta posición: foldear '
          'es lo correcto.',
    ),
    'open.raise.borderline_out': const _Rationale(
      basic:
          'La mano está justo por fuera del rango: abrir acá es forzar un poco '
          'la situación.',
    ),
    'open.raise.out_of_range': const _Rationale(
      basic:
          'La mano es demasiado débil para abrir desde esta posición: vas a '
          'jugar botes sin iniciativa clara y fuera de rango.',
    ),
    'sizing.ideal': const _Rationale(
      basic: 'Es el tamaño estándar de apertura para esta posición.',
    ),
    'sizing.too_small': const _Rationale(
      basic:
          'Un tamaño tan chico (o limpear) le da un precio demasiado bueno a '
          'las ciegas para entrar.',
    ),
    'sizing.too_big': const _Rationale(
      basic:
          'Un tamaño tan grande infla el bote sin necesidad y hace que tu '
          'apertura sea muy fácil de leer.',
    ),
    'sizing.slightly_big': const _Rationale(
      basic: 'Está un poco por encima de lo estándar, pero es defendible.',
    ),
    'sizing.slightly_small': const _Rationale(
      basic: 'Está un poco por debajo de lo estándar, pero es defendible.',
    ),
    'range.wider.later': const _Rationale(
      basic:
          'Cuanto más tarde actuás, menos jugadores quedan por hablar y más '
          'manos podés abrir.',
    ),
    'hand.compare.stronger': const _Rationale(
      basic:
          'Entre las dos, esta mano tiene más valor para abrir por sus cartas '
          'altas y su potencial.',
    ),
    'hand.ranking.stronger': const _Rationale(
      basic: 'Lo que decide es la jerarquía de manos, no las cartas concretas.',
    ),
    'position.order': const _Rationale(
      basic:
          'El orden de acción preflop es fijo: UTG habla primero y la BB '
          'última.',
    ),
  };

  /// Conceptos que, si el usuario ya los tiene, permiten mostrar un
  /// matiz extra en algunos feedbacks. (Reservado para crecer.)
  static const List<String> advancedPositionConcepts = [
    ConceptIds.equityRealization,
    ConceptIds.ev,
  ];
}

class _Rationale {
  const _Rationale({required this.basic});
  final String basic;
}

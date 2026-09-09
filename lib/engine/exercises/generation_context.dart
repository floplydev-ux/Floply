import '../concepts/concept_registry.dart';
import '../poker/deck.dart';
import '../strategy/strategy_engine.dart';

/// Todo lo que un [ExerciseTemplate] necesita para generar un ejercicio
/// concreto: fuente de azar controlada, motor estratégico, conceptos
/// disponibles y parámetros del objetivo.
class GenerationContext {
  GenerationContext({
    required this.deck,
    required this.strategyEngine,
    required this.concepts,
    required this.taughtConcepts,
    required this.difficulty,
    required this.targetConcept,
  });

  /// Baraja sembrada: toda carta/elección aleatoria sale de acá.
  final Deck deck;

  final StrategyEngine strategyEngine;
  final ConceptRegistry concepts;

  /// Conceptos que el usuario tiene enseñados (para no evaluar de más).
  final Set<String> taughtConcepts;

  final int difficulty;
  final String targetConcept;

  bool isTaught(String conceptId) => taughtConcepts.contains(conceptId);

  /// Filtra una lista de conceptos a los enseñados.
  List<String> keepTaught(Iterable<String> ids) =>
      ids.where(taughtConcepts.contains).toList();
}

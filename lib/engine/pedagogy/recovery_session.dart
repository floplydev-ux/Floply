import '../concepts/concept_registry.dart';
import '../concepts/user_knowledge.dart';

/// Una sesión de práctica corta y enfocada en un concepto débil, en lugar
/// de obligar a repetir un nivel entero.
class RecoverySession {
  RecoverySession({
    required this.conceptId,
    required this.title,
    required this.exerciseCount,
    required this.difficulty,
  });

  final String conceptId;
  final String title;
  final int exerciseCount;
  final int difficulty;

  /// Arma una sesión de recuperación para el concepto más débil del
  /// usuario, o `null` si no hay ninguno lo bastante flojo.
  static RecoverySession? forWeakestConcept(
    UserKnowledge knowledge,
    ConceptRegistry registry, {
    double threshold = 0.65,
  }) {
    final weak = knowledge.weakConcepts(threshold: threshold);
    if (weak.isEmpty) return null;

    final target = weak.first;
    final concept = registry.tryById(target.conceptId);
    final name = concept?.name ?? target.conceptId;

    return RecoverySession(
      conceptId: target.conceptId,
      title: 'Práctica de recuperación: $name',
      exerciseCount: target.mastery < 0.4 ? 6 : 4,
      difficulty: 2,
    );
  }
}

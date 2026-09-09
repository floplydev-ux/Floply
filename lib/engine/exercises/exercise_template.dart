import '../poker/street.dart';
import 'exercise.dart';
import 'generation_context.dart';

/// Una plantilla de ejercicio: NO es una pregunta fija, sino una familia
/// de situaciones con el mismo objetivo pedagógico.
///
/// A partir de sus variables (mano, posición, stack, sizing, ...) genera
/// ejercicios concretos distintos que evalúan lo mismo.
abstract class ExerciseTemplate {
  const ExerciseTemplate();

  /// Id estable de la plantilla.
  String get id;

  ExerciseType get type;
  Street get street;

  /// Conceptos que la plantilla evalúa.
  Set<String> get evaluatedConcepts;

  /// Conceptos que el usuario DEBE tener enseñados para que la plantilla
  /// sea elegible.
  Set<String> get requiredConcepts;

  /// Conceptos que enriquecen el ejercicio si están disponibles.
  Set<String> get optionalConcepts => const {};

  /// Dificultades que la plantilla sabe generar.
  List<int> get supportedDifficulties;

  /// Peso relativo al elegir plantilla (más alto = más frecuente).
  double get weight => 1.0;

  /// ¿Se puede usar esta plantilla dado lo que el usuario sabe y la
  /// dificultad pedida?
  bool isEligible({
    required Set<String> taughtConcepts,
    required int difficulty,
    required String targetConcept,
  }) {
    if (!supportedDifficulties.contains(difficulty)) return false;
    if (!evaluatedConcepts.contains(targetConcept)) return false;
    if (!requiredConcepts.every(taughtConcepts.contains)) return false;
    // No evaluar conceptos que el usuario todavía no aprendió.
    if (!evaluatedConcepts.every(taughtConcepts.contains)) return false;
    return true;
  }

  /// Genera un ejercicio concreto. Puede lanzar [TemplateGenerationException]
  /// si con las variables sorteadas no se puede armar una situación
  /// coherente (el generador reintentará).
  Exercise generate(GenerationContext ctx);
}

/// Señala que una generación puntual falló y hay que reintentar con otras
/// variables (no es un error del sistema).
class TemplateGenerationException implements Exception {
  TemplateGenerationException(this.message);
  final String message;
  @override
  String toString() => 'TemplateGenerationException: $message';
}

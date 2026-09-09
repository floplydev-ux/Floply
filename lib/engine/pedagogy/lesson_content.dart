/// Modelo de contenido pedagógico de un sub-nivel de la Academia.
///
/// Separa el *texto que enseña* del código de la UI: ningún widget de la
/// Academia hardcodea explicaciones. El contenido es corto y progresivo
/// (concepto → explicación → ejemplo → mini pregunta → conclusión) y se
/// puede ampliar/traducir sin tocar las pantallas.
library;

/// Tipo de bloque de teoría, para que la UI sepa cómo pintarlo.
enum TheoryBlockKind {
  /// Enuncia el concepto en una frase.
  concept,

  /// Explicación en lenguaje simple.
  explanation,

  /// Ejemplo concreto de una situación de póker.
  example,

  /// Idea para recordar / conclusión.
  keyPoint,
}

/// Un bloque de teoría dentro de un lesson.
class TheoryBlock {
  const TheoryBlock({
    required this.kind,
    required this.body,
    this.title,
  });

  const TheoryBlock.concept(this.body, {this.title})
      : kind = TheoryBlockKind.concept;
  const TheoryBlock.explanation(this.body, {this.title})
      : kind = TheoryBlockKind.explanation;
  const TheoryBlock.example(this.body, {this.title})
      : kind = TheoryBlockKind.example;
  const TheoryBlock.keyPoint(this.body, {this.title})
      : kind = TheoryBlockKind.keyPoint;

  final TheoryBlockKind kind;
  final String body;
  final String? title;
}

/// Una pregunta de comprensión autoral (no generada por el motor).
///
/// Se usa para:
///  * la "mini pregunta" al final de la teoría (formativa, no bloquea);
///  * los ejercicios de los lessons cuyo concepto todavía no tiene
///    cobertura en el generador (por ahora, solo Nivel 1 · reglas).
///
/// Nunca evalúa un concepto que la teoría del propio nivel (o de uno
/// anterior) no haya introducido: ese chequeo lo hace [AcademyEngine].
class ComprehensionCheck {
  const ComprehensionCheck({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.concept,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// Por qué esa es la respuesta (se muestra siempre, acierte o no).
  final String explanation;

  /// Concepto que refuerza. Si viene y el lesson es de evaluación, el
  /// acierto/fallo se registra en el mastery de ese concepto.
  final String? concept;

  String get correctOption => options[correctIndex];
}

/// Cómo un lesson obtiene sus ejercicios del [PokerTrainerEngine].
class PracticeSpec {
  const PracticeSpec({
    required this.targetConcept,
    required this.difficulty,
    this.exerciseCount = 4,
  });

  /// Concepto que se le pide al generador (`engine.nextExercise(concept:)`).
  final String targetConcept;
  final int difficulty;
  final int exerciseCount;
}

/// El contenido completo de un sub-nivel.
class LessonContent {
  const LessonContent({
    required this.objective,
    this.theory = const [],
    this.checks = const [],
    this.practice,
    this.intro,
  });

  /// Objetivo pedagógico, en una frase ("Reconocer la jerarquía de manos").
  final String objective;

  /// Bloques de teoría (vacío en lessons que no son de teoría).
  final List<TheoryBlock> theory;

  /// Preguntas autorales. En lessons de práctica de Nivel 1 son los
  /// ejercicios; en lessons de teoría es la mini pregunta final.
  final List<ComprehensionCheck> checks;

  /// Fuente de ejercicios del motor. `null` si el lesson se practica solo
  /// con [checks].
  final PracticeSpec? practice;

  /// Línea corta antes de los ejercicios.
  final String? intro;

  bool get hasTheory => theory.isNotEmpty;
  bool get usesEngine => practice != null;
}

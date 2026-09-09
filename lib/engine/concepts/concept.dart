/// Familia temática a la que pertenece un concepto. Sirve para agrupar
/// en la UI y para que el generador elija objetivos variados.
enum ConceptCategory {
  rules('Reglas'),
  handRanking('Ranking de manos'),
  position('Posición'),
  preflop('Preflop'),
  ranges('Rangos'),
  math('Matemáticas'),
  postflop('Postflop'),
  boardTexture('Textura de board'),
  betting('Apuestas'),
  advanced('Estrategia avanzada'),
  gto('GTO y explotación');

  const ConceptCategory(this.label);
  final String label;
}

/// Un concepto que la academia enseña y evalúa, independiente de los
/// niveles concretos donde aparece.
///
/// El motor lo usa para dos cosas:
///  * saber qué puede exigirle al usuario (solo conceptos ya enseñados);
///  * construir el grafo de prerrequisitos.
class Concept {
  const Concept({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.introducedAtLevel,
    this.prerequisites = const [],
    this.difficulty = 1,
  });

  /// Identificador estable (kebab/snake), p. ej. `open_raise`.
  final String id;

  final String name;
  final String description;
  final ConceptCategory category;

  /// Nivel de la academia donde se introduce (`'2.2'`). Es informativo:
  /// la fuente de verdad de "qué sabe el usuario" es su estado de mastery.
  final String introducedAtLevel;

  /// Ids de conceptos que deberían dominarse antes que este.
  final List<String> prerequisites;

  /// Dificultad intrínseca del concepto (1..5).
  final int difficulty;

  @override
  String toString() => 'Concept($id)';
}

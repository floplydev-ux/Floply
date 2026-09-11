/// Modelo del **piloto visual**: una teoría explicada como una secuencia de
/// situaciones sobre la mesa, cada una con una burbuja corta que señala qué
/// mirar.
///
/// Es contenido declarativo, igual que [TableLessonScript] o
/// `TheoryContent`: no tiene lógica de póker ni de UI. El renderer
/// (`VisualTheoryStageView`) es el único que sabe dibujar mesas, burbujas y
/// resaltados; acá solo viven los datos.
///
/// **No duplica la teoría escrita.** Una lección visual responde
/// "¿qué está pasando?" con pocas frases muy cortas; la teoría escrita
/// (`TheoryContent`, vía `WrittenTheoryView`) sigue siendo la que responde
/// "¿por qué, y qué tenés que aprender?" — y se muestra siempre después.
library;

import 'table_lesson.dart';

/// Un paso de una lección visual: una foto de la mesa + una burbuja que
/// narra la situación + (opcional) una línea de explicación breve debajo.
class VisualTheoryStep {
  const VisualTheoryStep({
    required this.table,
    required this.bubble,
    required this.anchor,
    this.highlight = const [],
    this.cardGlow = const {},
    this.caption,
    this.buttonLabel,
  });

  /// Mesa en este instante (sin `withCast`: lo resuelve el controller, igual
  /// que con [TableLessonScript]).
  final TableSnapshot table;

  /// Texto corto de la burbuja (una frase; "esto es lo que está pasando").
  final String bubble;

  /// Zona que ancla la burbuja y que se resalta por defecto.
  final TableAnchor anchor;

  /// Zonas adicionales a resaltar. Si está vacío, se resalta solo [anchor].
  final List<TableAnchor> highlight;

  /// Cartas puntuales a resaltar (más fino que [highlight]): por ejemplo,
  /// "esta carta del board es uno de tus outs".
  final Set<CardRef> cardGlow;

  /// Línea breve debajo de la mesa (1 oración). `null` si la burbuja ya
  /// alcanza. Nunca es un sustituto de la teoría escrita.
  final String? caption;

  /// Texto del botón de avance. `null` = usa el default ("CONTINUAR" / el
  /// de cierre en el último paso).
  final String? buttonLabel;

  List<TableAnchor> get effectiveHighlight =>
      highlight.isNotEmpty ? highlight : [anchor];
}

/// La lección visual completa de una teoría puntual.
class VisualTheoryLesson {
  const VisualTheoryLesson(this.theoryId, this.steps);

  /// Id de la teoría que ilustra (`"T093"`).
  final String theoryId;

  final List<VisualTheoryStep> steps;

  int get length => steps.length;
  bool get isEmpty => steps.isEmpty;
}

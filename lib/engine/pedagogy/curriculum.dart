import '../concepts/concept_ids.dart';

/// El tipo de sub-nivel dentro de un nivel principal (patrón Duolingo:
/// teoría → básico → intermedio → challenge → evaluación).
enum LessonKind {
  theory('Teoría', 1),
  basic('Ejercicios básicos', 1),
  intermediate('Ejercicios intermedios', 3),
  challenge('Challenge', 4),
  assessment('Evaluación', 3);

  const LessonKind(this.label, this.baseDifficulty);
  final String label;
  final int baseDifficulty;
}

/// Un sub-nivel concreto: `2.3 — Tamaño de apertura (intermedio)`.
class Lesson {
  const Lesson({
    required this.mainLevel,
    required this.subLevel,
    required this.kind,
    required this.title,
    this.conceptsIntroduced = const [],
    this.conceptsPracticed = const [],
    this.difficultyRange = const [1, 3],
  });

  final int mainLevel;
  final int subLevel;
  final LessonKind kind;
  final String title;

  /// Conceptos que este sub-nivel enseña por primera vez.
  final List<String> conceptsIntroduced;

  /// Conceptos que este sub-nivel repasa (ya introducidos antes).
  final List<String> conceptsPracticed;

  final List<int> difficultyRange;

  String get id => '$mainLevel.$subLevel';
}

/// Un nivel principal de la academia (1..40).
class MainLevel {
  const MainLevel({
    required this.number,
    required this.title,
    required this.theme,
    required this.lessons,
  });

  final int number;
  final String title;
  final String theme;
  final List<Lesson> lessons;
}

/// El plan de estudios completo. Hoy trae detallados los **niveles 1 a 5**
/// de la Academia (fundamentos → ranking → posición → rangos → open raise);
/// la estructura está lista para crecer hacia los 40 sin tocar el motor.
class Curriculum {
  Curriculum(this.levels);

  final List<MainLevel> levels;

  List<Lesson> get allLessons =>
      levels.expand((l) => l.lessons).toList(growable: false);

  Lesson? lessonById(String id) {
    for (final lesson in allLessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  /// Conceptos que ya se introdujeron hasta [lessonId] inclusive,
  /// recorriendo el plan en orden.
  Set<String> conceptsTaughtUpTo(String lessonId) {
    final taught = <String>{};
    for (final lesson in allLessons) {
      taught.addAll(lesson.conceptsIntroduced);
      if (lesson.id == lessonId) break;
    }
    return taught;
  }

  factory Curriculum.standard() => Curriculum(_levels);

  /// Ids de todos los sub-niveles de la Academia, en orden pedagógico.
  static List<String> get lessonOrder =>
      _levels.expand((l) => l.lessons).map((l) => l.id).toList();

  static const List<MainLevel> _levels = [
    // ---------------------------------------------------------------
    MainLevel(
      number: 1,
      title: 'Fundamentos',
      theme: 'Cómo funciona una mano de Texas Hold\'em',
      lessons: [
        Lesson(
          mainLevel: 1,
          subLevel: 1,
          kind: LessonKind.theory,
          title: 'Cómo se juega una mano',
          conceptsIntroduced: [ConceptIds.rules],
        ),
        Lesson(
          mainLevel: 1,
          subLevel: 2,
          kind: LessonKind.basic,
          title: 'Stack, ciegas y bote',
          conceptsPracticed: [ConceptIds.rules],
          difficultyRange: [1, 1],
        ),
        Lesson(
          mainLevel: 1,
          subLevel: 3,
          kind: LessonKind.intermediate,
          title: 'Las calles y las acciones',
          conceptsPracticed: [ConceptIds.rules],
          difficultyRange: [1, 2],
        ),
        Lesson(
          mainLevel: 1,
          subLevel: 4,
          kind: LessonKind.challenge,
          title: 'Una mano completa hasta el showdown',
          conceptsPracticed: [ConceptIds.rules],
          difficultyRange: [2, 2],
        ),
        Lesson(
          mainLevel: 1,
          subLevel: 5,
          kind: LessonKind.assessment,
          title: 'Evaluación: Fundamentos',
          conceptsPracticed: [ConceptIds.rules],
          difficultyRange: [1, 2],
        ),
      ],
    ),
    // ---------------------------------------------------------------
    MainLevel(
      number: 2,
      title: 'Ranking de manos',
      theme: 'Reconocer y comparar correctamente las manos',
      lessons: [
        Lesson(
          mainLevel: 2,
          subLevel: 1,
          kind: LessonKind.theory,
          title: 'La jerarquía de manos',
          conceptsIntroduced: [ConceptIds.handRanking],
        ),
        Lesson(
          mainLevel: 2,
          subLevel: 2,
          kind: LessonKind.basic,
          title: 'Comparar dos manos',
          conceptsPracticed: [ConceptIds.handRanking],
          difficultyRange: [1, 1],
        ),
        Lesson(
          mainLevel: 2,
          subLevel: 3,
          kind: LessonKind.intermediate,
          title: 'Manos parecidas',
          conceptsPracticed: [ConceptIds.handRanking],
          difficultyRange: [2, 2],
        ),
        Lesson(
          mainLevel: 2,
          subLevel: 4,
          kind: LessonKind.challenge,
          title: 'El showdown difícil',
          conceptsPracticed: [ConceptIds.handRanking],
          difficultyRange: [3, 3],
        ),
        Lesson(
          mainLevel: 2,
          subLevel: 5,
          kind: LessonKind.assessment,
          title: 'Evaluación: Ranking de manos',
          conceptsPracticed: [ConceptIds.handRanking],
          difficultyRange: [2, 3],
        ),
      ],
    ),
    // ---------------------------------------------------------------
    MainLevel(
      number: 3,
      title: 'Posición',
      theme: 'Por qué la posición cambia las decisiones',
      lessons: [
        Lesson(
          mainLevel: 3,
          subLevel: 1,
          kind: LessonKind.theory,
          title: 'Las posiciones en 6-max',
          conceptsIntroduced: [
            ConceptIds.positionNames,
            ConceptIds.blinds,
            ConceptIds.utg,
            ConceptIds.hj,
            ConceptIds.co,
            ConceptIds.btn,
          ],
        ),
        Lesson(
          mainLevel: 3,
          subLevel: 2,
          kind: LessonKind.basic,
          title: 'El orden de acción',
          conceptsPracticed: [ConceptIds.positionNames],
          difficultyRange: [1, 1],
        ),
        Lesson(
          mainLevel: 3,
          subLevel: 3,
          kind: LessonKind.intermediate,
          title: 'Temprana, media y tardía',
          conceptsIntroduced: [ConceptIds.positionAdvantage],
          conceptsPracticed: [ConceptIds.positionNames],
          difficultyRange: [2, 2],
        ),
        Lesson(
          mainLevel: 3,
          subLevel: 4,
          kind: LessonKind.challenge,
          title: 'Actuar primero vs actuar último',
          conceptsPracticed: [
            ConceptIds.positionAdvantage,
            ConceptIds.positionNames,
          ],
          difficultyRange: [2, 3],
        ),
        Lesson(
          mainLevel: 3,
          subLevel: 5,
          kind: LessonKind.assessment,
          title: 'Evaluación: Posición',
          conceptsPracticed: [
            ConceptIds.positionNames,
            ConceptIds.positionAdvantage,
          ],
          difficultyRange: [2, 3],
        ),
      ],
    ),
    // ---------------------------------------------------------------
    MainLevel(
      number: 4,
      title: 'Rangos',
      theme: 'No decidimos solo mirando nuestra mano',
      lessons: [
        Lesson(
          mainLevel: 4,
          subLevel: 1,
          kind: LessonKind.theory,
          title: 'Qué es un rango',
          conceptsIntroduced: [ConceptIds.openingRange],
          conceptsPracticed: [ConceptIds.positionAdvantage],
        ),
        Lesson(
          mainLevel: 4,
          subLevel: 2,
          kind: LessonKind.basic,
          title: '¿Está la mano en el rango?',
          conceptsPracticed: [ConceptIds.openingRange, ConceptIds.handRanking],
          difficultyRange: [1, 2],
        ),
        Lesson(
          mainLevel: 4,
          subLevel: 3,
          kind: LessonKind.intermediate,
          title: 'Rangos más anchos y más cerrados',
          conceptsIntroduced: [ConceptIds.rangeWidth],
          conceptsPracticed: [ConceptIds.positionAdvantage],
          difficultyRange: [2, 3],
        ),
        Lesson(
          mainLevel: 4,
          subLevel: 4,
          kind: LessonKind.challenge,
          title: 'Rango según la posición',
          conceptsPracticed: [
            ConceptIds.openingRange,
            ConceptIds.rangeWidth,
            ConceptIds.handRanking,
          ],
          difficultyRange: [3, 3],
        ),
        Lesson(
          mainLevel: 4,
          subLevel: 5,
          kind: LessonKind.assessment,
          title: 'Evaluación: Rangos',
          conceptsPracticed: [ConceptIds.openingRange, ConceptIds.rangeWidth],
          difficultyRange: [2, 3],
        ),
      ],
    ),
    // ---------------------------------------------------------------
    MainLevel(
      number: 5,
      title: 'Open raise',
      theme: 'Integrar posición + rango + acción + sizing',
      lessons: [
        Lesson(
          mainLevel: 5,
          subLevel: 1,
          kind: LessonKind.theory,
          title: 'Abrir o foldear',
          conceptsIntroduced: [ConceptIds.openRaise],
          conceptsPracticed: [ConceptIds.openingRange],
        ),
        Lesson(
          mainLevel: 5,
          subLevel: 2,
          kind: LessonKind.basic,
          title: '¿Abro esta mano?',
          conceptsPracticed: [ConceptIds.openRaise, ConceptIds.openingRange],
          difficultyRange: [1, 2],
        ),
        Lesson(
          mainLevel: 5,
          subLevel: 3,
          kind: LessonKind.intermediate,
          title: 'El tamaño de la subida',
          conceptsIntroduced: [ConceptIds.openSizing],
          conceptsPracticed: [ConceptIds.openRaise],
          difficultyRange: [2, 3],
        ),
        Lesson(
          mainLevel: 5,
          subLevel: 4,
          kind: LessonKind.challenge,
          title: 'Decisión completa',
          conceptsPracticed: [
            ConceptIds.openRaise,
            ConceptIds.openingRange,
            ConceptIds.positionAdvantage,
            ConceptIds.rangeWidth,
          ],
          difficultyRange: [3, 4],
        ),
        Lesson(
          mainLevel: 5,
          subLevel: 5,
          kind: LessonKind.assessment,
          title: 'Evaluación: Open raise',
          conceptsPracticed: [
            ConceptIds.openRaise,
            ConceptIds.openingRange,
            ConceptIds.openSizing,
          ],
          difficultyRange: [2, 4],
        ),
      ],
    ),
  ];
}

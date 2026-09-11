import 'theory.dart';

/// El tipo de sub-nivel (patrón Duolingo: teoría → básico → intermedio →
/// challenge → evaluación). Se deriva del **estadio cognitivo** del subnivel
/// en el nuevo currículo (ver [CognitiveStage] / [SublevelKind]).
enum LessonKind {
  theory('Teoría', 1),
  basic('Ejercicios básicos', 1),
  intermediate('Ejercicios intermedios', 3),
  challenge('Challenge', 4),
  assessment('Evaluación', 3);

  const LessonKind(this.label, this.baseDifficulty);
  final String label;
  final int baseDifficulty;

  static LessonKind fromSublevelKind(SublevelKind k) => switch (k) {
        SublevelKind.theory => LessonKind.theory,
        SublevelKind.basic => LessonKind.basic,
        SublevelKind.intermediate => LessonKind.intermediate,
        SublevelKind.challenge => LessonKind.challenge,
        SublevelKind.assessment => LessonKind.assessment,
      };
}

/// Un sub-nivel concreto (`"5.3"`). Es la unidad que el alumno completa.
///
/// **Vista de compatibilidad** sobre un [Sublevel] del [CurriculumSpec]: el
/// contenido curricular vive en `assets/curriculum/curriculum_spec.json`, no
/// acá. Esta clase existe para no reescribir de golpe todo lo que consumía la
/// vieja estructura de 25 lecciones.
class Lesson {
  Lesson.fromSublevel(this._s, {
    required this.conceptsIntroduced,
    required this.conceptsPracticed,
  });

  final Sublevel _s;

  int get mainLevel => _s.nivel;
  int get subLevel => _s.index;
  LessonKind get kind => LessonKind.fromSublevelKind(_s.kind);
  String get title => _s.nombre;
  String get id => _s.code;

  /// El subnivel del currículo nuevo detrás de esta lección.
  Sublevel get sublevel => _s;

  /// Conceptos que este sub-nivel enseña por primera vez.
  final List<String> conceptsIntroduced;

  /// Conceptos que este sub-nivel repasa (ya introducidos antes).
  final List<String> conceptsPracticed;

  List<int> get difficultyRange => switch (_s.dificultad) {
        Difficulty.fundamental => const [1, 1],
        Difficulty.basico => const [1, 2],
        Difficulty.intermedio => const [2, 3],
        Difficulty.avanzado => const [3, 4],
      };
}

/// Un nivel principal de la Academia (1..13). Representa una **capacidad**.
class MainLevel {
  MainLevel.fromLevel(this._l, this.lessons);

  final CurriculumLevel _l;

  int get number => _l.n;
  String get title => _l.nombre;

  /// La capacidad que adquiere el alumno ("Después de este nivel, puede…").
  String get theme => _l.capacidad;

  final List<Lesson> lessons;
}

/// El plan de estudios completo — 13 niveles, 64 subniveles, 326 teorías.
///
/// Deriva TODO de [CurriculumSpec] (que a su vez viene del JSON maestro). No
/// hay estructura hardcodeada acá.
class Curriculum {
  Curriculum._(this.spec, this.levels, this._byId, this._introducedUpTo);

  /// El currículo nuevo, con la información completa (teorías, prerrequisitos,
  /// estadios, visualización, legacy…).
  final CurriculumSpec spec;

  final List<MainLevel> levels;
  final Map<String, Lesson> _byId;

  /// code de subnivel → set acumulado de conceptos introducidos hasta ahí.
  final Map<String, Set<String>> _introducedUpTo;

  List<Lesson> get allLessons =>
      [for (final l in levels) ...l.lessons];

  Lesson? lessonById(String id) => _byId[id];

  /// Conceptos ya introducidos hasta [lessonId] inclusive.
  Set<String> conceptsTaughtUpTo(String lessonId) =>
      _introducedUpTo[lessonId] ?? const {};

  /// Ids de todos los subniveles, en orden de recorrido.
  static List<String> get lessonOrder =>
      CurriculumSpec.standard().allSublevels.map((s) => s.code).toList();

  factory Curriculum.standard() => _cache ??= _build();

  static Curriculum? _cache;

  static Curriculum _build() {
    final spec = CurriculumSpec.standard();

    // conceptsIntroduced/Practiced por subnivel: un concepto se "introduce"
    // en el primer subnivel (por orden) que lo lista en conceptosClave; en
    // los siguientes se cuenta como "practicado".
    final seen = <String>{};
    final introducedBySub = <String, List<String>>{};
    final practicedBySub = <String, List<String>>{};
    final introUpTo = <String, Set<String>>{};
    for (final s in spec.allSublevels) {
      final intro = <String>[];
      final prac = <String>[];
      for (final c in s.conceptosClave) {
        if (seen.add(c)) {
          intro.add(c);
        } else {
          prac.add(c);
        }
      }
      introducedBySub[s.code] = intro;
      practicedBySub[s.code] = prac;
      introUpTo[s.code] = {...seen};
    }

    final byId = <String, Lesson>{};
    final levels = <MainLevel>[];
    for (final l in spec.levels) {
      final lessons = <Lesson>[];
      for (final s in l.sublevels) {
        final lesson = Lesson.fromSublevel(
          s,
          conceptsIntroduced: introducedBySub[s.code] ?? const [],
          conceptsPracticed: practicedBySub[s.code] ?? const [],
        );
        lessons.add(lesson);
        byId[s.code] = lesson;
      }
      levels.add(MainLevel.fromLevel(l, lessons));
    }
    return Curriculum._(spec, levels, byId, introUpTo);
  }

  /// Solo para tests.
  static void resetCache() {
    _cache = null;
    CurriculumSpec.resetCache();
  }
}

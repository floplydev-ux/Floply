/// Modelos tipados del currículo de la Academia.
///
/// **Fuente de verdad:** `assets/curriculum/curriculum_spec.json`.
/// Ese JSON se compila a `curriculum_spec_data.g.dart` (constantes Dart, carga
/// síncrona) con `scratchpad/gen_curriculum.py`. Estos modelos leen esas
/// constantes; nadie duplica el contenido curricular a mano.
///
/// Jerarquía:  [CurriculumSpec] → [CurriculumLevel] → [Sublevel] → [Theory].
///
/// Una **teoría** es una unidad conceptual del currículo (los 308 temas del
/// documento maestro + 18 nuevas = 326). No equivale a una pantalla: una
/// teoría puede desarrollarse en varios pasos sobre la mesa.
///
/// El **camino** que ve el alumno es lineal (nivel a nivel). El **grafo** de
/// prerrequisitos (por teoría) es para el motor: recuperación, ejercicios
/// dirigidos, estadísticas y el futuro Coach. Ver [CurriculumUnlockMode].
library;

import 'curriculum_spec_data.g.dart';

/// Banda de dificultad de un nivel.
enum Difficulty {
  fundamental('FUNDAMENTAL'),
  basico('BASICO'),
  intermedio('INTERMEDIO'),
  avanzado('AVANZADO');

  const Difficulty(this.code);
  final String code;

  static Difficulty fromCode(String c) {
    final n = c.toUpperCase().replaceAll('Á', 'A').replaceAll('É', 'E');
    return Difficulty.values.firstWhere(
      (d) => d.code == n,
      orElse: () => Difficulty.fundamental,
    );
  }

  int get order => index;
}

/// Estadio cognitivo dominante de un subnivel (curva de aprendizaje).
///
/// reconocer → elegir → decidir → explicar. No se adelanta "explicar"
/// mientras el alumno todavía está aprendiendo a "reconocer".
enum CognitiveStage {
  reconocer('RECONOCER'),
  elegir('ELEGIR'),
  decidir('DECIDIR'),
  explicar('EXPLICAR');

  const CognitiveStage(this.code);
  final String code;

  static CognitiveStage fromCode(String c) => CognitiveStage.values.firstWhere(
        (s) => s.code == c.toUpperCase(),
        orElse: () => CognitiveStage.reconocer,
      );
}

/// Tipo de subnivel, derivado del estadio cognitivo (para íconos / lógica de
/// UI). Compatible con el `LessonKind` histórico.
enum SublevelKind {
  theory('teoría'),
  basic('ejercicios básicos'),
  intermediate('ejercicios intermedios'),
  challenge('challenge'),
  assessment('evaluación');

  const SublevelKind(this.label);
  final String label;

  static SublevelKind fromCode(String c) => switch (c) {
        'theory' => SublevelKind.theory,
        'basic' => SublevelKind.basic,
        'intermediate' => SublevelKind.intermediate,
        'challenge' => SublevelKind.challenge,
        'assessment' => SublevelKind.assessment,
        _ => SublevelKind.basic,
      };
}

/// Cómo se abre el contenido para el alumno.
///
///  * [linear]        → N1 → N2 → … → N13. El subnivel N abre cuando el
///    anterior está completo. **Modo actual.**
///  * [prerequisites] → un subnivel abre cuando *todos* sus prerrequisitos
///    (los de sus teorías) están dominados. Para más adelante.
///
/// El modo vive en `meta.unlock_mode` del JSON y se puede cambiar sin tocar
/// los modelos, el currículo ni la UI principal.
enum CurriculumUnlockMode { linear, prerequisites }

/// Estado de redacción del contenido de una teoría (PASO 4, nivel por nivel).
enum WritingStatus { pendiente, borrador, listo }

WritingStatus _writingStatus(String s) => WritingStatus.values.firstWhere(
      (w) => w.name == s,
      orElse: () => WritingStatus.pendiente,
    );

/// Contenido interino heredado de las 25 lecciones actuales.
///
/// Nada se borra en la migración: cada subnivel nuevo apunta, mientras no se
/// redacte su contenido definitivo, a los assets de las lecciones antiguas
/// (guiones de mesa, sets de ejercicios interactivos, teoría en texto,
/// `PracticeSpec` del motor, `ComprehensionCheck`). Las claves son ids de
/// lección histórica (`"1.1"` … `"5.5"`).
class LegacyContentRef {
  const LegacyContentRef({
    this.tableScripts = const [],
    this.exerciseSets = const [],
    this.textTheory = const [],
    this.practice = const [],
    this.checks = const [],
  });

  final List<String> tableScripts;
  final List<String> exerciseSets;
  final List<String> textTheory;
  final List<String> practice;
  final List<String> checks;

  bool get isEmpty =>
      tableScripts.isEmpty &&
      exerciseSets.isEmpty &&
      textTheory.isEmpty &&
      practice.isEmpty &&
      checks.isEmpty;

  static LegacyContentRef? fromMap(Object? raw) {
    if (raw is! Map) return null;
    List<String> g(String k) =>
        (raw[k] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final ref = LegacyContentRef(
      tableScripts: g('table_scripts'),
      exerciseSets: g('exercise_sets'),
      textTheory: g('text_theory'),
      practice: g('practice'),
      checks: g('checks'),
    );
    return ref.isEmpty ? null : ref;
  }
}

/// Contenido pedagógico redactado de una teoría (se completa en PASO 4).
///
/// No todos los campos aplican a toda teoría. Se usan los que aportan valor.
class TheoryContent {
  const TheoryContent({
    this.queEs,
    this.porQueImporta,
    this.comoFunciona,
    this.cuandoLoUso,
    this.cuandoNo,
    this.ejemplo,
    this.errorComun,
    this.ideaClave,
    this.pasosMesa = const [],
  });

  final String? queEs;
  final String? porQueImporta;
  final String? comoFunciona;
  final String? cuandoLoUso;
  final String? cuandoNo;
  final String? ejemplo;
  final String? errorComun;
  final String? ideaClave;

  /// Pasos sobre la mesa (situación + burbuja). Vacío = la teoría todavía no
  /// tiene guion visual redactado.
  final List<TheoryStep> pasosMesa;

  bool get isEmpty =>
      queEs == null &&
      porQueImporta == null &&
      comoFunciona == null &&
      ideaClave == null &&
      pasosMesa.isEmpty;

  static TheoryContent? fromMap(Object? raw) {
    if (raw is! Map) return null;
    String? s(String k) {
      final v = raw[k];
      return (v is String && v.trim().isNotEmpty) ? v : null;
    }

    final pasos = <TheoryStep>[];
    final rawPasos = raw['pasosMesa'];
    if (rawPasos is List) {
      for (final p in rawPasos) {
        if (p is Map) {
          pasos.add(TheoryStep(
            bubble: p['bubble']?.toString() ?? '',
            note: p['note']?.toString(),
          ));
        }
      }
    }

    final content = TheoryContent(
      queEs: s('queEs'),
      porQueImporta: s('porQueImporta'),
      comoFunciona: s('comoFunciona'),
      cuandoLoUso: s('cuandoLoUso'),
      cuandoNo: s('cuandoNo'),
      ejemplo: s('ejemplo'),
      errorComun: s('errorComun'),
      ideaClave: s('ideaClave'),
      pasosMesa: pasos,
    );
    return content.isEmpty ? null : content;
  }
}

/// Un paso del guion visual de una teoría (equivalente a `TableStep`, pero
/// como dato de contenido). La conversión a `TableSnapshot` se hace en la capa
/// de presentación.
class TheoryStep {
  const TheoryStep({required this.bubble, this.note});
  final String bubble;
  final String? note;
}

/// Una teoría del currículo.
class Theory {
  Theory({
    required this.id,
    required this.numeroCurriculo,
    required this.esNueva,
    required this.titulo,
    required this.nivel,
    required this.subnivel,
    required this.ordenGlobal,
    required this.dificultad,
    required this.estadio,
    required this.objetivo,
    required this.visualizacionMesa,
    required this.prerrequisitos,
    required this.teoriasRelacionadas,
    required this.conceptosClave,
    required this.estadoRedaccion,
    this.contenido,
    this.ejerciciosRelacionados = const [],
  });

  /// Id estable: `T001`…`T308` para las 308 originales (coincide con
  /// [numeroCurriculo]), `TN01`…`TN18` para las nuevas.
  final String id;

  /// Número en el documento maestro (1..308). `null` si es una teoría nueva.
  final int? numeroCurriculo;

  final bool esNueva;
  final String titulo;

  /// Número de nivel (1..13).
  final int nivel;

  /// Código de subnivel (`"5.3"`).
  final String subnivel;

  /// Posición en el recorrido lineal completo (1..326).
  final int ordenGlobal;

  final Difficulty dificultad;
  final CognitiveStage estadio;
  final String objetivo;

  /// `true` si el concepto se puede (y conviene) mostrar sobre la mesa.
  final bool visualizacionMesa;

  /// Ids de teorías que hay que dominar antes (grafo para el motor).
  final List<String> prerrequisitos;

  /// Ids de teorías del mismo tema (navegación / Coach).
  final List<String> teoriasRelacionadas;

  /// Ids de conceptos del `ConceptRegistry` que esta teoría enseña/refuerza.
  /// Vacío mientras el concepto no exista todavía (se crea en PASO 4).
  final List<String> conceptosClave;

  final WritingStatus estadoRedaccion;

  /// Contenido redactado. `null` hasta PASO 4.
  TheoryContent? contenido;

  /// Ids de ejercicios asociados (se poblará al construir el Salón de
  /// Práctica).
  final List<String> ejerciciosRelacionados;

  bool get tieneContenido =>
      contenido != null && !contenido!.isEmpty;

  factory Theory.fromMap(Map<String, Object?> m) {
    List<String> ls(String k) =>
        (m[k] as List?)?.map((e) => e.toString()).toList() ?? const [];
    return Theory(
      id: m['id']! as String,
      numeroCurriculo: m['numeroCurriculo'] as int?,
      esNueva: m['esNueva'] as bool? ?? false,
      titulo: m['titulo']! as String,
      nivel: m['nivel']! as int,
      subnivel: m['subnivel']! as String,
      ordenGlobal: m['ordenGlobal']! as int,
      dificultad: Difficulty.fromCode(m['dificultad']! as String),
      estadio: CognitiveStage.fromCode(m['estadio']! as String),
      objetivo: m['objetivo']! as String,
      visualizacionMesa: m['visualizacionMesa'] as bool? ?? true,
      prerrequisitos: ls('prerrequisitos'),
      teoriasRelacionadas: ls('teoriasRelacionadas'),
      conceptosClave: ls('conceptosClave'),
      estadoRedaccion: _writingStatus(m['estadoRedaccion'] as String? ?? 'pendiente'),
      contenido: TheoryContent.fromMap(m['contenido']),
    );
  }
}

/// Un subnivel: un grupo de teorías que se aprenden juntas. Es la **unidad
/// que el alumno completa** (equivale a la vieja "lección").
class Sublevel {
  Sublevel({
    required this.code,
    required this.nombre,
    required this.nivel,
    required this.objetivo,
    required this.estadio,
    required this.kind,
    required this.esCheckpoint,
    required this.dificultad,
    required this.prerequisiteSublevels,
    required this.conceptosClave,
    required this.legacy,
    required this.theories,
  });

  /// `"5.3"`.
  final String code;
  final String nombre;
  final int nivel;
  final String objetivo;
  final CognitiveStage estadio;
  final SublevelKind kind;

  /// El último subnivel de cada nivel funciona como checkpoint: si se completa
  /// por debajo del umbral, el nivel no queda aprobado y se ofrece
  /// recuperación de conceptos.
  final bool esCheckpoint;

  final Difficulty dificultad;

  /// Códigos de subniveles que hay que completar antes (modo lineal usa el
  /// inmediato anterior; este campo lo hace explícito para el modo
  /// prerrequisitos).
  final List<String> prerequisiteSublevels;

  final List<String> conceptosClave;
  final LegacyContentRef? legacy;
  final List<Theory> theories;

  bool get isAssessment => kind == SublevelKind.assessment;

  /// Índice dentro de su nivel (1-based).
  int get index => int.parse(code.split('.')[1]);
}

/// Un nivel principal. Representa una **capacidad** concreta.
class CurriculumLevel {
  CurriculumLevel({
    required this.n,
    required this.nombre,
    required this.capacidad,
    required this.dificultad,
    required this.sublevels,
  });

  final int n;
  final String nombre;

  /// "Después de este nivel, el jugador puede…".
  final String capacidad;
  final Difficulty dificultad;
  final List<Sublevel> sublevels;
}

/// Un problema detectado al validar el currículo.
class CurriculumIssue {
  const CurriculumIssue(this.severity, this.message);
  final String severity; // 'error' | 'warning'
  final String message;
  @override
  String toString() => '[$severity] $message';
}

/// El currículo completo, cargado desde las constantes generadas.
class CurriculumSpec {
  CurriculumSpec._(this.meta, this.levels)
      : _byId = {
          for (final l in levels)
            for (final s in l.sublevels)
              for (final t in s.theories) t.id: t,
        },
        _sublevelByCode = {
          for (final l in levels)
            for (final s in l.sublevels) s.code: s,
        };

  final Map<String, Object?> meta;
  final List<CurriculumLevel> levels;
  final Map<String, Theory> _byId;
  final Map<String, Sublevel> _sublevelByCode;

  // ---- singleton ----
  static CurriculumSpec? _instance;

  /// La instancia estándar (desde `curriculum_spec_data.g.dart`).
  factory CurriculumSpec.standard() => _instance ??= _build();

  static CurriculumSpec _build() {
    const theoryMaps = kCurriculumTheories;
    final theoriesByCode = <String, List<Theory>>{};
    for (final tm in theoryMaps) {
      final t = Theory.fromMap(tm);
      (theoriesByCode[t.subnivel] ??= []).add(t);
    }
    for (final list in theoriesByCode.values) {
      list.sort((a, b) => a.ordenGlobal.compareTo(b.ordenGlobal));
    }

    final levels = <CurriculumLevel>[];
    for (final lm in kCurriculumLevels) {
      final subs = <Sublevel>[];
      for (final sm in (lm['subniveles']! as List).cast<Map<String, Object?>>()) {
        final code = sm['code']! as String;
        subs.add(Sublevel(
          code: code,
          nombre: sm['nombre']! as String,
          nivel: sm['nivel']! as int,
          objetivo: sm['objetivo']! as String,
          estadio: CognitiveStage.fromCode(sm['estadio']! as String),
          kind: SublevelKind.fromCode(sm['kind']! as String),
          esCheckpoint: sm['esCheckpoint'] as bool? ?? false,
          dificultad: Difficulty.fromCode(sm['dificultad']! as String),
          prerequisiteSublevels:
              (sm['prerrequisitos'] as List?)?.map((e) => e.toString()).toList() ??
                  const [],
          conceptosClave:
              (sm['conceptosClave'] as List?)?.map((e) => e.toString()).toList() ??
                  const [],
          legacy: LegacyContentRef.fromMap(sm['legacy']),
          theories: theoriesByCode[code] ?? const [],
        ));
      }
      levels.add(CurriculumLevel(
        n: lm['n']! as int,
        nombre: lm['nombre']! as String,
        capacidad: lm['capacidad']! as String,
        dificultad: Difficulty.fromCode(lm['dificultad']! as String),
        sublevels: subs,
      ));
    }
    return CurriculumSpec._(kCurriculumSpecMeta, levels);
  }

  // ---- consultas ----

  Iterable<Theory> get allTheories => _byId.values;

  int get theoryCount => _byId.length;

  /// Todos los subniveles en orden de recorrido.
  List<Sublevel> get allSublevels =>
      [for (final l in levels) ...l.sublevels];

  Theory? theoryById(String id) => _byId[id];

  Sublevel? sublevelByCode(String code) => _sublevelByCode[code];

  CurriculumLevel? levelByNumber(int n) =>
      levels.where((l) => l.n == n).firstOrNull;

  /// Teorías de un subnivel, en orden.
  List<Theory> theoriesOfSublevel(String code) =>
      _sublevelByCode[code]?.theories ?? const [];

  /// Teorías de un nivel, en orden.
  List<Theory> theoriesOfLevel(int n) => [
        for (final s in levelByNumber(n)?.sublevels ?? const <Sublevel>[])
          ...s.theories,
      ];

  /// Prerrequisitos directos de una teoría.
  List<String> prerequisitesOf(String theoryId) =>
      _byId[theoryId]?.prerrequisitos ?? const [];

  /// Todos los prerrequisitos (transitivos) de una teoría.
  Set<String> allPrerequisitesOf(String theoryId) {
    final out = <String>{};
    final stack = [...prerequisitesOf(theoryId)];
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      if (out.add(cur)) stack.addAll(prerequisitesOf(cur));
    }
    return out;
  }

  /// Teorías que dependen (directamente) de [theoryId].
  List<String> dependentsOf(String theoryId) => [
        for (final t in _byId.values)
          if (t.prerrequisitos.contains(theoryId)) t.id,
      ];

  /// Modo de desbloqueo declarado en el JSON.
  CurriculumUnlockMode get unlockMode =>
      (meta['unlock_mode'] == 'prerequisites')
          ? CurriculumUnlockMode.prerequisites
          : CurriculumUnlockMode.linear;

  /// ¿El subnivel [code] está disponible, dado el set de subniveles ya
  /// completados? [completedTheoryIds] solo se usa en modo prerrequisitos.
  bool isSublevelUnlocked(
    String code,
    Set<String> completedSublevelCodes, {
    Set<String>? completedTheoryIds,
    CurriculumUnlockMode? mode,
  }) {
    final m = mode ?? unlockMode;
    final order = allSublevels.map((s) => s.code).toList();
    final idx = order.indexOf(code);
    if (idx <= 0) return true;
    if (m == CurriculumUnlockMode.linear) {
      return completedSublevelCodes.contains(order[idx - 1]);
    }
    // prerequisites
    final done = completedTheoryIds ?? const <String>{};
    final needed = theoriesOfSublevel(code)
        .expand((t) => t.prerrequisitos)
        .toSet();
    return needed.every(done.contains);
  }

  // ---- validación (mismos chequeos que el generador, en runtime) ----

  List<CurriculumIssue> validate() {
    final issues = <CurriculumIssue>[];
    final ids = <String>{};
    final numeros = <int, int>{};
    final pos = <String, int>{
      for (final t in _byId.values) t.id: t.ordenGlobal,
    };

    for (final t in _byId.values) {
      if (!ids.add(t.id)) {
        issues.add(CurriculumIssue('error', 'id duplicado: ${t.id}'));
      }
      final n = t.numeroCurriculo;
      if (n != null) numeros[n] = (numeros[n] ?? 0) + 1;
      for (final p in t.prerrequisitos) {
        if (!pos.containsKey(p)) {
          issues.add(
              CurriculumIssue('error', '${t.id} prereq inexistente: $p'));
        } else if (pos[p]! >= t.ordenGlobal) {
          issues.add(CurriculumIssue('error',
              '${t.id} tiene un prereq posterior: $p'));
        }
      }
    }

    final missing = [
      for (var i = 1; i <= 308; i++)
        if ((numeros[i] ?? 0) == 0) i,
    ];
    final dup = [
      for (final e in numeros.entries)
        if (e.value > 1) e.key,
    ];
    if (missing.isNotEmpty) {
      issues.add(CurriculumIssue(
          'error', 'faltan temas del documento: $missing'));
    }
    if (dup.isNotEmpty) {
      issues.add(CurriculumIssue('error', 'temas duplicados: $dup'));
    }

    // subniveles: prereqs resuelven, dificultad monótona
    final subOrder = {
      for (var i = 0; i < allSublevels.length; i++) allSublevels[i].code: i,
    };
    for (final s in allSublevels) {
      for (final p in s.prerequisiteSublevels) {
        if (!subOrder.containsKey(p)) {
          issues.add(CurriculumIssue(
              'error', 'subnivel ${s.code}: prereq inexistente $p'));
        } else if (subOrder[p]! >= subOrder[s.code]!) {
          issues.add(CurriculumIssue(
              'warning', 'subnivel ${s.code}: prereq no anterior $p'));
        }
      }
    }
    var prevBand = -1;
    for (final l in levels) {
      if (l.dificultad.order < prevBand) {
        issues.add(CurriculumIssue(
            'error', 'N${l.n} baja de dificultad'));
      }
      prevBand = l.dificultad.order > prevBand ? l.dificultad.order : prevBand;
    }

    return issues;
  }

  /// Solo para tests / debug.
  static void resetCache() => _instance = null;
}

/// Modelo de una **clase de mentor**: la experiencia que reemplaza a la
/// ficha de teoría estática (`WrittenTheoryView`) para las teorías que ya
/// migraron al nuevo paradigma pedagógico ("un profesor te está enseñando",
/// no "estás leyendo un manual").
///
/// **Por qué esto y no un cuarto sistema paralelo.** Antes de crear este
/// archivo se compararon `TheoryContent.pasosMesa`/`TheoryStep` (declarado,
/// nunca redactado en las 326 teorías), `TableLessonScript`/`TableStep`
/// (guion legacy, solo narra), `VisualTheoryLesson`/`VisualTheoryStep`
/// (piloto de 4 teorías, solo narra, burbuja flotante) e
/// `InteractiveTableExercise` (situación → pregunta → opciones con
/// feedback → explicación, pero solo en la fase de ejercicios, con
/// scoring). Ninguno alcanzaba solo: `MentorLesson` generaliza los tres
/// primeros (que son, en esencia, la misma idea con distinto nivel de
/// detalle) en un único tipo de "turno" narrativo (`MentorSay`), y reutiliza
/// literalmente el tipo de `InteractiveTableExercise` para las preguntas
/// (`ExerciseChoice`: label/rating/feedback) en un turno de comprobación
/// (`MentorCheck`) que el controller nunca puntúa ni manda a
/// `UserKnowledge.recordAttempt` — la distinción pedida por el usuario:
/// *MentorCheck = "¿entendiste?", Exercise = "aplicalo"*.
///
/// No reemplaza `TableLessonScript` (contenido legado de las 25 lecciones
/// viejas, fuera de alcance) ni migra todavía los 4 `VisualTheoryLesson`
/// del piloto anterior — eso queda señalado como trabajo futuro en vez de
/// hecho a mitad de camino (ver informe de la Fase 3).
library;

import 'dart:math' as math;

import 'table_exercise.dart' show ExerciseChoice;
import 'table_lesson.dart';

/// Qué tipo de momento pedagógico es un [MentorSay]. Cambia el ícono/acento
/// visual, nunca la estructura de datos — así se puede agregar un rol nuevo
/// sin tocar el renderer.
enum MentorSayRole {
  /// Abre la clase planteando una situación o pregunta — nunca una
  /// definición (ver sección 4 del prompt maestro).
  intro,

  /// "Fijate en esto": dirige la atención a un elemento concreto de la mesa.
  observe,

  /// El cuerpo de la explicación (equivalente a "cómo funciona").
  explain,

  /// Un ejemplo concreto aplicado.
  example,

  /// Anticipa un error típico del principiante.
  error,

  /// Conecta con una teoría anterior o prepara la siguiente, sin enseñarla.
  bridge,

  /// La idea que el alumno se debe llevar. Cierre.
  keyIdea,
}

/// Un turno donde el mentor **habla** (con o sin apoyo de mesa). Generaliza
/// `TableStep`/`VisualTheoryStep`: agrega [role] (para el acento visual) y
/// hace la mesa opcional — muchas teorías no necesitan tablero para un turno
/// puntual (una definición corta, un puente, la idea clave).
class MentorSay {
  const MentorSay(
    this.text, {
    this.role = MentorSayRole.explain,
    this.table,
    this.anchor,
    this.highlight = const [],
    this.cardGlow = const {},
  });

  final String text;
  final MentorSayRole role;

  /// `null` = turno puramente textual, sin mesa (una definición corta, un
  /// puente, la idea clave). No-`null` = se dibuja la mesa con la misma
  /// burbuja flotante que ya usa el piloto visual.
  final TableSnapshot? table;

  /// Obligatorio cuando [table] no es `null` (a qué apunta la burbuja).
  final TableAnchor? anchor;
  final List<TableAnchor> highlight;
  final Set<CardRef> cardGlow;

  bool get hasTable => table != null;

  List<TableAnchor> get effectiveHighlight =>
      highlight.isNotEmpty ? highlight : [if (anchor != null) anchor!];
}

/// Un turno donde el mentor **pregunta** y espera una respuesta antes de
/// continuar. Exclusivamente pedagógico: el controller nunca llama
/// `UserKnowledge.recordAttempt` para esto, nunca cuenta para mastery/XP,
/// nunca bloquea el avance salvo por "todavía no respondiste".
///
/// Reutiliza [ExerciseChoice] tal cual (label/rating/feedback) — la misma
/// forma de dato que ya usan los ejercicios reales — para no inventar un
/// segundo modelo de "opción con feedback".
class MentorCheck {
  const MentorCheck({
    required this.prompt,
    required this.options,
    this.table,
    this.anchor,
    this.highlight = const [],
    this.wrapUp,
  });

  /// La pregunta del mentor, en una burbuja (o card, si no hay mesa).
  final String prompt;

  final List<ExerciseChoice> options;

  final TableSnapshot? table;
  final TableAnchor? anchor;
  final List<TableAnchor> highlight;

  /// Una frase final que el mentor dice después de la respuesta —
  /// cualquiera haya sido la opción elegida. Consolida la idea en vez de
  /// dejar que el feedback puntual de la opción sea lo último que se lee.
  /// `null` si el feedback de cada opción ya alcanza.
  final String? wrapUp;

  bool get hasTable => table != null;

  List<TableAnchor> get effectiveHighlight =>
      highlight.isNotEmpty ? highlight : [if (anchor != null) anchor!];
}

/// Un turno de la clase: o habla el mentor, o pregunta. Nunca las dos cosas
/// a la vez (una `MentorCheck` que necesite decir algo antes solo necesita
/// que el turno anterior de la lista sea un `MentorSay`).
sealed class MentorBeat {
  const MentorBeat();
}

class MentorSayBeat extends MentorBeat {
  const MentorSayBeat(this.say);
  final MentorSay say;
}

class MentorCheckBeat extends MentorBeat {
  const MentorCheckBeat(this.check);
  final MentorCheck check;
}

/// La clase de mentor completa de una teoría puntual.
class MentorLesson {
  const MentorLesson(this.theoryId, this.beats);

  /// Id de la teoría que enseña (`"T020"`).
  final String theoryId;

  final List<MentorBeat> beats;

  int get length => beats.length;
  bool get isEmpty => beats.isEmpty;
}

/// Azúcar para autoría: evita escribir `MentorSayBeat(MentorSay(...))` y
/// `MentorCheckBeat(MentorCheck(...))` en cada línea del contenido.
extension MentorLessonBuilder on List<MentorBeat> {
  void say(
    String text, {
    MentorSayRole role = MentorSayRole.explain,
    TableSnapshot? table,
    TableAnchor? anchor,
    List<TableAnchor> highlight = const [],
    Set<CardRef> cardGlow = const {},
  }) =>
      add(MentorSayBeat(MentorSay(
        text,
        role: role,
        table: table,
        anchor: anchor,
        highlight: highlight,
        cardGlow: cardGlow,
      )));

  void ask(
    String prompt, {
    required List<ExerciseChoice> options,
    TableSnapshot? table,
    TableAnchor? anchor,
    List<TableAnchor> highlight = const [],
    String? wrapUp,
  }) =>
      add(MentorCheckBeat(MentorCheck(
        prompt: prompt,
        options: _shuffledChoices(prompt, options),
        table: table,
        anchor: anchor,
        highlight: highlight,
        wrapUp: wrapUp,
      )));
}

/// Reordena [options] con una semilla derivada del propio [prompt] — así
/// la misma pregunta siempre queda en el mismo orden (estable entre
/// sesiones y para los tests), pero preguntas distintas caen en órdenes
/// distintos, sin ningún patrón fijo ni una posición siempre correcta.
///
/// QA pedagógico 2026-09-20: las 18 preguntas `.ask()` existentes
/// (`mentor_lessons_n1.dart` + `mentor_pilot_lessons.dart`) tenían la
/// opción `ExerciseRating.best` en el índice 0 el 100% de las veces — un
/// alumno podía "acertar" tocando siempre la primera sin leer nada. Este
/// shuffle es la corrección general (en el único punto donde se
/// construyen todas las `MentorCheck`, no en cada guion) — no toca el
/// contenido de ninguna opción (label/rating/feedback viajan juntos, se
/// permutan como unidad), así que la identidad de cada respuesta se
/// preserva íntegra.
List<ExerciseChoice> _shuffledChoices(
    String prompt, List<ExerciseChoice> options) {
  if (options.length <= 1) return options;
  final seed = prompt.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);
  final rnd = math.Random(seed);
  final shuffled = List<ExerciseChoice>.of(options);
  for (var i = shuffled.length - 1; i > 0; i--) {
    final j = rnd.nextInt(i + 1);
    final tmp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = tmp;
  }
  return shuffled;
}

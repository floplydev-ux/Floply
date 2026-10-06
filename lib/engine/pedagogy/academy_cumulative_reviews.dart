import 'academy_exercise_scripts.dart';
import 'table_exercise.dart';

/// **Repasos acumulativos** — 4 evaluaciones de repaso que cruzan varios
/// niveles, además de la evaluación propia de cada módulo (el subnivel
/// `kind: assessment`/checkpoint de cada nivel, ver `theory.dart`):
///
///  - Repaso 1, después de aprobar el checkpoint de N3 (`3.5`): repasa N1-3.
///  - Repaso 2, después de N6 (`6.7`): repasa N1-6.
///  - Repaso 3, después de N9 (`9.5`): repasa N1-9.
///  - Repaso 4, después de N13 (`13.5`): repasa TODA la Academia, N1-13.
///
/// **No crea un sistema paralelo**: reutiliza tal cual los mismos
/// `InteractiveTableExercise` ya autorados por subnivel (los mismos que se
/// practican en 5.1, 7.3, etc.) vía [AcademyExerciseScripts.forLesson] — un
/// repaso es, ni más ni menos, una selección curada de preguntas que YA
/// existen, tomadas de varios subniveles a la vez. No se enseña nada nuevo:
/// cada pregunta ya fue vista (o su equivalente) en el módulo de origen, y
/// por construcción nunca cae fuera de [Curriculum.conceptsTaughtUpTo] del
/// punto donde se ofrece el repaso.
///
/// **Diseño "espiral"**: cada repaso repite completo (o casi) el tramo más
/// reciente todavía no repasado, y toca más liviano los módulos ya vistos en
/// un repaso anterior — así la duración no crece sin límite a medida que
/// avanza la Academia, pero ningún nivel queda nunca afuera de ningún
/// repaso que lo incluya.
class AcademyCumulativeReviews {
  AcademyCumulativeReviews._();

  /// El subnivel-checkpoint que, al aprobarse, ofrece cada repaso.
  static const Map<String, String> reviewByCheckpointLesson = {
    '3.5': 'review.3',
    '6.7': 'review.6',
    '9.5': 'review.9',
    '13.5': 'review.13',
  };

  /// Orden fijo de los 4 repasos (para recorrerlos en `pendingReviewId`).
  static const List<String> order = [
    'review.3',
    'review.6',
    'review.9',
    'review.13',
  ];

  static const Map<String, String> titles = {
    'review.3': 'Repaso: módulos 1 → 3',
    'review.6': 'Repaso: módulos 1 → 6',
    'review.9': 'Repaso: módulos 1 → 9',
    'review.13': 'Repaso final: módulos 1 → 13',
  };

  static InteractiveExerciseSet? forId(String reviewId) => _byId[reviewId];

  /// Toma UNA pregunta representativa de cada subnivel listado — nunca el
  /// set completo. Varios subniveles heredados de N1-N3 tienen baterías
  /// enteras de práctica (hasta 16 ejercicios cada una); un repaso no es
  /// "repetir toda esa práctica de nuevo", es tocar cada subnivel una vez y
  /// avanzar. Así la duración depende de CUÁNTOS subniveles entran, no de
  /// cuántos ejercicios tenga cada uno.
  ///
  /// Toma la ÚLTIMA del set, no la primera: el checkpoint de cada nivel
  /// (`X.Y` con `Y` el último subnivel, ver `reviewByCheckpointLesson`)
  /// ahora empieza repasando los subniveles ANTERIORES del mismo nivel
  /// (sección 1, evaluación de módulo) y termina con su propio contenido
  /// original al final de la lista — tomar la última evita repetir, dos
  /// veces en el mismo repaso, una pregunta que ya se sampleó por separado
  /// desde su código de origen (p. ej. `'5.1'` Y la primera de `'5.6'`
  /// serían la misma pregunta si tomáramos la primera).
  ///
  /// Deduplica por texto de pregunta: algunos subniveles heredados de
  /// N1-N3 comparten, sin que esto sea nada nuevo de acá, la misma
  /// pregunta de cierre entre dos lecciones vecinas (p. ej. 2.1 y 2.2)
  /// — un repaso nunca debería mostrar la misma pregunta dos veces.
  static InteractiveExerciseSet _pick(List<String> codes) {
    final seenQuestions = <String>{};
    final exercises = <InteractiveTableExercise>[
      for (final code in codes)
        if (AcademyExerciseScripts.forLesson(code)?.exercises.isNotEmpty ??
            false)
          if (seenQuestions.add(
              AcademyExerciseScripts.forLesson(code)!.exercises.last.question))
            AcademyExerciseScripts.forLesson(code)!.exercises.last,
    ];
    return InteractiveExerciseSet(exercises);
  }

  // ------------------------------------------------------------------
  // Repaso 1 — N1-3 completo (8 preguntas tras deduplicar: todavía no se
  // repasó nada, así que entran los 10 subniveles con ejercicios propios
  // del tramo — falta 3.4, que no tiene set, gap preexistente que no se
  // inventa acá; 2.1/2.2 y 3.1/3.2 comparten pregunta de cierre y quedan
  // en 1 sola tras deduplicar).
  // ------------------------------------------------------------------
  static InteractiveExerciseSet _review3() => _pick(const [
        '1.1', '1.2', '1.3', '1.4',
        '2.1', '2.2',
        '3.1', '3.2', '3.3', '3.5',
      ]);

  // ------------------------------------------------------------------
  // Repaso 2 — toque liviano a N1-3 (los 3 checkpoints, ya repasados en el
  // Repaso 1) + N4-6 completo (16 preguntas).
  // ------------------------------------------------------------------
  static InteractiveExerciseSet _review6() => _pick(const [
        '1.4', '2.2', '3.5',
        '4.6',
        '5.1', '5.2', '5.3', '5.4', '5.5', '5.6',
        '6.1', '6.2', '6.3', '6.4', '6.5', '6.6', '6.7',
      ]);

  // ------------------------------------------------------------------
  // Repaso 3 — toque liviano a N1-6 (sus 6 checkpoints) + N7-9 completo
  // (20 preguntas).
  // ------------------------------------------------------------------
  static InteractiveExerciseSet _review9() => _pick(const [
        '1.4', '2.2', '3.5', '4.6', '5.6', '6.7',
        '7.1', '7.2', '7.3', '7.4',
        '8.1', '8.2', '8.3', '8.4', '8.5', '8.6',
        '9.1', '9.2', '9.3', '9.4', '9.5',
      ]);

  // ------------------------------------------------------------------
  // Repaso 4 (capstone) — un checkpoint por cada uno de N1-9 (ya
  // repasados a fondo en los repasos 1-3) + selección representativa de
  // N10-13, el tramo más nuevo (20 preguntas en total: el cierre de toda
  // la Academia justifica un repaso más largo que los anteriores).
  // ------------------------------------------------------------------
  static InteractiveExerciseSet _review13() => _pick(const [
        '1.4', '2.2', '3.5', '4.6', '5.6', '6.7', '7.4', '8.6', '9.5',
        '10.1', '10.2', '10.4',
        '11.1', '11.3', '11.4', '11.6',
        '12.1', '12.4',
        '13.1', '13.3', '13.5',
      ]);

  static final Map<String, InteractiveExerciseSet> _byId = {
    'review.3': _review3(),
    'review.6': _review6(),
    'review.9': _review9(),
    'review.13': _review13(),
  };
}

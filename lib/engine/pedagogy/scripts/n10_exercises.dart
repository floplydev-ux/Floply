import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 10 "Leer al rival".
class N10Exercises {
  N10Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '10.1': InteractiveExerciseSet([_checkNoEsNada()]),
    '10.2': InteractiveExerciseSet([_rangoTrasRaise()]),
    '10.3': InteractiveExerciseSet([_contarCombos()]),
    // 10.4 es el checkpoint del nivel: la evaluación del módulo repasa
    // que un check no es "nada", el rango tras un raise y contar combos,
    // antes de cerrar con su propio contenido (¿valor o farol?).
    '10.4': InteractiveExerciseSet([
      _checkNoEsNada(),
      _rangoTrasRaise(),
      _contarCombos(),
      _valorOFarol(),
    ]),
  };

  // ================================================================
  // 10.1 — Cada acción es información
  // ================================================================
  static InteractiveTableExercise _checkNoEsNada() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2},
        actions: const {1: 'ABRE', 4: 'CHECK'},
        bets: const {1: 2.5},
        cards: const {0: ['Jc', 'Jd']},
        toAct: 0,
      ),
      board: const ['Ts', '6d', '2c'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(1),
      situationHighlight: const [TableAnchor.seat(1)],
      question: '{CO} abrió preflop (con la iniciativa) y ahora pasa en '
          'el flop. ¿Qué es más correcto pensar sobre su rango?',
      choices: const [
        ExerciseChoice(
          label: 'PROBABLEMENTE NO TIENE SUS MANOS MÁS FUERTES',
          rating: ExerciseRating.best,
          feedback: 'Correcto: un check saca del rango, sobre todo, las '
              'manos MÁS fuertes (esas suelen apostar solas) — pero '
              'sigue pudiendo tener manos medias o incluso un proyecto.',
        ),
        ExerciseChoice(
          label: 'SEGURO NO TIENE NADA',
          rating: ExerciseRating.poor,
          feedback: 'Demasiado tajante: un check no es "nada", puede '
              'incluir manos medias e incluso fuertes jugando pot '
              'control.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Cada acción recorta el rango, no lo define por '
              'completo. Un check acota sin eliminar todo.',
          anchor: TableAnchor.seat(1),
        ),
      ],
    );
  }

  // ================================================================
  // 10.2 — Rango tras agresión (raise)
  // ================================================================
  static InteractiveTableExercise _rangoTrasRaise() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'CHECK-RAISE'},
        bets: const {4: 10.0},
        cards: const {0: ['Ad', 'Kc']},
        toAct: 0,
      ),
      board: const ['Kh', '8h', '3h'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(4),
      situationHighlight: const [TableAnchor.seat(4)],
      question: '{BB} te pasa y te sube (check-raise) tu c-bet en un '
          'board con proyecto de color. ¿Qué tipo de rango representa, '
          'en general, un check-raise postflop?',
      choices: const [
        ExerciseChoice(
          label: 'POLARIZADO: MANOS FUERTES O SEMI-FAROLES',
          rating: ExerciseRating.best,
          feedback: 'Correcto: subir cuesta más fichas que pagar. Los '
              'jugadores suelen reservarlo para sus mejores manos o '
              'buenos proyectos — no para manos medias.',
        ),
        ExerciseChoice(
          label: 'CUALQUIER MANO, SIN PATRÓN',
          rating: ExerciseRating.poor,
          feedback: 'Un check-raise no es al azar: casi siempre viene de '
              'un rango más polarizado que un simple call.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Con proyecto de color visible en el board, este '
              'check-raise puede ser valor (color ya hecho) o un buen '
              'semi-farol — de cualquier forma, no suele ser una mano '
              'media.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 10.3 — Estrechar el rango (contar combos)
  // ================================================================
  static InteractiveTableExercise _contarCombos() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(labels: TableBuilder.btnHero),
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.pot,
      question: 'Después de estrechar el rango del rival, todavía '
          'incluye AA (6 combos) y AK (16 combos). Solo con esa '
          'diferencia de combos, ¿qué mano es más probable que tenga?',
      choices: const [
        ExerciseChoice(
          label: 'AK — tiene casi el triple de combos',
          rating: ExerciseRating.best,
          feedback: 'Correcto: 16 combos contra 6 — aunque las dos manos '
              'sigan siendo posibles, AK pesa mucho más solo por '
              'cantidad de combinaciones.',
        ),
        ExerciseChoice(
          label: 'AA — es más fuerte, así que es más probable',
          rating: ExerciseRating.poor,
          feedback: 'Ser más fuerte no la hace más PROBABLE. La '
              'probabilidad depende de cuántos combos reales quedan, no '
              'de qué tan buena es la mano.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Contar combos te dice qué tan probable es cada mano '
              'dentro del rango ya estrechado — no alcanza con saber '
              'que "todavía es posible".',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 10.4 — ¿Valor o farol?
  // ================================================================
  static InteractiveTableExercise _valorOFarol() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'APUESTA GRANDE'},
        bets: const {4: 14.0},
        cards: const {0: ['Kd', 'Kc']},
        toAct: 0,
      ),
      board: const ['Qh', '9h', '4c', '2h', '7s'],
      potBb: 12.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(4),
      situationHighlight: const [TableAnchor.seat(4), TableAnchor.board],
      question: 'El rival pasó el flop y el turn (en un board con '
          'proyecto de color en juego) y ahora, en el río, apuesta muy '
          'grande, después de que el color no llegó a completarse '
          '(river 7♠, sin corazón). ¿La línea completa encaja más con '
          'valor o con un farol?',
      choices: const [
        ExerciseChoice(
          label: 'FAROL',
          rating: ExerciseRating.best,
          feedback: 'Coherente con farol: si tuviera una mano de valor '
              'hecha, lo normal hubiera sido apostar antes, no pasar dos '
              'calles y recién apostar grande cuando su proyecto de '
              'color falló.',
        ),
        ExerciseChoice(
          label: 'VALOR',
          rating: ExerciseRating.poor,
          feedback: 'La línea no cierra con valor: pasar dos calles y '
              'apostar grande justo cuando el color no llegó es más '
              'típico de alguien que se quedó sin proyecto e intenta '
              'ganar el bote de otra forma.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'La línea completa (check-check-bet grande, justo tras '
              'fallar un proyecto visible) cuenta una historia más '
              'creíble de farol que de valor.',
          anchor: TableAnchor.seat(4),
        ),
      ],
    );
  }
}

import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 8 "El flop: c-bet".
class N8Exercises {
  N8Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '8.1': InteractiveExerciseSet([_iniciativa()]),
    '8.2': InteractiveExerciseSet([_cbetProyecto()]),
    '8.3': InteractiveExerciseSet([_boardSecoVsCoordinado()]),
    '8.4': InteractiveExerciseSet([_fueraDePosicion()]),
    '8.5': InteractiveExerciseSet([_tamanoCbet()]),
    '8.6': InteractiveExerciseSet([_enfrentarCbet()]),
  };

  static TableSnapshot _heroOpenedTable({
    required List<String> board,
    List<String> heroCards = const ['Ac', 'Kd'],
    double pot = 6.0,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: TableBuilder.btnHero,
          folded: const {3, 2, 1},
          cards: {0: heroCards},
          toAct: 0,
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  // ================================================================
  // 8.1 — La iniciativa y la c-bet
  // ================================================================
  static InteractiveTableExercise _iniciativa() {
    final table = _heroOpenedTable(board: const ['Kc', '7d', '2s']);
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.cbet,
      strategyDependent: true,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Abriste preflop y te pagó la BB: tenés la iniciativa. '
          'Board seco K♣7♦2♠, tenés top pair. ¿C-beteás?',
      choices: const [
        ExerciseChoice(
          label: 'C-BETEAR',
          rating: ExerciseRating.best,
          feedback: 'Sí: tenés la iniciativa, un board seco (pocos '
              'proyectos posibles), y una mano hecha que quiere cobrar.',
        ),
        ExerciseChoice(
          label: 'PASAR',
          rating: ExerciseRating.poor,
          feedback: 'Pasar acá regala la ventaja de la iniciativa y no '
              'cobra valor de un top pair en un board donde el rival '
              'suele haber fallado.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Iniciativa + board seco + mano de valor: los tres '
              'motivos apuntan a c-betear.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 8.2 — C-bet con proyecto (semi-farol)
  // ================================================================
  static InteractiveTableExercise _cbetProyecto() {
    final table = _heroOpenedTable(
      board: const ['Jh', 'Th', '4c'],
      heroCards: const ['Qh', '9h'],
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.cbet,
      strategyDependent: true,
      questionAnchor: TableAnchor.heroCards,
      question: 'Tenés Q♥9♥: proyecto de color Y de escalera abierta '
          '(ningún par todavía). Tenés la iniciativa. ¿C-beteás con este '
          'proyecto?',
      choices: const [
        ExerciseChoice(
          label: 'SÍ, C-BETEAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: es un semi-farol de manual — ganás si el '
              'rival se retira, y si paga seguís con muchísimos outs '
              'reales para las próximas calles.',
        ),
        ExerciseChoice(
          label: 'PASAR, ESPERAR A TENER ALGO HECHO',
          rating: ExerciseRating.poor,
          feedback: 'Con tantos outs (color + escalera combinados), '
              'apostar ahora gana de dos formas — pasar deja esa doble '
              'chance sobre la mesa.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'C-bet con proyecto = gana por fold equity ahora, o por '
              'equity real si te pagan. No hace falta tener la mano hecha.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 8.3 — C-bet según el board
  // ================================================================
  static InteractiveTableExercise _boardSecoVsCoordinado() {
    final table = _heroOpenedTable(
      board: const ['9s', '8s', '7d'],
      heroCards: const ['Ac', 'Kc'],
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.boardTexture,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: 'Board 9♠8♠7♦: muy coordinado. Con A♣K♣ (sin nada hecho '
          'ni proyecto real acá), ¿tu frecuencia de c-bet en este board '
          'debería ser alta o baja comparada con un board seco?',
      choices: const [
        ExerciseChoice(
          label: 'BAJA — más selectivo',
          rating: ExerciseRating.best,
          feedback: 'Correcto: en un board tan coordinado, muchas manos '
              'del rango del rival conectaron algo. Conviene ser más '
              'selectivo con el farol puro.',
        ),
        ExerciseChoice(
          label: 'ALTA — igual que en un board seco',
          rating: ExerciseRating.poor,
          feedback: 'En un board coordinado como este, mantener la misma '
              'frecuencia que en un board seco regala fichas contra un '
              'rango que conectó mucho más seguido.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Board coordinado = más manos del rival conectaron = '
              'c-bet más selectiva. Es lo opuesto a un board seco como '
              'K♣7♦2♠.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 8.4 — C-bet según la posición
  // ================================================================
  static InteractiveTableExercise _fueraDePosicion() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.utgHero,
        folded: const {2, 1},
        actions: const {1: 'PAGA'},
        cards: const {0: ['Ad', 'Qs']},
        toAct: 0,
      ),
      board: const ['Kh', '7c', '2d'],
      potBb: 6.0,
      buttonSlot: 3,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.cbet,
      strategyDependent: true,
      questionAnchor: TableAnchor.heroCards,
      question: 'Abriste desde UTG y te pagó la BB: vas a jugar el resto '
          'de la mano FUERA de posición. Con A♦Q♠ (sin pareja en este '
          'board), ¿elegís una mano con un plan claro para seguir, o '
          'cualquier cosa?',
      choices: const [
        ExerciseChoice(
          label: 'UNA MANO CON PLAN CLARO PARA SEGUIR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: fuera de posición no vas a ver la '
              'reacción del rival antes de tu próxima decisión — conviene '
              'c-betear con manos donde ya sabés qué vas a hacer después.',
        ),
        ExerciseChoice(
          label: 'CUALQUIER MANO, IGUAL QUE EN POSICIÓN',
          rating: ExerciseRating.poor,
          feedback: 'Fuera de posición tenés menos información para las '
              'calles siguientes: c-betear con la misma amplitud que en '
              'posición te deja sin plan cuando venga la próxima decisión.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'En posición podés c-betear más ancho porque vas a ver '
              'la reacción del rival antes de decidir de nuevo.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 8.5 — Frecuencia y tamaño
  // ================================================================
  static InteractiveTableExercise _tamanoCbet() {
    final table = _heroOpenedTable(
      board: const ['Jh', 'Th', '9h'],
      heroCards: const ['As', 'Ad'],
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.cbet,
      questionAnchor: TableAnchor.board,
      question: 'Board J♥T♥9♥ (muy coordinado, con color y escalera '
          'posibles). Tenés overpair de ases. ¿Qué tamaño de c-bet tiene '
          'más sentido acá?',
      choices: const [
        ExerciseChoice(
          label: 'GRANDE (dos tercios del bote o más)',
          rating: ExerciseRating.best,
          feedback: 'Correcto: en un board con tantos proyectos posibles, '
              'un tamaño grande cobra mejor a esos proyectos y a las manos '
              'hechas más flojas que igual pagan.',
        ),
        ExerciseChoice(
          label: 'CHICO (un tercio del bote)',
          rating: ExerciseRating.acceptable,
          feedback: 'No es un error grave, pero en un board tan mojado un '
              'tamaño chico le da a los proyectos del rival un precio '
              'demasiado barato para seguir.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'En boards coordinados, con muchos proyectos posibles, '
              'un tamaño más grande cobra mejor y cobra más caro a esos '
              'proyectos que en un board seco.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 8.6 — Enfrentar una apuesta postflop
  // ================================================================
  static InteractiveTableExercise _enfrentarCbet() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'C-BET'},
        bets: const {4: 4.0},
        cards: const {0: ['9d', '8d']},
        toAct: 0,
      ),
      board: const ['Kc', 'Qs', '2h'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(4),
      situationHighlight: const [TableAnchor.seat(4), TableAnchor.heroCards],
      question: '{BB} c-betea un board K-Q-2. Tenés 9♦8♦: sin nada hecho '
          'ni proyecto real en este board. ¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: sin mano ni proyecto, y sin motivos para '
              'pensar que el rival se retira, no hay nada que justifique '
              'seguir.',
        ),
        ExerciseChoice(
          label: 'PAGAR',
          rating: ExerciseRating.poor,
          feedback: 'Pagar sin mano ni proyecto, "para ver", es tirar '
              'fichas sin ningún plan para las calles siguientes.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Enfrentar una c-bet junta tu mano, el board y el rango '
              'probable del rival — acá ninguno de los tres te da motivos '
              'para seguir.',
          anchor: TableAnchor.seat(4),
        ),
      ],
    );
  }
}

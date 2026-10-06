import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos sobre la mesa — subniveles del Nivel 4 y la
/// pasarela N3.4.
///
/// Incluye:
///  • **3.4** — Stack efectivo (fichas y stacks, concepto `rules`)
///  • **4.1** — Tipos de mano inicial (concepto `handRanking`)
///  • **4.2** — Fuerza de la mano inicial (concepto `handRanking`)
///  • **4.3** — Texturas de board (concepto `boardTexture`)
///  • **4.4** — Proyectos y cartas clave (concepto `boardTexture`)
///  • **4.5** — Tu mano hecha en el flop (concepto `handRanking`)
///  • **4.6** — Checkpoint (manos grandes y nuts, showdown)
class Level4Exercises {
  Level4Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '3.4': InteractiveExerciseSet([_stackEfectivo()]),
    '4.1': InteractiveExerciseSet([_tipoDeManoPP()]),
    '4.2': InteractiveExerciseSet([_fuerzaParPequeno()]),
    '4.3': InteractiveExerciseSet([_texturaBoard()]),
    '4.4': InteractiveExerciseSet([_proyectoEscalera()]),
    '4.5': InteractiveExerciseSet([_topPair()]),
    '4.6': InteractiveExerciseSet([
      // Escalera vs pareja.
      _sd(['6h', '7d', '8c', '2s', 'Ks'], ['9c', 'Ts'], ['Ah', 'Kh'],
          heroWins: true, heroCat: 'escalera', rivalCat: 'pareja de reyes'),
      // Color vs trío.
      _sd(['2s', '6s', '9s', 'Kd', '3h'], ['As', 'Js'], ['Kh', 'Kc'],
          heroWins: true, heroCat: 'color', rivalCat: 'trío de reyes'),
      // Full house vs trío.
      _sd(['7d', '7h', '2c', '9s', '9h'], ['9c', '4d'], ['7c', 'Kd'],
          heroWins: true,
          heroCat: 'full house (nueves con sietes)',
          rivalCat: 'trío de sietes'),
      // Los nuts (póker) vs trío.
      _sd(['5c', '5d', '5h', '8s', '2h'], ['5s', 'Ah'], ['8d', '8c'],
          heroWins: true,
          heroCat: 'póker de cincos (los nuts acá)',
          rivalCat: 'trío de ochos'),
      // Bluff catcher: una pareja modesta le gana a una mano sin nada.
      _sd(['Kh', '9c', '4s', '2d', '7h'], ['Qc', 'Qd'], ['Jc', 'Ts'],
          heroWins: true,
          heroCat: 'pareja de damas (bluff catcher)',
          rivalCat: 'carta alta, sin nada'),
      // El héroe pierde: doble pareja no le alcanza contra una escalera.
      _sd(['4c', '5d', '6h', '9s', 'Kd'], ['Kc', '9c'], ['3h', '7c'],
          heroWins: false, heroCat: 'doble pareja', rivalCat: 'escalera'),
    ]),
  };

  static const _labels = TableBuilder.btnHero; // 0 = usuario, 3 = rival (UTG)
  static const _concept = ConceptIds.handRanking; // mismo skill que 2.1/2.2,
  // reforzado acá con manos más grandes — 4.6 no introduce un concepto
  // nuevo (`conceptos_clave` está vacío para este subnivel en el spec).

  static TableSnapshot _showdown(
    List<String> board,
    List<String> hero,
    List<String> rival,
  ) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          folded: const {5, 4, 2, 1},
          cards: {0: hero, 3: rival},
        ),
        board: board,
        potBb: 22,
        buttonSlot: 0,
      );

  static InteractiveTableExercise _sd(
    List<String> board,
    List<String> hero,
    List<String> rival, {
    required bool heroWins,
    required String heroCat,
    required String rivalCat,
  }) {
    final table = _showdown(board, hero, rival);
    final winnerAnchor =
        heroWins ? TableAnchor.heroCards : const TableAnchor.seat(3);

    final choices = <ExerciseChoice>[
      ExerciseChoice(
        label: '{me} · $heroCat',
        rating: heroWins ? ExerciseRating.best : ExerciseRating.poor,
        feedback: heroWins
            ? 'Sí: tu $heroCat le gana al $rivalCat de {UTG}.'
            : 'No: tu $heroCat pierde contra el $rivalCat de {UTG}.',
      ),
      ExerciseChoice(
        label: '{UTG} · $rivalCat',
        rating: heroWins ? ExerciseRating.poor : ExerciseRating.best,
        feedback: heroWins
            ? 'No: el $rivalCat de {UTG} está por debajo de tu $heroCat.'
            : 'Sí: el $rivalCat de {UTG} le gana a tu $heroCat.',
      ),
      const ExerciseChoice(
        label: 'EMPATE',
        rating: ExerciseRating.poor,
        feedback: 'No hay empate: las dos manos son de categorías '
            'distintas, así que una es claramente superior.',
      ),
    ];

    return InteractiveTableExercise(
      situation: table,
      concept: _concept,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [
        TableAnchor.heroCards,
        TableAnchor.seat(3),
        TableAnchor.board,
      ],
      question: 'Mostraron las cartas en el river. ¿Quién gana el bote?',
      choices: choices,
      explanation: [
        ExerciseExplainStep(
          text: heroWins
              ? 'Vos tenés $heroCat; {UTG}, $rivalCat.'
              : '{UTG} tiene $rivalCat; vos, $heroCat.',
          anchor: winnerAnchor,
          highlight: [winnerAnchor],
        ),
        const ExerciseExplainStep(
          text: 'El orden de las categorías de mano es fijo — de mayor a '
              'menor: póker, full house, color, escalera, trío, doble '
              'pareja, pareja, carta alta.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 3.4 — Stack efectivo
  // ================================================================

  static InteractiveTableExercise _stackEfectivo() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        stacks: {0: 90, 5: 60},
        folded: {4, 3, 2, 1},
      ),
      potBb: 1.5,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.rules,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.seat(5)],
      question: 'Vos tenés 90 BB; el SB, 60 BB. ¿Cuál es el stack efectivo '
          'en esta mano?',
      choices: const [
        ExerciseChoice(
          label: '60 BB',
          rating: ExerciseRating.best,
          feedback: 'Exacto: el stack efectivo es el menor de los dos. '
              'No podés ganar ni perder más de 60 BB contra el SB.',
        ),
        ExerciseChoice(
          label: '90 BB',
          rating: ExerciseRating.poor,
          feedback: 'Ese es tu stack. El efectivo es el menor: 60 BB, '
              'porque el SB no puede responder más de eso.',
        ),
        ExerciseChoice(
          label: '150 BB',
          rating: ExerciseRating.poor,
          feedback: 'Eso sería la suma de los dos. '
              'El stack efectivo es el mínimo: 60 BB.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El BTN tiene 90 BB; el SB, 60 BB.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.seat(5)],
        ),
        ExerciseExplainStep(
          text: 'El stack efectivo es siempre el menor de los dos. '
              'Solo podés ganar — o perder — lo que ambos comparten.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 4.1 — Tipos de mano inicial
  // ================================================================

  static InteractiveTableExercise _tipoDeManoPP() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        cards: const {
          0: ['9c', '8c'],
        },
      ),
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.handRanking,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: '¿Cómo se clasifica la mano 9♣ 8♣?',
      choices: const [
        ExerciseChoice(
          label: 'Conector suited',
          rating: ExerciseRating.best,
          feedback: 'Sí: las dos cartas son del mismo palo (suited) y '
              'están separadas por exactamente un rango (conectadas).',
        ),
        ExerciseChoice(
          label: 'Par servido',
          rating: ExerciseRating.poor,
          feedback: 'Un par servido son dos cartas del mismo rango '
              '(p. ej. 9-9). Acá son 9 y 8 — distintos rangos.',
        ),
        ExerciseChoice(
          label: 'Broadway',
          rating: ExerciseRating.poor,
          feedback: 'Las broadways son las cartas altas: A, K, Q, J y T. '
              'El 9 y el 8 no entran en esa categoría.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Suited: mismo palo (los dos trébol ♣). '
              'Conector: separados solo un rango (9 y 8).',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards],
        ),
        ExerciseExplainStep(
          text: 'Un conector suited combina el potencial de proyecto de '
              'escalera con el de color — dos draws posibles.',
          anchor: TableAnchor.heroCards,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 4.2 — Fuerza de la mano inicial
  // ================================================================

  static InteractiveTableExercise _fuerzaParPequeno() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        cards: const {
          0: ['2h', '2d'],
        },
      ),
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.handRanking,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: '¿Cómo se llama la categoría de 2♥ 2♦ y qué se busca '
          'al jugarlo?',
      choices: const [
        ExerciseChoice(
          label: 'Par pequeño — buscar set',
          rating: ExerciseRating.best,
          feedback: 'Sí: los pares del 2 al 5 son pares pequeños. '
              'Su valor está en hacer un set (trío) en el flop.',
        ),
        ExerciseChoice(
          label: 'Mano premium — siempre 3-bet',
          rating: ExerciseRating.poor,
          feedback: 'Las manos premium son AA, KK, QQ, JJ, AKs. '
              'Un par de dos es especulativo, no premium.',
        ),
        ExerciseChoice(
          label: 'Par mediano — jugar solo en posición',
          rating: ExerciseRating.poor,
          feedback: 'Pares medianos son del 6 al 9. El 2-2 es un '
              'par pequeño con una dinámica distinta.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Pares pequeños: del 2 al 5. '
              'Pares medianos: 6-9. Premium: 10 en adelante.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards],
        ),
        ExerciseExplainStep(
          text: 'Un par pequeño suele jugar en modo "set mining": '
              'llamar una apuesta modesta y buscar mejorar a trío en el flop.',
          anchor: TableAnchor.heroCards,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 4.3 — Texturas de board
  // ================================================================

  static InteractiveTableExercise _texturaBoard() {
    const board = ['Ks', '9h', '2d'];
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        cards: const {
          0: ['Ac', 'Jc'],
        },
        folded: const {5, 4, 3, 2},
      ),
      board: board,
      potBb: 6,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.boardTexture,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: '¿Cómo se describe la textura del board K♠ 9♥ 2♦?',
      choices: const [
        ExerciseChoice(
          label: 'Seco (dry)',
          rating: ExerciseRating.best,
          feedback: 'Sí: tres palos distintos (rainbow) y cartas no '
              'conectadas. Hay pocas posibilidades de proyecto.',
        ),
        ExerciseChoice(
          label: 'Coordinado',
          rating: ExerciseRating.poor,
          feedback: 'Un board coordinado tiene cartas consecutivas o del '
              'mismo palo que forman proyectos. K-9-2 no tiene eso.',
        ),
        ExerciseChoice(
          label: 'Monocromo',
          rating: ExerciseRating.poor,
          feedback: 'Monocromo significa tres cartas del mismo palo. '
              'Acá hay tres palos diferentes (rainbow).',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'K♠ 9♥ 2♦: tres palos distintos → rainbow. '
              'K, 9 y 2 no están conectados → pocas escaleras posibles.',
          anchor: TableAnchor.board,
          highlight: [TableAnchor.board],
        ),
        ExerciseExplainStep(
          text: 'Un board seco/dry favorece al que apuesta: '
              'el rival tiene pocas combinaciones de proyecto que puedan mejorar.',
          anchor: TableAnchor.board,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 4.4 — Proyectos y cartas clave
  // ================================================================

  static InteractiveTableExercise _proyectoEscalera() {
    const board = ['Qh', '9s', '3d'];
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        cards: const {
          0: ['Jc', 'Td'],
        },
        folded: const {5, 4, 3, 2},
      ),
      board: board,
      potBb: 8,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.boardTexture,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'El héroe tiene J♣T♦ y el board es Q♥9♠3♦. '
          '¿Qué tipo de proyecto tiene?',
      choices: const [
        ExerciseChoice(
          label: 'Escalera abierta (OESD)',
          rating: ExerciseRating.best,
          feedback: 'Sí: Q-J-T-9 son cuatro cartas consecutivas. '
              'Entra un 8 o un K → escalera completa.',
        ),
        ExerciseChoice(
          label: 'Proyecto de color',
          rating: ExerciseRating.poor,
          feedback: 'Para un proyecto de color se necesitan 4 cartas del '
              'mismo palo. J♣ y T♦ son de palos distintos y el board '
              'no suma ningún palo en cuatro.',
        ),
        ExerciseChoice(
          label: 'Sin proyecto (carta alta)',
          rating: ExerciseRating.poor,
          feedback: 'El héroe tiene un proyecto de escalera abierto, '
              'no carta alta. Con Q-J-T-9 sobre la mesa, ocho cartas '
              'completan la escalera.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'J♣T♦ + Q♥9♠: los cuatro rangos Q-J-T-9 están en juego.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.board],
        ),
        ExerciseExplainStep(
          text: 'OESD (open-ended): entra cualquiera de los dos extremos. '
              'Un 8 hace 8-9-T-J-Q; un K hace 9-T-J-Q-K. '
              'Son 8 outs, el proyecto más potente.',
          anchor: TableAnchor.board,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 4.5 — Tu mano hecha en el flop
  // ================================================================

  static InteractiveTableExercise _topPair() {
    const board = ['Ah', '7c', '2s'];
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        cards: const {
          0: ['As', 'Kd'],
        },
        folded: const {5, 4, 3, 2},
      ),
      board: board,
      potBb: 7,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.handRanking,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'El héroe tiene A♠K♦ y el board es A♥7♣2♠. '
          '¿Qué mano tiene en el flop?',
      choices: const [
        ExerciseChoice(
          label: 'Top pair, kicker rey',
          rating: ExerciseRating.best,
          feedback: 'Exacto: el héroe hace pareja con el As, que es la '
              'carta más alta del board. Kicker rey es el mejor posible.',
        ),
        ExerciseChoice(
          label: 'Overpair',
          rating: ExerciseRating.poor,
          feedback: 'Un overpair es una pareja servida en mano que supera '
              'a todas las cartas del board. Acá el héroe no tiene par '
              'servido — tiene A-K de palos distintos.',
        ),
        ExerciseChoice(
          label: 'Set de ases',
          rating: ExerciseRating.poor,
          feedback: 'Un set requiere un par servido en mano más la carta '
              'en el board (p. ej. A-A en mano + A en board). '
              'El héroe tiene A-K, no A-A.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El A♠ de la mano empareja con el A♥ del board.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.board],
        ),
        ExerciseExplainStep(
          text: 'Top pair: la pareja es con la carta más alta del board '
              '(el As). El K es el kicker — desempata si el rival '
              'también tiene un as.',
          anchor: TableAnchor.board,
          dimOthers: false,
        ),
      ],
    );
  }
}

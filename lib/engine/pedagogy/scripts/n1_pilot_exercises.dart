import 'dart:math' as math;

import '../table_exercise.dart';
import '../table_lesson.dart';

/// Ejercicios interactivos del piloto de 3 bloques de los subniveles 1.1,
/// 1.2 y 1.3 (Bloque C) — mesa + pregunta sobre lo que ya enseñaron sus
/// teorías.
///
/// 1.1: cartas privadas, comunitarias, flop/turn/river, las 7 disponibles y
/// las mejores 5. 1.2: showdown, empate exacto, que apostar más no decide, y
/// ganar por fold. 1.3: las 6 acciones (fold/check/call/bet/raise/re-raise),
/// all-in, acción cerrada, acción legal y orden de acción. Ninguno usa
/// ranking de manos (pareja, trío, etc.) ni nombres de posición (BTN/SB/BB):
/// eso es Nivel 2 y Nivel 3, todavía no enseñados. Las opciones se muestran
/// en orden aleatorio
/// (semilla derivada de la pregunta, igual que `MentorLessonBuilder.ask` en
/// `mentor_lesson.dart`): la respuesta correcta no siempre es la primera.
class N1PilotExercises {
  N1PilotExercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '1.1': InteractiveExerciseSet([
      _cartasPrivadas(),
      _etapaFlop(),
      _cartaDelTurn(),
      _totalComunitarias(),
      _sieteDisponibles(),
      _manoFinalDeCinco(),
      _cualesCinco(),
      _losPalosValenIgual(),
    ]),
    '1.2': InteractiveExerciseSet([
      _queEsShowdown(),
      _comoSeDecideElGanador(),
      _empateExacto(),
      _apostarMasNoDecide(),
      _ganarPorFold(),
      _noHaceFaltaLaMejorMano(),
    ]),
    '1.3': InteractiveExerciseSet([
      _foldEjercicio(),
      _checkEjercicio(),
      _callEjercicio(),
      _betEjercicio(),
      _raiseEjercicio(),
      _reRaiseEjercicio(),
      _allInEjercicio(),
      _accionCerradaEjercicio(),
      _accionLegalEjercicio(),
      _ordenDeAccionEjercicio(),
    ]),
  };

  /// Reordena [options] con una semilla derivada de [seedText] — la misma
  /// pregunta siempre cae en el mismo orden (estable entre sesiones), pero
  /// preguntas distintas caen en órdenes distintos, sin una posición
  /// siempre correcta. Mismo criterio que `_shuffledChoices` en
  /// `mentor_lesson.dart`, pero para `ExerciseChoice`/`InteractiveTableExercise`.
  static List<ExerciseChoice> _shuffled(
      String seedText, List<ExerciseChoice> options) {
    final seed =
        seedText.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);
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

  static TableSnapshot _stage({
    List<String> hero = const [],
    List<String> board = const [],
    int? villainSlot,
    List<String> villain = const [],
    bool villainFolded = false,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    int? toAct,
    double pot = 0,
  }) {
    return TableSnapshot(
      seats: [
        SeatState(
          slot: 0,
          label: '',
          isHero: true,
          cards: hero,
          betBb: bets[0] ?? 0,
          action: actions[0],
          toAct: toAct == 0,
        ),
        for (var i = 1; i < 6; i++)
          if (i == villainSlot)
            SeatState(
              slot: i,
              label: '',
              cards: villain,
              folded: villainFolded,
              action: villainFolded ? 'FOLD' : actions[i],
              betBb: bets[i] ?? 0,
              toAct: toAct == i,
            )
          else
            SeatState.empty(i),
      ],
      board: board,
      potBb: pot,
      buttonSlot: 0,
    );
  }

  static const _hero = ['Ah', 'Ks'];

  // ================================================================
  // 1 — Cartas privadas
  // ================================================================
  static InteractiveTableExercise _cartasPrivadas() {
    return InteractiveTableExercise(
      situation: _stage(hero: _hero),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: '¿Cuántas cartas privadas recibe cada jugador?',
      choices: const [
        ExerciseChoice(
          label: '2',
          rating: ExerciseRating.best,
          feedback: 'Exacto: cada jugador recibe 2 cartas privadas, boca '
              'abajo, que solo él puede ver.',
        ),
        ExerciseChoice(
          label: '1',
          rating: ExerciseRating.poor,
          feedback: 'No: son 2, no 1. Mirá tus cartas arriba — son un par.',
        ),
        ExerciseChoice(
          label: '5',
          rating: ExerciseRating.poor,
          feedback: '5 son las cartas comunitarias, no las privadas. Las '
              'privadas de cada jugador son 2.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '2 cartas privadas por jugador: las tuyas solo las ves vos.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 2 — Etapa: el flop
  // ================================================================
  static InteractiveTableExercise _etapaFlop() {
    return InteractiveTableExercise(
      situation: _stage(hero: _hero, board: const ['Qd', '8s', '3c']),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: 'Acaban de aparecer 3 cartas comunitarias juntas en el '
          'centro. ¿En qué etapa estamos?',
      choices: const [
        ExerciseChoice(
          label: 'EL FLOP',
          rating: ExerciseRating.best,
          feedback: 'Correcto: las primeras 3 cartas comunitarias, todas '
              'juntas, son el flop.',
        ),
        ExerciseChoice(
          label: 'EL TURN',
          rating: ExerciseRating.poor,
          feedback: 'El turn es una sola carta, y sale después. Estas 3 '
              'juntas son el flop.',
        ),
        ExerciseChoice(
          label: 'EL RIVER',
          rating: ExerciseRating.poor,
          feedback: 'El river es la última carta, la 5ª. Acá recién van 3.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '3 cartas comunitarias juntas, de entrada: eso es siempre '
              'el flop.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 3 — Qué carta acaba de aparecer (el turn)
  // ================================================================
  static InteractiveTableExercise _cartaDelTurn() {
    return InteractiveTableExercise(
      situation: _stage(hero: _hero, board: const ['Qd', '8s', '3c', 'Th']),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: 'El board pasó de 3 a 4 cartas comunitarias. ¿Cómo se '
          'llama la carta que acaba de aparecer?',
      choices: const [
        ExerciseChoice(
          label: 'EL TURN',
          rating: ExerciseRating.best,
          feedback: 'Exacto: la 4ª carta comunitaria, la que sale sola '
              'después del flop, es el turn.',
        ),
        ExerciseChoice(
          label: 'EL FLOP',
          rating: ExerciseRating.poor,
          feedback: 'El flop ya pasó: fueron las primeras 3 juntas. Esta es '
              'una carta nueva, la 4ª.',
        ),
        ExerciseChoice(
          label: 'EL RIVER',
          rating: ExerciseRating.poor,
          feedback: 'El river es la 5ª y última carta. Todavía falta una '
              'más para llegar ahí.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Flop (3) → turn (1) → river (1). Esta 4ª carta, sola, es '
              'el turn.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 4 — Total de comunitarias
  // ================================================================
  static InteractiveTableExercise _totalComunitarias() {
    return InteractiveTableExercise(
      situation:
          _stage(hero: _hero, board: const ['Qd', '8s', '3c', 'Th', '4h']),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: 'Ya salieron todas. ¿Cuántas cartas comunitarias hay en '
          'total, contando las 3 del flop?',
      choices: const [
        ExerciseChoice(
          label: '5',
          rating: ExerciseRating.best,
          feedback: 'Correcto: 3 (flop) + 1 (turn) + 1 (river) = 5 cartas '
              'comunitarias en total.',
        ),
        ExerciseChoice(
          label: '7',
          rating: ExerciseRating.poor,
          feedback: '7 es el total de cartas DISPONIBLES contando tus 2 '
              'privadas. Las comunitarias, solas, son 5.',
        ),
        ExerciseChoice(
          label: '3',
          rating: ExerciseRating.poor,
          feedback: '3 son solo las del flop. Contá también el turn y el '
              'river.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '3 + 1 + 1 = 5 cartas comunitarias, siempre.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 5 — Las 7 cartas disponibles
  // ================================================================
  static InteractiveTableExercise _sieteDisponibles() {
    return InteractiveTableExercise(
      situation:
          _stage(hero: _hero, board: const ['Qd', '8s', '3c', 'Th', '4h']),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Contando tus 2 privadas y las 5 comunitarias, ¿cuántas '
          'cartas tenés disponibles en total?',
      choices: const [
        ExerciseChoice(
          label: '7',
          rating: ExerciseRating.best,
          feedback: 'Exacto: 2 privadas + 5 comunitarias = 7 cartas '
              'disponibles.',
        ),
        ExerciseChoice(
          label: '5',
          rating: ExerciseRating.poor,
          feedback: 'Esas son solo las comunitarias. Sumale tus 2 '
              'privadas: son 7 en total.',
        ),
        ExerciseChoice(
          label: '2',
          rating: ExerciseRating.poor,
          feedback: 'Esas son solo tus privadas. Sumale las 5 '
              'comunitarias: son 7 en total.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '2 + 5 = 7 cartas disponibles.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.board],
        ),
      ],
    );
  }

  // ================================================================
  // 6 — Cuántas forman la mano final
  // ================================================================
  static InteractiveTableExercise _manoFinalDeCinco() {
    return InteractiveTableExercise(
      situation:
          _stage(hero: _hero, board: const ['Qd', '8s', '3c', 'Th', '4h']),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'De esas 7 cartas disponibles, ¿cuántas forman tu mano '
          'final?',
      choices: const [
        ExerciseChoice(
          label: '5',
          rating: ExerciseRating.best,
          feedback: 'Correcto: tu mano final son siempre las 5 mejores de '
              'las 7 disponibles.',
        ),
        ExerciseChoice(
          label: '7',
          rating: ExerciseRating.poor,
          feedback: 'Tenés 7 disponibles, pero tu mano final nunca son 7: '
              'siempre se eligen las 5 mejores.',
        ),
        ExerciseChoice(
          label: '6',
          rating: ExerciseRating.poor,
          feedback: 'Tu mano final son exactamente 5 cartas, ni una más.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Siempre 5. Las otras 2, de las 7 disponibles, no cuentan '
              'para nada.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.board],
        ),
      ],
    );
  }

  // ================================================================
  // 7 — Cuáles son las mejores 5
  // ================================================================
  static InteractiveTableExercise _cualesCinco() {
    const hero = ['Ah', 'Ad'];
    const board = ['As', 'Kd', '9c', '7s', '2s'];
    return InteractiveTableExercise(
      situation: _stage(hero: hero, board: board),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Tenés A♥A♦, y el board terminó K♦9♣7♠2♠ con un As más '
          '(A♠). De estas 7 cartas, ¿cuáles son tus mejores 5?',
      choices: const [
        ExerciseChoice(
          label: 'A♥ A♦ A♠ K♦ 9♣',
          rating: ExerciseRating.best,
          feedback: 'Exacto: trío de ases (A♥A♦A♠) con K♦ y 9♣ '
              'acompañando. El 7♠ y el 2♠ sobran.',
        ),
        ExerciseChoice(
          label: 'Las 7 cartas juntas',
          rating: ExerciseRating.poor,
          feedback: 'Tu mano final nunca son 7: siempre son las 5 mejores.',
        ),
        ExerciseChoice(
          label: 'A♥ A♦ 7♠ 2♠ 9♣',
          rating: ExerciseRating.poor,
          feedback: 'Esas dejan afuera al A♠ del board, que sí forma parte '
              'de tu mejor combinación (trío de ases).',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'A♥ A♦ A♠ K♦ 9♣: esas 5 son tu mejor mano. El 7♠ y el 2♠, '
              'aunque estén en la mesa, no forman parte de nada mejor.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.board],
          table: TableSnapshot(
            seats: [
              SeatState(slot: 0, label: '', isHero: true, cards: hero),
              SeatState.empty(1),
              SeatState.empty(2),
              SeatState.empty(3),
              SeatState.empty(4),
              SeatState.empty(5),
            ],
            board: board,
            buttonSlot: 0,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // 8 — Los 4 palos valen igual
  // ================================================================
  static InteractiveTableExercise _losPalosValenIgual() {
    return InteractiveTableExercise(
      situation: _stage(hero: const ['Kd', 'Kh'], board: const ['Ks', 'Kc']),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Mirá estas 4 cartas: mismo valor (K), los 4 palos '
          'distintos. ¿Cuál de estos palos es más fuerte?',
      choices: const [
        ExerciseChoice(
          label: 'NINGUNO — LOS 4 PALOS VALEN LO MISMO',
          rating: ExerciseRating.best,
          feedback: 'Correcto. Ningún palo le gana a otro, nunca: lo único '
              'que importa es el valor de la carta.',
        ),
        ExerciseChoice(
          label: 'PICAS',
          rating: ExerciseRating.poor,
          feedback: 'No en el póker: eso es de otros juegos. Acá los 4 '
              'palos son exactamente iguales.',
        ),
        ExerciseChoice(
          label: 'CORAZONES',
          rating: ExerciseRating.poor,
          feedback: 'No: ningún palo vale más que otro. Los 4 son '
              'exactamente iguales.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Los 4 palos valen exactamente lo mismo. Nunca desempatan.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.board],
        ),
      ],
    );
  }

  // ================================================================
  // 1.2 — Ganar la mano
  // ================================================================

  static const _villainSlot = 3;
  static const _h2Hero = ['Ah', 'As'];
  static const _h2Board = ['Ad', 'Kd', '9c', '7s', '2s'];
  static const _h2Villain = ['Qc', 'Qd'];

  static InteractiveTableExercise _queEsShowdown() {
    const question = '¿Cómo se llama el momento en el que, al final de la '
        'mano, los jugadores que quedan (sin haberse retirado) muestran '
        'sus cartas para ver quién gana?';
    return InteractiveTableExercise(
      situation: _stage(hero: _h2Hero, board: _h2Board, villainSlot: _villainSlot),
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.pot],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'EL SHOWDOWN',
          rating: ExerciseRating.best,
          feedback: 'Exacto: showdown es exactamente eso — mostrar las '
              'cartas al final para ver quién gana.',
        ),
        ExerciseChoice(
          label: 'EL FLOP',
          rating: ExerciseRating.poor,
          feedback: 'El flop son las primeras 3 cartas comunitarias, no el '
              'momento de mostrar las cartas.',
        ),
        ExerciseChoice(
          label: 'LA CIEGA',
          rating: ExerciseRating.poor,
          feedback: 'La ciega es una apuesta obligatoria al principio de la '
              'mano. No tiene que ver con mostrar las cartas al final.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Showdown = se muestran las cartas al final, solo si al '
              'menos dos jugadores siguen en la mano sin retirarse.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _comoSeDecideElGanador() {
    const question = 'En el showdown, ¿qué se compara exactamente para '
        'decidir quién gana el bote?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: _h2Hero,
        board: _h2Board,
        villainSlot: _villainSlot,
        villain: _h2Villain,
      ),
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.seat(_villainSlot)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'LA MEJOR MANO DE 5 DE CADA JUGADOR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: se compara la mejor mano de 5 cartas de cada '
              'uno. La que vale más se lleva el bote.',
        ),
        ExerciseChoice(
          label: 'QUIÉN APOSTÓ MÁS EN TOTAL',
          rating: ExerciseRating.poor,
          feedback: 'No: cuánto apostó cada uno no entra en la comparación. '
              'Solo importa la mano.',
        ),
        ExerciseChoice(
          label: 'QUIÉN LLEGÓ ÚLTIMO A LA MESA',
          rating: ExerciseRating.poor,
          feedback: 'Eso no tiene nada que ver. En el showdown se comparan '
              'las manos, nada más.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Se muestran las cartas: se comparan las mejores manos de '
              '5, y la de mayor valor se lleva el bote entero.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _empateExacto() {
    const hero = ['Ah', 'Kd'];
    const villain = ['As', 'Kh'];
    const board = ['Qh', 'Jd', '9h', '4c', '2d'];
    const question = 'Dos jugadores llegan al showdown y, al mostrar las '
        'cartas, sus manos de 5 valen EXACTAMENTE lo mismo. ¿Qué pasa con '
        'el bote?';
    return InteractiveTableExercise(
      situation:
          _stage(hero: hero, board: board, villainSlot: _villainSlot, villain: villain),
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.seat(_villainSlot)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'SE REPARTE ENTRE LOS DOS',
          rating: ExerciseRating.best,
          feedback: 'Correcto: en un empate exacto, el bote se reparte '
              'entre los jugadores empatados, mitad y mitad.',
        ),
        ExerciseChoice(
          label: 'SE LO LLEVA EL QUE APOSTÓ PRIMERO',
          rating: ExerciseRating.poor,
          feedback: 'No: el orden de las apuestas no desempata nada. Un '
              'empate exacto siempre se reparte.',
        ),
        ExerciseChoice(
          label: 'NO SE PUEDE EMPATAR, SIEMPRE HAY UN GANADOR',
          rating: ExerciseRating.poor,
          feedback: 'Sí se puede: cuando las dos manos de 5 valen '
              'exactamente lo mismo, es un empate real y el bote se '
              'reparte.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Empate exacto = bote repartido entre los empatados.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _apostarMasNoDecide() {
    const question = 'En este showdown, el rival apostó bastante más '
        'fichas que vos durante toda la mano. ¿Alcanza eso para que gane '
        'el bote?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: _h2Hero,
        board: _h2Board,
        villainSlot: _villainSlot,
        villain: _h2Villain,
        bets: const {0: 3, _villainSlot: 9},
      ),
      questionAnchor: const TableAnchor.seat(_villainSlot),
      situationHighlight: const [
        TableAnchor.bet(_villainSlot),
        TableAnchor.heroCards,
        TableAnchor.seat(_villainSlot),
      ],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'NO — GANA LA MEJOR MANO DE 5, SIN IMPORTAR QUIÉN APOSTÓ MÁS',
          rating: ExerciseRating.best,
          feedback: 'Exacto. Apostar más no gana nada por sí solo: en el '
              'showdown decide únicamente la mano.',
        ),
        ExerciseChoice(
          label: 'SÍ — QUIEN APOSTÓ MÁS SIEMPRE GANA EL SHOWDOWN',
          rating: ExerciseRating.poor,
          feedback: 'No: cuánto apostó cada uno no entra en la comparación '
              'del showdown. Solo importa la mano.',
        ),
        ExerciseChoice(
          label: 'SE REPARTE, POR HABER APOSTADO DISTINTO',
          rating: ExerciseRating.poor,
          feedback: 'No: el bote solo se reparte si las manos empatan '
              'exactamente. Apostar distinto no genera un reparto.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Apostar más no determina quién gana. Si se llega al '
              'showdown, gana la mejor mano de 5.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _ganarPorFold() {
    const board = ['Jc', '8h', '3d'];
    const question = 'Apostaste, y el rival decidió no pagar: se retiró. '
        '¿Qué pasa ahora?';
    return InteractiveTableExercise(
      situation: _stage(
        board: board,
        villainSlot: _villainSlot,
        villainFolded: true,
      ),
      questionAnchor: const TableAnchor.seat(_villainSlot),
      situationHighlight: const [TableAnchor.seat(_villainSlot)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'GANÁS EL BOTE, SIN MOSTRAR TUS CARTAS',
          rating: ExerciseRating.best,
          feedback: 'Correcto: si el rival se retira, la mano termina ahí '
              'mismo y te llevás el bote sin que nadie vea tus cartas.',
        ),
        ExerciseChoice(
          label: 'TENÉS QUE MOSTRAR TUS CARTAS IGUAL',
          rating: ExerciseRating.poor,
          feedback: 'No: si todos los demás se retiran, no hay showdown. '
              'Tus cartas no se muestran.',
        ),
        ExerciseChoice(
          label: 'LA MANO SIGUE EN LA SIGUIENTE CALLE',
          rating: ExerciseRating.poor,
          feedback: 'No: en cuanto se retira el último rival que quedaba, '
              'la mano termina ahí — no sigue a la próxima carta.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Ganar por fold: todos los demás se retiran, la mano '
              'termina y el bote es tuyo sin mostrar nada.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _noHaceFaltaLaMejorMano() {
    const board = ['Jc', '8h', '3d'];
    const question = 'Para ganar el bote de esa forma —porque el rival se '
        'retiró— ¿hace falta tener la mejor mano?';
    return InteractiveTableExercise(
      situation: _stage(
        board: board,
        villainSlot: _villainSlot,
        villainFolded: true,
      ),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.seat(_villainSlot)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'NO, NO HACE FALTA',
          rating: ExerciseRating.best,
          feedback: 'Exacto: ganar por fold no depende de tus cartas. '
              'Podés ganar el bote con cualquier mano, si el rival se '
              'retira.',
        ),
        ExerciseChoice(
          label: 'SÍ, SIEMPRE HACE FALTA LA MEJOR MANO',
          rating: ExerciseRating.poor,
          feedback: 'No: esa es la otra forma de ganar (por cartas). Por '
              'fold, no hace falta tener nada.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Ganar por fold no depende de la mano: depende de que los '
              'demás se retiren.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 1.3 — Las acciones
  // ================================================================

  static const _h3Board = ['Jc', '8h', '3d'];

  static InteractiveTableExercise _foldEjercicio() {
    const question = 'Tenés 9♦4♣, una mano floja, y no querés poner ni una '
        'ficha más. ¿Qué acción es esta?';
    return InteractiveTableExercise(
      situation: _stage(hero: const ['9d', '4c']),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'FOLD',
          rating: ExerciseRating.best,
          feedback: 'Correcto: soltar las cartas y abandonar la mano es '
              'foldear.',
        ),
        ExerciseChoice(
          label: 'CHECK',
          rating: ExerciseRating.poor,
          feedback: 'Check es pasar SIN abandonar la mano. Acá estás '
              'soltando las cartas: eso es fold.',
        ),
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.poor,
          feedback: 'Call es pagar una apuesta para seguir en la mano. Acá '
              'te estás retirando, no pagando.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Fold = abandonar la mano. Lo que ya hayas puesto antes '
              'queda en el bote; no ponés nada más.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  static InteractiveTableExercise _checkEjercicio() {
    const question = 'Nadie apostó todavía en esta ronda y vos no querés '
        'poner fichas. ¿Qué hacés?';
    return InteractiveTableExercise(
      situation: _stage(hero: const ['Ah', 'Qd'], board: _h3Board),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'CHECK',
          rating: ExerciseRating.best,
          feedback: 'Exacto: check es pasar sin apostar cuando no hay '
              'apuesta delante. Seguís en la mano gratis.',
        ),
        ExerciseChoice(
          label: 'FOLD',
          rating: ExerciseRating.poor,
          feedback: 'Foldear acá tiraría la mano gratis, sin necesidad: '
              'nadie te está cobrando nada.',
        ),
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.poor,
          feedback: 'No hay ninguna apuesta que igualar: call no es una '
              'opción todavía.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Check solo existe cuando nadie apostó antes que vos en '
              'esa ronda.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  static InteractiveTableExercise _callEjercicio() {
    const question = 'El rival apostó 4 BB. Querés seguir en la mano SIN '
        'subir. ¿Qué hacés?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: const ['Ah', 'Qd'],
        board: _h3Board,
        villainSlot: _villainSlot,
        bets: const {_villainSlot: 4},
        actions: const {_villainSlot: 'APUESTA'},
        pot: 6,
      ),
      questionAnchor: const TableAnchor.bet(_villainSlot),
      situationHighlight: const [TableAnchor.bet(_villainSlot), TableAnchor.heroCards],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.best,
          feedback: 'Correcto: call es igualar la apuesta del rival para '
              'seguir en la mano sin subir.',
        ),
        ExerciseChoice(
          label: 'CHECK',
          rating: ExerciseRating.poor,
          feedback: 'Check ya no es una opción: hay una apuesta delante '
              'tuyo.',
        ),
        ExerciseChoice(
          label: 'RAISE',
          rating: ExerciseRating.poor,
          feedback: 'Raise sería poner MÁS que esos 4 BB. Vos querías '
              'seguir sin subir: eso es call.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Con una apuesta delante: fold, call (igualar) o raise '
              '(subir).',
          anchor: TableAnchor.bet(_villainSlot),
        ),
      ],
    );
  }

  static InteractiveTableExercise _betEjercicio() {
    const question = 'Nadie apostó todavía en esta ronda y vos ponés fichas '
        'primero. ¿Cómo se llama esa acción?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: const ['Kc', 'Kd'],
        board: _h3Board,
        bets: const {0: 5},
        actions: const {0: 'APUESTA'},
        pot: 5,
      ),
      questionAnchor: const TableAnchor.bet(0),
      situationHighlight: const [TableAnchor.bet(0)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'BET',
          rating: ExerciseRating.best,
          feedback: 'Exacto: ser el primero en poner fichas en una ronda es '
              'bet, apostar.',
        ),
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.poor,
          feedback: 'Call es igualar una apuesta que YA existe. Acá no '
              'había ninguna todavía.',
        ),
        ExerciseChoice(
          label: 'RAISE',
          rating: ExerciseRating.poor,
          feedback: 'Raise es subir una apuesta que ya está en la mesa. '
              'Acá no había ninguna: sos el primero en apostar.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Bet = ser el primero en poner fichas en la ronda.',
          anchor: TableAnchor.bet(0),
        ),
      ],
    );
  }

  static InteractiveTableExercise _raiseEjercicio() {
    const question = 'El rival apostó 3 BB. Vos ponés 9 BB, más que esa '
        'apuesta. ¿Cómo se llama esa acción?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: const ['Kc', 'Kd'],
        board: _h3Board,
        villainSlot: _villainSlot,
        bets: const {_villainSlot: 3, 0: 9},
        actions: const {_villainSlot: 'APUESTA', 0: 'SUBE'},
        pot: 12,
      ),
      questionAnchor: const TableAnchor.bet(0),
      situationHighlight: const [TableAnchor.bet(_villainSlot), TableAnchor.bet(0)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'RAISE',
          rating: ExerciseRating.best,
          feedback: 'Correcto: poner más fichas que la apuesta que ya '
              'estaba en la mesa es raise, subir.',
        ),
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.poor,
          feedback: 'Call sería igualar esos 3 BB, sin poner más. Acá '
              'pusiste 9: eso es subir.',
        ),
        ExerciseChoice(
          label: 'BET',
          rating: ExerciseRating.poor,
          feedback: 'Bet es ser el primero en apostar. Acá el rival ya '
              'había apostado antes: lo que hacés vos es subir esa '
              'apuesta.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Raise = subir una apuesta que ya está sobre la mesa.',
          anchor: TableAnchor.bet(0),
        ),
      ],
    );
  }

  static InteractiveTableExercise _reRaiseEjercicio() {
    const question = 'El rival ya había subido una apuesta (a 9 BB). Vos '
        'volvés a subir por encima de esa subida (a 27 BB). ¿Cómo se llama '
        'esto?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: const ['As', 'Ad'],
        villainSlot: _villainSlot,
        bets: const {_villainSlot: 9, 0: 27},
        actions: const {_villainSlot: 'SUBE', 0: 'SUBE'},
        pot: 39,
      ),
      questionAnchor: const TableAnchor.bet(0),
      situationHighlight: const [TableAnchor.bet(_villainSlot), TableAnchor.bet(0)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'UN RE-RAISE',
          rating: ExerciseRating.best,
          feedback: 'Exacto: subir por encima de una subida ya existente es '
              'un re-raise.',
        ),
        ExerciseChoice(
          label: 'UN BET NORMAL',
          rating: ExerciseRating.poor,
          feedback: 'Bet es ser el primero en apostar en la ronda. Acá ya '
              'había dos subidas antes.',
        ),
        ExerciseChoice(
          label: 'UN ALL-IN',
          rating: ExerciseRating.poor,
          feedback: 'All-in es apostar todas tus fichas de una vez. Acá no '
              'sabemos si es todo tu stack: lo que sí sabemos es que es una '
              'subida sobre otra subida.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Re-raise = subir sobre una subida.',
          anchor: TableAnchor.bet(0),
        ),
      ],
    );
  }

  static InteractiveTableExercise _allInEjercicio() {
    const question = 'Ponés todas las fichas que tenés en la mesa, de una '
        'sola vez. ¿Cómo se llama esa jugada?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: const ['As', 'Kd'],
        bets: const {0: 100},
        actions: const {0: 'ALL-IN'},
        pot: 100,
      ),
      questionAnchor: const TableAnchor.bet(0),
      situationHighlight: const [TableAnchor.bet(0)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'ALL-IN',
          rating: ExerciseRating.best,
          feedback: 'Correcto: apostar todo tu stack de una sola vez es ir '
              'all-in. Es la apuesta más grande posible.',
        ),
        ExerciseChoice(
          label: 'UN RAISE CUALQUIERA',
          rating: ExerciseRating.acceptable,
          feedback: 'Técnicamente estás subiendo, sí — pero cuando ponés '
              'TODO tu stack, esa jugada tiene nombre propio: all-in.',
        ),
        ExerciseChoice(
          label: 'UN CALL GRANDE',
          rating: ExerciseRating.poor,
          feedback: 'Call es igualar una apuesta existente. Acá no hay '
              'ninguna apuesta previa: sos vos poniendo todo de una.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'All-in = todas tus fichas, de una vez. Nunca podés perder '
              'más de lo que tenés en la mesa.',
          anchor: TableAnchor.bet(0),
        ),
      ],
    );
  }

  static InteractiveTableExercise _accionCerradaEjercicio() {
    const question = 'Vos apostaste 5 BB y el rival pagó esos mismos 5 BB. '
        'No queda nadie más por hablar. ¿Qué pasa ahora?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: const ['Kc', 'Kd'],
        board: _h3Board,
        villainSlot: _villainSlot,
        bets: const {_villainSlot: 5, 0: 5},
        actions: const {_villainSlot: 'PAGA', 0: 'APUESTA'},
        pot: 15,
      ),
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.pot],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'LA RONDA SE CIERRA Y SALE LA PRÓXIMA CARTA',
          rating: ExerciseRating.best,
          feedback: 'Exacto: cuando todos los que siguen en la mano '
              'igualaron la última apuesta, la acción está cerrada.',
        ),
        ExerciseChoice(
          label: 'SE VUELVE A REPARTIR TODO',
          rating: ExerciseRating.poor,
          feedback: 'No: la mano sigue su curso normal. Solo cambia que '
              'ahora sale la próxima carta.',
        ),
        ExerciseChoice(
          label: 'TENÉS QUE APOSTAR DE NUEVO',
          rating: ExerciseRating.poor,
          feedback: 'No: la ronda ya está cerrada, nadie tiene que volver a '
              'actuar en esta calle.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'La ronda se cierra cuando todos los que siguen en la mano '
              'igualaron o pasaron.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _accionLegalEjercicio() {
    const question = 'No hay ninguna apuesta delante tuyo en esta ronda. '
        '¿Cuáles son tus opciones?';
    return InteractiveTableExercise(
      situation: _stage(hero: const ['Th', '9h'], board: _h3Board),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'CHECK O BET',
          rating: ExerciseRating.best,
          feedback: 'Correcto: sin apuesta delante, tus opciones son check '
              '(pasar) o bet (apostar).',
        ),
        ExerciseChoice(
          label: 'FOLD, CALL O RAISE',
          rating: ExerciseRating.poor,
          feedback: 'Esas son las opciones cuando SÍ hay una apuesta '
              'delante. Acá no hay ninguna.',
        ),
        ExerciseChoice(
          label: 'SOLO CHECK',
          rating: ExerciseRating.poor,
          feedback: 'Check es una opción, pero no la única: también podés '
              'apostar (bet) si querés.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Sin apuesta delante: check o bet. Con apuesta delante: '
              'fold, call o raise.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  static InteractiveTableExercise _ordenDeAccionEjercicio() {
    const question = 'En una ronda, ¿pueden dos jugadores hablar al mismo '
        'tiempo, o se actúa de a uno en un orden fijo?';
    return InteractiveTableExercise(
      situation: _stage(
        hero: const ['Th', '9h'],
        board: _h3Board,
        villainSlot: _villainSlot,
        toAct: 0,
      ),
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.seat(0), TableAnchor.seat(_villainSlot)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'SE ACTÚA DE A UNO, EN ORDEN FIJO',
          rating: ExerciseRating.best,
          feedback: 'Exacto: en cada ronda se habla de a uno, siempre en el '
              'mismo sentido alrededor de la mesa.',
        ),
        ExerciseChoice(
          label: 'CUALQUIERA PUEDE HABLAR CUANDO QUIERE',
          rating: ExerciseRating.poor,
          feedback: 'No: el póker tiene un orden fijo. Nadie actúa fuera de '
              'su turno.',
        ),
        ExerciseChoice(
          label: 'HABLAN TODOS A LA VEZ Y SE VE QUÉ PASA',
          rating: ExerciseRating.poor,
          feedback: 'No: eso generaría confusión total. Se actúa de a uno, '
              'en un orden fijo.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Se actúa de a uno, en orden fijo, siempre en el mismo '
              'sentido alrededor de la mesa.',
          anchor: TableAnchor.seat(0),
          dimOthers: false,
        ),
      ],
    );
  }
}

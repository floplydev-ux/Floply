import 'dart:math' as math;

import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos del piloto de 3 bloques de los subniveles 1.1,
/// 1.2, 1.3 y 1.4 (Bloque C) — mesa + pregunta sobre lo que ya enseñaron
/// sus teorías.
///
/// 1.1: cartas privadas, comunitarias, flop/turn/river, las 7 disponibles y
/// las mejores 5. 1.2: showdown, empate exacto, que apostar más no decide, y
/// ganar por fold. 1.3: las 6 acciones (fold/check/call/bet/raise/re-raise),
/// all-in, acción cerrada, acción legal y orden de acción. 1.4: las 4
/// calles (preflop/flop/turn/river), que cada una tiene su propia ronda de
/// apuestas, que la información se acumula calle a calle, y las dos formas
/// de terminar una mano (fold o showdown) — consolidación de 1.1-1.3, sin
/// contenido nuevo. Ninguno usa ranking de manos (pareja, trío, etc.): eso
/// es Nivel 2. Las etiquetas de posición (BTN/SB/BB/…) sí aparecen en la
/// mesa de los 4 subniveles (pedido explícito del usuario) aunque el
/// NOMBRE de cada posición recién se enseña formalmente en Nivel 3 — es
/// una etiqueta visual de la mesa, no un concepto que la pregunta evalúe.
/// Las opciones se muestran en orden aleatorio (semilla derivada de la
/// pregunta, igual que `MentorLessonBuilder.ask` en `mentor_lesson.dart`):
/// la respuesta correcta no siempre es la primera.
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
    '1.4': InteractiveExerciseSet([
      _quePasaEnElPreflop(),
      _identificarElFlop(),
      _identificarElTurn(),
      _identificarElRiver(),
      _cuantasRondasDeApuestas(),
      _laInformacionSeAcumula(),
      _comoTerminaLaMano(),
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

  /// Mesa de 6 jugadores para los ejercicios de 1.1/1.2/1.3 (reutiliza
  /// [TableBuilder], igual que los ejemplos de cierre — no un sistema
  /// nuevo). SB/BB/UTG/HJ/CO siempre presentes y etiquetados aunque no
  /// participen del ejercicio puntual (`villainSlot: -1` cuando no hay un
  /// segundo jugador con rol propio en la pregunta).
  ///
  /// [heroStack]/[villainStack]/[pot] son `null` por defecto: si no se
  /// pasan, se calculan solos a partir de [bets] (100 BB menos lo que ese
  /// asiento puso; el bote, la suma de lo que hay sobre la mesa) — así un
  /// ejercicio que muestra fichas apostadas nunca puede quedar con un
  /// stack de 100 BB fijo "de regalo". Pasarlos explícitos (como en las
  /// manos encadenadas de 1.1/1.2, con bote ya sweepeado) los pisa sin
  /// problema.
  static TableSnapshot _stage6({
    List<String> hero = const [],
    List<String> board = const [],
    int villainSlot = _villainSlot,
    List<String> villain = const [],
    bool villainFolded = false,
    bool othersDealt = true,
    bool othersFolded = true,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    int? toAct,
    double? heroStack,
    double? villainStack,
    double? pot,
  }) {
    final background = {
      for (var i = 1; i < 6; i++)
        if (i != villainSlot) i,
    };
    return TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        bets: bets,
        actions: actions,
        cards: {
          0: hero,
          villainSlot: villain,
          for (final i in background) i: othersDealt ? const ['?', '?'] : const [],
        },
        stacks: {
          0: heroStack ?? (100 - (bets[0] ?? 0)),
          villainSlot: villainStack ?? (100 - (bets[villainSlot] ?? 0)),
        },
        folded: {
          if (villainFolded) villainSlot,
          if (othersFolded) ...background,
        },
        toAct: toAct,
      ),
      board: board,
      potBb: pot ?? bets.values.fold(0.0, (a, b) => a + b),
      buttonSlot: 0,
    );
  }

  static const _hero = ['Ah', 'Ks'];

  // ================================================================
  // 1 — Cartas privadas
  // ================================================================
  static InteractiveTableExercise _cartasPrivadas() {
    const question = '¿Cuántas cartas privadas recibe cada jugador?';
    return InteractiveTableExercise(
      situation: _stage6(hero: _hero, villainSlot: -1),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
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
    const question = 'Acaban de aparecer 3 cartas comunitarias juntas en el '
        'centro. ¿En qué etapa estamos?';
    return InteractiveTableExercise(
      situation: _stage6(hero: _hero, board: const ['Qd', '8s', '3c'], villainSlot: -1),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
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
    const question = 'El board pasó de 3 a 4 cartas comunitarias. ¿Cómo se '
        'llama la carta que acaba de aparecer?';
    return InteractiveTableExercise(
      situation:
          _stage6(hero: _hero, board: const ['Qd', '8s', '3c', 'Th'], villainSlot: -1),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
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
    const question = 'Ya salieron todas. ¿Cuántas cartas comunitarias hay en '
        'total, contando las 3 del flop?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: _hero,
        board: const ['Qd', '8s', '3c', 'Th', '4h'],
        villainSlot: -1,
      ),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
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
    const question = 'Contando tus 2 privadas y las 5 comunitarias, ¿cuántas '
        'cartas tenés disponibles en total?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: _hero,
        board: const ['Qd', '8s', '3c', 'Th', '4h'],
        villainSlot: -1,
      ),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
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
    const question = 'De esas 7 cartas disponibles, ¿cuántas forman tu mano '
        'final?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: _hero,
        board: const ['Qd', '8s', '3c', 'Th', '4h'],
        villainSlot: -1,
      ),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
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
    const question = 'Tenés A♥A♦, y el board terminó K♦9♣7♠2♠ con un As más '
        '(A♠). De estas 7 cartas, ¿cuáles son tus mejores 5?';
    return InteractiveTableExercise(
      situation: _stage6(hero: hero, board: board, villainSlot: -1),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
      explanation: [
        ExerciseExplainStep(
          text: 'A♥ A♦ A♠ K♦ 9♣: esas 5 son tu mejor mano. El 7♠ y el 2♠, '
              'aunque estén en la mesa, no forman parte de nada mejor.',
          anchor: TableAnchor.heroCards,
          highlight: const [TableAnchor.heroCards, TableAnchor.board],
          table: _stage6(hero: hero, board: board, villainSlot: -1),
        ),
      ],
    );
  }

  // ================================================================
  // 8 — Los 4 palos valen igual
  // ================================================================
  static InteractiveTableExercise _losPalosValenIgual() {
    const question = 'Mirá estas 4 cartas: mismo valor (K), los 4 palos '
        'distintos. ¿Cuál de estos palos es más fuerte?';
    return InteractiveTableExercise(
      situation:
          _stage6(hero: const ['Kd', 'Kh'], board: const ['Ks', 'Kc'], villainSlot: -1),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
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
      ]),
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
      situation: _stage6(
        hero: _h2Hero,
        board: _h2Board,
        villain: const ['?', '?'],
        pot: 18,
        heroStack: 91,
        villainStack: 91,
      ),
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
      situation: _stage6(
        hero: _h2Hero,
        board: _h2Board,
        villain: _h2Villain,
        pot: 18,
        heroStack: 91,
        villainStack: 91,
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
      situation: _stage6(
        hero: hero,
        board: board,
        villain: villain,
        pot: 14,
        heroStack: 93,
        villainStack: 93,
      ),
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
    const question = 'Durante la mano, el rival apostó fuerte en varias '
        'calles y vos pagaste esas apuestas para seguir viéndolo. Llegan '
        'los dos al showdown. ¿Alcanza con haber apostado fuerte para '
        'ganar el bote?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: _h2Hero,
        board: _h2Board,
        villain: _h2Villain,
        pot: 18,
        heroStack: 91,
        villainStack: 91,
      ),
      questionAnchor: const TableAnchor.seat(_villainSlot),
      situationHighlight: const [
        TableAnchor.heroCards,
        TableAnchor.seat(_villainSlot),
      ],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'NO — EN EL SHOWDOWN GANA LA MEJOR MANO DE 5, SIN IMPORTAR '
              'QUIÉN APOSTÓ MÁS FUERTE',
          rating: ExerciseRating.best,
          feedback: 'Exacto. Para llegar los dos al showdown, cada apuesta '
              'tuvo que ser pagada — apostar fuerte no te hace ganar por sí '
              'solo: en el showdown decide únicamente la mano.',
        ),
        ExerciseChoice(
          label: 'SÍ — EL QUE APUESTA MÁS FUERTE GANA EL SHOWDOWN',
          rating: ExerciseRating.poor,
          feedback: 'No: en el showdown no importa quién apostó más fuerte '
              'durante la mano. Solo se compara la mejor mano de 5 de cada '
              'uno.',
        ),
        ExerciseChoice(
          label: 'SE REPARTE, POR HABER APOSTADO DISTINTO',
          rating: ExerciseRating.poor,
          feedback: 'No: el bote solo se reparte si las manos empatan '
              'exactamente. Que las apuestas hayan sido de distinto tamaño '
              'en el camino no genera un reparto.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Apostar fuerte no determina quién gana. Si los dos llegan '
              'al showdown, gana la mejor mano de 5.',
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
      situation: _stage6(
        hero: const ['?', '?'],
        board: board,
        villainFolded: true,
        pot: 10,
        heroStack: 95,
        villainStack: 95,
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
      situation: _stage6(
        hero: const ['?', '?'],
        board: board,
        villainFolded: true,
        pot: 10,
        heroStack: 95,
        villainStack: 95,
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
      situation: _stage6(hero: const ['9d', '4c'], villainSlot: -1),
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
      situation: _stage6(hero: const ['Ah', 'Qd'], board: _h3Board, villainSlot: -1),
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
      situation: _stage6(
        hero: const ['Ah', 'Qd'],
        board: _h3Board,
        bets: const {_villainSlot: 4},
        actions: const {_villainSlot: 'APUESTA'},
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
      situation: _stage6(
        hero: const ['Kc', 'Kd'],
        board: _h3Board,
        villainSlot: -1,
        bets: const {0: 5},
        actions: const {0: 'APUESTA'},
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
      situation: _stage6(
        hero: const ['Kc', 'Kd'],
        board: _h3Board,
        bets: const {_villainSlot: 3, 0: 9},
        actions: const {_villainSlot: 'APUESTA', 0: 'SUBE'},
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
      situation: _stage6(
        hero: const ['As', 'Ad'],
        bets: const {_villainSlot: 9, 0: 27},
        actions: const {_villainSlot: 'SUBE', 0: 'SUBE'},
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
      situation: _stage6(
        hero: const ['As', 'Kd'],
        villainSlot: -1,
        bets: const {0: 100},
        actions: const {0: 'ALL-IN'},
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
      situation: _stage6(
        hero: const ['Kc', 'Kd'],
        board: _h3Board,
        bets: const {_villainSlot: 5, 0: 5},
        actions: const {_villainSlot: 'PAGA', 0: 'APUESTA'},
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
      situation: _stage6(hero: const ['Th', '9h'], board: _h3Board, villainSlot: -1),
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
      situation: _stage6(
        hero: const ['Th', '9h'],
        board: _h3Board,
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

  // ================================================================
  // 1.4 — Las cuatro calles (consolidación de 1.1-1.3)
  // ================================================================

  static const _c4VillainSlot = 4; // BB, mismo rival del ejemplo de cierre.

  static InteractiveTableExercise _quePasaEnElPreflop() {
    const question = 'No salió ninguna carta comunitaria todavía, pero ya '
        'hay fichas en el bote (las ciegas). ¿En qué ronda estás?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: const ['As', 'Ks'],
        villainSlot: _c4VillainSlot,
        villainStack: 99,
        pot: 1.5,
      ),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.pot],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'EL PREFLOP',
          rating: ExerciseRating.best,
          feedback: 'Exacto: sin ninguna carta comunitaria todavía, solo '
              'tus 2 privadas, es el preflop — la primera ronda.',
        ),
        ExerciseChoice(
          label: 'EL FLOP',
          rating: ExerciseRating.poor,
          feedback: 'El flop ya tiene 3 cartas comunitarias en el centro. '
              'Acá todavía no salió ninguna.',
        ),
        ExerciseChoice(
          label: 'EL SHOWDOWN',
          rating: ExerciseRating.poor,
          feedback: 'El showdown es el final, mostrando cartas. Esto es '
              'el arranque de la mano.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Preflop = primera ronda, solo tus 2 privadas, sin ninguna '
              'carta comunitaria.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  static InteractiveTableExercise _identificarElFlop() {
    const question = 'El board tiene 3 cartas comunitarias, todas juntas, '
        'recién abiertas. ¿Qué calle es esta?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: const ['As', 'Ks'],
        board: const ['Kd', '7h', '2c'],
        villainSlot: -1,
      ),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'EL FLOP',
          rating: ExerciseRating.best,
          feedback: 'Correcto: las primeras 3 cartas comunitarias juntas '
              'son el flop.',
        ),
        ExerciseChoice(
          label: 'EL PREFLOP',
          rating: ExerciseRating.poor,
          feedback: 'En el preflop todavía no hay ninguna carta '
              'comunitaria. Acá ya hay 3.',
        ),
        ExerciseChoice(
          label: 'EL TURN',
          rating: ExerciseRating.poor,
          feedback: 'El turn es 1 sola carta, y sale después del flop. '
              'Acá son 3 juntas: eso es el flop.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Flop = las primeras 3 cartas comunitarias, siempre '
              'juntas.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  static InteractiveTableExercise _identificarElTurn() {
    const question = 'El board pasó de 3 a 4 cartas comunitarias: salió '
        'una sola carta más. ¿Qué calle es esta?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: const ['As', 'Ks'],
        board: const ['Kd', '7h', '2c', '9s'],
        villainSlot: -1,
      ),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'EL TURN',
          rating: ExerciseRating.best,
          feedback: 'Exacto: la 4ª carta comunitaria, sola, es el turn.',
        ),
        ExerciseChoice(
          label: 'EL FLOP',
          rating: ExerciseRating.poor,
          feedback: 'El flop ya pasó: fueron las primeras 3, juntas. Esta '
              'es una carta nueva, la 4ª.',
        ),
        ExerciseChoice(
          label: 'EL RIVER',
          rating: ExerciseRating.poor,
          feedback: 'El river es la 5ª y última. Todavía falta una carta '
              'más para llegar ahí.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Preflop → flop (3) → turn (1) → river (1).',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  static InteractiveTableExercise _identificarElRiver() {
    const question = 'El board ya tiene las 5 cartas comunitarias. '
        '¿Cuántas cartas más van a salir en esta mano?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: const ['As', 'Ks'],
        board: const ['Kd', '7h', '2c', '9s', '4d'],
        villainSlot: -1,
      ),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'NINGUNA — YA SALIERON LAS 5',
          rating: ExerciseRating.best,
          feedback: 'Correcto: con 5 cartas comunitarias ya estás en el '
              'river. No viene ninguna más — tu mano ya es lo que es.',
        ),
        ExerciseChoice(
          label: 'UNA MÁS',
          rating: ExerciseRating.poor,
          feedback: 'No: 3 (flop) + 1 (turn) + 1 (river) ya son las 5. No '
              'queda ninguna carta comunitaria por salir.',
        ),
        ExerciseChoice(
          label: 'TRES MÁS',
          rating: ExerciseRating.poor,
          feedback: 'No: ya salieron las 5 cartas comunitarias que hay en '
              'total. No vuelve a salir un flop.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'River = la 5ª y última carta comunitaria. No viene nada '
              'más después.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  static InteractiveTableExercise _cuantasRondasDeApuestas() {
    const question = 'En una mano que llega hasta el final, una ronda de '
        'apuestas por calle. ¿Cuántas rondas de apuestas hay en total?';
    return InteractiveTableExercise(
      situation: _stage6(hero: const ['As', 'Ks'], villainSlot: -1),
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: '4',
          rating: ExerciseRating.best,
          feedback: 'Exacto: preflop, flop, turn y river — una ronda de '
              'apuestas por cada una de las 4 calles.',
        ),
        ExerciseChoice(
          label: '3',
          rating: ExerciseRating.poor,
          feedback: 'Te falta una: el preflop también es una ronda de '
              'apuestas propia, antes de que salga ninguna carta.',
        ),
        ExerciseChoice(
          label: '5',
          rating: ExerciseRating.poor,
          feedback: 'El showdown no es una ronda de apuestas: ahí ya no se '
              'apuesta más, solo se muestran las cartas. Son 4.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: '4 calles, 4 rondas de apuestas: preflop, flop, turn, '
              'river.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  static InteractiveTableExercise _laInformacionSeAcumula() {
    const question = 'Ya viste cómo apostó el rival en el flop, y ahora '
        'estás en el turn con una carta comunitaria más que antes. '
        'Comparado con el flop, ¿sabés más, menos o lo mismo sobre la '
        'mano del rival?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: const ['As', 'Ks'],
        board: const ['Kd', '7h', '2c', '9s'],
        villainSlot: _c4VillainSlot,
        bets: const {0: 4, _c4VillainSlot: 4},
        heroStack: 93,
        villainStack: 93,
        pot: 14.5,
      ),
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board, TableAnchor.seat(_c4VillainSlot)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'MÁS — CADA CALLE Y CADA ACCIÓN SUMAN INFORMACIÓN',
          rating: ExerciseRating.best,
          feedback: 'Correcto: la carta nueva y cómo apostó en el flop son '
              'datos que no tenías antes. Siempre sabés más, calle a '
              'calle, nunca menos.',
        ),
        ExerciseChoice(
          label: 'MENOS — CADA CALLE BORRA LO QUE SABÍAS ANTES',
          rating: ExerciseRating.poor,
          feedback: 'No: lo que aprendiste en el flop sigue valiendo. Se '
              'le suma la carta y la acción nuevas — no se pierde nada.',
        ),
        ExerciseChoice(
          label: 'LO MISMO — LAS CARTAS NUEVAS NO CAMBIAN NADA',
          rating: ExerciseRating.poor,
          feedback: 'No: una carta comunitaria más y una acción más del '
              'rival son información nueva. Nunca es exactamente lo '
              'mismo que antes.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'Cada carta y cada acción suman información. Actualizá tu '
              'lectura calle a calle.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  static InteractiveTableExercise _comoTerminaLaMano() {
    const question = 'Una mano de póker puede terminar de dos formas '
        'distintas. ¿Cuáles son?';
    return InteractiveTableExercise(
      situation: _stage6(
        hero: const ['As', 'Ks'],
        board: const ['Kd', '7h', '2c', '9s', '4d'],
        villainSlot: _c4VillainSlot,
        villain: const ['Qc', 'Qd'],
      ),
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.seat(_c4VillainSlot)],
      question: question,
      choices: _shuffled(question, const [
        ExerciseChoice(
          label: 'POR FOLD (se retiran todos menos uno) O POR SHOWDOWN '
              '(se muestran las cartas)',
          rating: ExerciseRating.best,
          feedback: 'Exacto: esas son las dos únicas formas. Por fold no '
              'hace falta mostrar nada; por showdown, se comparan las '
              'manos.',
        ),
        ExerciseChoice(
          label: 'SOLO POR SHOWDOWN — SIEMPRE HAY QUE MOSTRAR LAS CARTAS',
          rating: ExerciseRating.poor,
          feedback: 'No: si todos menos uno se retiran antes del final, la '
              'mano termina ahí y nadie muestra nada.',
        ),
        ExerciseChoice(
          label: 'SOLO POR FOLD — NUNCA SE LLEGA A MOSTRAR LAS CARTAS',
          rating: ExerciseRating.poor,
          feedback: 'No: si al menos dos llegan hasta el final del río, '
              'hay showdown y se comparan las manos.',
        ),
      ]),
      explanation: const [
        ExerciseExplainStep(
          text: 'La mano termina por fold o por showdown. Tené claro para '
              'cuál de las dos estás jugando.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }
}

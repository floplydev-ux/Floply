import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'script_builders.dart';

/// Ejercicios interactivos sobre la mesa — Nivel 1 (Fundamentos · reglas).
///
/// El alumno aprende las reglas tomando decisiones en situaciones reales,
/// no respondiendo preguntas abstractas. Concepto: `rules` (ya enseñado
/// desde 1.1), así que el acierto/fallo sí cuenta para el mastery.
class Level1Exercises {
  Level1Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '1.1': InteractiveExerciseSet([_howYouWin()]),
    '1.2': InteractiveExerciseSet([_potAmount(), _maxLoss(), _blindsPurpose()]),
    '1.3': InteractiveExerciseSet([_nextStreet(), _checkAction(), _callAction()]),
    '1.4': InteractiveExerciseSet([_handOpen(), _handFlop(), _handShowdown()]),
    '1.5': InteractiveExerciseSet([
      _evalPot(),
      _evalStreetOrder(),
      _evalCheck(),
      _evalWinByFold(),
      _evalBlinds(),
    ]),
  };

  static const _labels = TableScript.btnHero;
  static const _rules = ConceptIds.rules;

  // Mesa con ciegas puestas, sin acción todavía.
  static TableSnapshot _blindsTable({
    Map<int, List<String>> cards = const {},
    double pot = 1.5,
    int? toAct,
  }) =>
      TableSnapshot(
        seats: TableScript.seats(
          labels: _labels,
          bets: const {5: 0.5, 4: 1.0},
          actions: const {5: 'CIEGA', 4: 'CIEGA'},
          cards: cards,
          toAct: toAct,
        ),
        potBb: pot,
        buttonSlot: 0,
      );

  // Mesa heads-up postflop (héroe BTN vs BB).
  static TableSnapshot _flopTable({
    required List<String> board,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    Map<int, List<String>> cards = const {0: ['Ah', 'Kh']},
    double pot = 6.0,
    int? toAct,
  }) =>
      TableSnapshot(
        seats: TableScript.seats(
          labels: _labels,
          folded: const {3, 2, 1, 5},
          bets: bets,
          actions: actions,
          cards: cards,
          toAct: toAct,
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  // ================================================================
  // 1.1 — Cómo se gana
  // ================================================================
  static InteractiveTableExercise _howYouWin() {
    final table = _flopTable(
      board: const ['Ks', '7h', '2d', 'Qs', '3c'],
      cards: const {0: ['Kd', 'Kc'], 4: ['Ad', 'Jc']},
      pot: 5.5,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: _rules,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.pot],
      question: 'La mano llegó al showdown. ¿Cómo se decide quién gana el '
          'bote?',
      choices: const [
        ExerciseChoice(
          label: 'MEJOR MANO DE 5',
          rating: ExerciseRating.best,
          feedback: 'Exacto: se comparan las manos y la mejor combinación '
              'de 5 cartas se lleva el bote.',
        ),
        ExerciseChoice(
          label: 'QUIEN APOSTÓ MÁS',
          rating: ExerciseRating.poor,
          feedback: 'No: apostar más no gana la mano. Gana la mejor '
              'combinación de 5 cartas.',
        ),
        ExerciseChoice(
          label: 'SE REPARTE',
          rating: ExerciseRating.poor,
          feedback: 'Solo se reparte si hay empate exacto. Tu trío de reyes '
              'le gana a la carta alta de {BB}.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Tu trío de reyes vence a A♦J♣ (solo carta alta).',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards, TableAnchor.seat(4)],
        ),
        ExerciseExplainStep(
          text: 'También se gana antes del showdown: si todos foldean, el '
              'bote es tuyo sin mostrar cartas.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 1.2 — Stack, ciegas y bote
  // ================================================================
  static InteractiveTableExercise _potAmount() {
    return InteractiveTableExercise(
      situation: _blindsTable(),
      concept: _rules,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [
        TableAnchor.pot,
        TableAnchor.bet(5),
        TableAnchor.bet(4),
      ],
      question: 'Nadie subió todavía. ¿Cuánto hay en el bote ahora mismo?',
      choices: const [
        ExerciseChoice(
          label: '1,5 BB',
          rating: ExerciseRating.best,
          feedback: 'SB (0,5) + BB (1) = 1,5 BB antes de la primera '
              'decisión.',
        ),
        ExerciseChoice(
          label: '0,5 BB',
          rating: ExerciseRating.poor,
          feedback: 'Esa es solo la ciega chica. Falta sumar la ciega '
              'grande.',
        ),
        ExerciseChoice(
          label: '3 BB',
          rating: ExerciseRating.poor,
          feedback: 'Todavía nadie subió: solo están las dos ciegas, '
              '1,5 BB.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El bote arranca con las ciegas y va creciendo con cada '
              'apuesta.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _maxLoss() {
    return InteractiveTableExercise(
      situation: _blindsTable(cards: const {0: ['9s', '9d']}, toAct: 0),
      concept: _rules,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.seat(0)],
      question: 'Tu stack es de 100 BB. Vas all-in y perdés la mano. '
          '¿Cuánto perdés como máximo?',
      choices: const [
        ExerciseChoice(
          label: '100 BB (TU STACK)',
          rating: ExerciseRating.best,
          feedback: 'Solo arriesgás lo que tenés en la mesa: tu stack.',
        ),
        ExerciseChoice(
          label: '1 BB',
          rating: ExerciseRating.poor,
          feedback: 'Si vas all-in ponés en juego todo tu stack, no solo la '
              'ciega grande.',
        ),
        ExerciseChoice(
          label: 'TODO TU DINERO',
          rating: ExerciseRating.poor,
          feedback: 'Nunca podés perder más que las fichas que tenés en la '
              'mesa. Lo de afuera no entra en la mano.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El stack es tu límite: lo máximo que podés ganar o perder '
              'en una mano.',
          anchor: TableAnchor.seat(0),
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _blindsPurpose() {
    return InteractiveTableExercise(
      situation: _blindsTable(),
      concept: _rules,
      questionAnchor: const TableAnchor.bet(5),
      situationHighlight: const [TableAnchor.bet(5), TableAnchor.bet(4)],
      question: '¿Para qué sirven las ciegas obligatorias?',
      choices: const [
        ExerciseChoice(
          label: 'PARA QUE HAYA JUEGO',
          rating: ExerciseRating.best,
          feedback: 'Sin ciegas nadie estaría obligado a poner fichas y '
              'todos esperarían solo manos enormes.',
        ),
        ExerciseChoice(
          label: 'PREMIAN AL GANADOR',
          rating: ExerciseRating.poor,
          feedback: 'Las ciegas no son un premio: son un costo forzado que '
              'arranca el bote.',
        ),
        ExerciseChoice(
          label: 'PAGAN A LA CASA',
          rating: ExerciseRating.poor,
          feedback: 'Las ciegas van al bote de la mano, no a la casa.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Las ciegas obligan a que siempre haya algo en juego, mano '
              'tras mano.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 1.3 — Calles y acciones
  // ================================================================
  static InteractiveTableExercise _nextStreet() {
    return InteractiveTableExercise(
      situation: _flopTable(board: const ['Qd', '8s', '3c']),
      concept: _rules,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: 'El flop ya salió (3 cartas). ¿Qué calle viene ahora?',
      choices: const [
        ExerciseChoice(
          label: 'EL TURN',
          rating: ExerciseRating.best,
          feedback: 'Preflop → flop → turn → river. El turn es la 4ª carta '
              'comunitaria.',
        ),
        ExerciseChoice(
          label: 'EL RIVER',
          rating: ExerciseRating.poor,
          feedback: 'El river es la 5ª carta: viene después del turn, no '
              'ahora.',
        ),
        ExerciseChoice(
          label: 'EL PREFLOP',
          rating: ExerciseRating.poor,
          feedback: 'El preflop ya pasó: es antes del flop.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Orden fijo: preflop → flop → turn → river → showdown.',
          anchor: TableAnchor.board,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _checkAction() {
    final table = _flopTable(board: const ['Qd', '8s', '3c'], toAct: 0);
    return InteractiveTableExercise(
      situation: table,
      afterDecision: _flopTable(
        board: const ['Qd', '8s', '3c'],
        actions: const {0: 'PASA'},
      ),
      concept: _rules,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.seat(0)],
      question: 'Nadie apostó y vos no querés poner fichas. ¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'CHECK',
          rating: ExerciseRating.best,
          feedback: 'Check es pasar sin apostar cuando no hay apuesta '
              'delante. Seguís en la mano gratis.',
        ),
        ExerciseChoice(
          label: 'FOLD',
          rating: ExerciseRating.poor,
          feedback: 'Foldear acá sería tirar la mano gratis, sin necesidad: '
              'nadie te está cobrando.',
        ),
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.poor,
          feedback: 'No hay ninguna apuesta que igualar: no se puede hacer '
              'call.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Sin apuesta delante: check para pasar, o bet para apostar '
              'vos.',
          anchor: TableAnchor.seat(0),
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _callAction() {
    final table = _flopTable(
      board: const ['Qd', '8s', '3c'],
      bets: const {4: 3.0},
      actions: const {4: 'APUESTA'},
      pot: 9.0,
      toAct: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      afterDecision: _flopTable(
        board: const ['Qd', '8s', '3c'],
        bets: const {0: 3.0, 4: 3.0},
        actions: const {0: 'PAGA', 4: 'APUESTA'},
        pot: 12.0,
      ),
      concept: _rules,
      questionAnchor: const TableAnchor.bet(4),
      situationHighlight: const [TableAnchor.bet(4), TableAnchor.seat(0)],
      question: '{BB} apostó 3 BB. Querés seguir en la mano SIN subir. '
          '¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.best,
          feedback: 'Call es igualar: pagás los 3 BB y seguís en la mano '
              'sin subir.',
        ),
        ExerciseChoice(
          label: 'FOLD',
          rating: ExerciseRating.poor,
          feedback: 'Foldear es abandonar la mano. Vos querías seguir.',
        ),
        ExerciseChoice(
          label: 'RAISE',
          rating: ExerciseRating.poor,
          feedback: 'Raise es subir: pondrías MÁS que los 3 BB. Vos querías '
              'seguir sin subir.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Con una apuesta delante: fold, call (igualar) o raise '
              '(subir).',
          anchor: TableAnchor.bet(0),
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 1.4 — Una mano completa (Hero BTN, K♦K♣)
  // ================================================================
  static InteractiveTableExercise _handOpen() {
    final situation = _blindsTable(
      cards: const {0: ['Kd', 'Kc']},
      toAct: 0,
    ).withSeat(3, (s) => s.copyWith(action: 'FOLD', folded: true)).withSeat(
        2, (s) => s.copyWith(action: 'FOLD', folded: true)).withSeat(
        1, (s) => s.copyWith(action: 'FOLD', folded: true));

    final after = TableSnapshot(
      seats: TableScript.seats(
        labels: _labels,
        bets: const {0: 2.5, 4: 2.5, 5: 0.5},
        actions: const {0: 'SUBE', 4: 'PAGA', 5: 'FOLD'},
        folded: const {3, 2, 1, 5},
        cards: const {0: ['Kd', 'Kc']},
      ),
      potBb: 5.5,
      buttonSlot: 0,
    );

    return InteractiveTableExercise(
      situation: situation,
      afterDecision: after,
      concept: _rules,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: 'Tenés K♦K♣ en el BTN y todos foldean hasta vos. '
          '¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'SUBIR A 2,5 BB',
          rating: ExerciseRating.best,
          feedback: 'K♦K♣ es de las mejores manos del póker. Subís para '
              'hacer el bote grande.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: '¡Estás tirando una de las mejores manos que existen! '
              'KK siempre se juega.',
        ),
        ExerciseChoice(
          label: 'IGUALAR LA CIEGA',
          rating: ExerciseRating.poor,
          feedback: 'Limpear con KK regala valor: no aprovechás la fuerza '
              'de tu mano.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Subís a 2,5 BB. {BB} paga y van los dos al flop.',
          anchor: TableAnchor.bet(0),
          highlight: [TableAnchor.bet(0)],
        ),
      ],
    );
  }

  static InteractiveTableExercise _handFlop() {
    final situation = _flopTable(
      board: const ['Ks', '7h', '2d'],
      cards: const {0: ['Kd', 'Kc']},
      actions: const {4: 'PASA'},
      pot: 5.5,
      toAct: 0,
    );
    return InteractiveTableExercise(
      situation: situation,
      afterDecision: _flopTable(
        board: const ['Ks', '7h', '2d'],
        cards: const {0: ['Kd', 'Kc']},
        bets: const {0: 3.5},
        actions: const {0: 'APUESTA', 4: 'PASA'},
        pot: 9.0,
      ),
      concept: _rules,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Flop K♠7♥2♦: con tus K♦K♣ tenés trío de reyes. La BB '
          'pasa. ¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'APOSTAR',
          rating: ExerciseRating.best,
          feedback: 'Tenés una mano muy fuerte: apostás para que {BB} '
              'pague con manos peores y el bote crezca.',
        ),
        ExerciseChoice(
          label: 'PASAR',
          rating: ExerciseRating.acceptable,
          feedback: 'Pasar no es un desastre, pero con trío top querés '
              'meter fichas al bote mientras podés.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: '¿Foldear el trío más alto? Nunca: es casi la mejor '
              'mano posible acá.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Apostás con tu mano fuerte. {BB} paga y siguen al turn y '
              'al river.',
          anchor: TableAnchor.bet(0),
          highlight: [TableAnchor.bet(0)],
        ),
      ],
    );
  }

  static InteractiveTableExercise _handShowdown() {
    final table = _flopTable(
      board: const ['Ks', '7h', '2d', 'Qs', '3c'],
      cards: const {0: ['Kd', 'Kc'], 4: ['Ac', 'Js']},
      pot: 16.0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: _rules,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [
        TableAnchor.heroCards,
        TableAnchor.seat(4),
        TableAnchor.pot,
      ],
      question: 'Llegan al river sin foldear. Mostrás las cartas: tu trío '
          'de reyes vs A♣J♠ de {BB}. ¿Quién gana el bote?',
      choices: const [
        ExerciseChoice(
          label: 'VOS (TRÍO DE K)',
          rating: ExerciseRating.best,
          feedback: 'Tu trío de reyes es una mano hecha. Le gana a {BB}.',
        ),
        ExerciseChoice(
          label: '{BB} (TIENE UN AS)',
          rating: ExerciseRating.poor,
          feedback: 'Un as sin par es solo "carta alta": está muy abajo en '
              'el ranking. Tu trío gana.',
        ),
        ExerciseChoice(
          label: 'SE REPARTE',
          rating: ExerciseRating.poor,
          feedback: 'No hay empate: tu trío es claramente superior a una '
              'carta alta.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Ganás el bote: fichas que empezaron con las ciegas y '
              'crecieron calle a calle.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 1.5 — Evaluación
  // ================================================================
  static InteractiveTableExercise _evalPot() => InteractiveTableExercise(
        situation: _blindsTable(),
        concept: _rules,
        questionAnchor: TableAnchor.pot,
        situationHighlight: const [TableAnchor.pot],
        question: '¿Qué es el bote?',
        choices: const [
          ExerciseChoice(
            label: 'FICHAS EN JUEGO',
            rating: ExerciseRating.best,
            feedback: 'El bote son todas las fichas apostadas; lo gana quien '
                'gana la mano.',
          ),
          ExerciseChoice(
            label: 'CARTAS COMUNES',
            rating: ExerciseRating.poor,
            feedback: 'Esas son el board. El bote son las fichas.',
          ),
          ExerciseChoice(
            label: 'EL STACK DEL BTN',
            rating: ExerciseRating.poor,
            feedback: 'El stack es de un jugador; el bote es común y se lo '
                'lleva el ganador.',
          ),
        ],
        explanation: const [
          ExerciseExplainStep(
            text: 'Ganar la mano = llevarse el bote.',
            anchor: TableAnchor.pot,
            dimOthers: false,
          ),
        ],
      );

  static InteractiveTableExercise _evalStreetOrder() => InteractiveTableExercise(
        situation: _flopTable(board: const ['Th', '6c', '2s']),
        concept: _rules,
        questionAnchor: TableAnchor.board,
        situationHighlight: const [TableAnchor.board],
        question: 'Acaba de salir el flop. ¿Qué calle sigue?',
        choices: const [
          ExerciseChoice(
            label: 'EL TURN',
            rating: ExerciseRating.best,
            feedback: 'Flop → turn → river.',
          ),
          ExerciseChoice(
            label: 'EL RIVER',
            rating: ExerciseRating.poor,
            feedback: 'El river es después del turn.',
          ),
          ExerciseChoice(
            label: 'EL PREFLOP',
            rating: ExerciseRating.poor,
            feedback: 'El preflop es antes del flop: ya pasó.',
          ),
        ],
        explanation: const [
          ExerciseExplainStep(
            text: 'Preflop → flop → turn → river → showdown.',
            anchor: TableAnchor.board,
            dimOthers: false,
          ),
        ],
      );

  static InteractiveTableExercise _evalCheck() => InteractiveTableExercise(
        situation: _flopTable(board: const ['Th', '6c', '2s'], toAct: 0),
        concept: _rules,
        questionAnchor: const TableAnchor.seat(0),
        situationHighlight: const [TableAnchor.seat(0)],
        question: 'No hay apuesta delante tuyo y no querés apostar. Acción:',
        choices: const [
          ExerciseChoice(
            label: 'CHECK',
            rating: ExerciseRating.best,
            feedback: 'Check: pasás sin poner fichas y seguís en la mano.',
          ),
          ExerciseChoice(
            label: 'FOLD',
            rating: ExerciseRating.poor,
            feedback: 'Foldear tira la mano gratis, sin necesidad.',
          ),
          ExerciseChoice(
            label: 'CALL',
            rating: ExerciseRating.poor,
            feedback: 'No hay apuesta que igualar.',
          ),
        ],
        explanation: const [
          ExerciseExplainStep(
            text: 'Sin apuesta delante: check o bet.',
            anchor: TableAnchor.seat(0),
            dimOthers: false,
          ),
        ],
      );

  static InteractiveTableExercise _evalWinByFold() {
    final table = _flopTable(
      board: const ['Th', '6c', '2s'],
      bets: const {4: 4.0},
      actions: const {4: 'APUESTA'},
      pot: 10.0,
      toAct: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      afterDecision: _flopTable(
        board: const ['Th', '6c', '2s'],
        actions: const {0: 'FOLD', 4: 'APUESTA'},
        cards: const {},
        pot: 10.0,
      ).withSeat(0, (s) => s.copyWith(folded: true)),
      concept: _rules,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.bet(4)],
      question: 'En el flop {BB} apuesta y vos foldeás. ¿Qué pasa?',
      choices: const [
        ExerciseChoice(
          label: '{BB} GANA EL BOTE',
          rating: ExerciseRating.best,
          feedback: 'Al retirarte, {BB} se lleva el bote ahí mismo, sin '
              'mostrar cartas.',
        ),
        ExerciseChoice(
          label: 'SE JUEGA EL TURN',
          rating: ExerciseRating.poor,
          feedback: 'Si te retirás, la mano termina para vos: no hay turn.',
        ),
        ExerciseChoice(
          label: 'VAN AL SHOWDOWN',
          rating: ExerciseRating.poor,
          feedback: 'No hay showdown si no llegás al river con la mano '
              'viva.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Se puede ganar en cualquier calle: en cuanto todos menos '
              'uno se retiran, la mano termina.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _evalBlinds() => InteractiveTableExercise(
        situation: _blindsTable(),
        concept: _rules,
        questionAnchor: const TableAnchor.bet(5),
        situationHighlight: const [TableAnchor.bet(5), TableAnchor.bet(4)],
        question: 'Las ciegas (SB y BB) son…',
        choices: const [
          ExerciseChoice(
            label: 'APUESTAS FORZADAS',
            rating: ExerciseRating.best,
            feedback: 'Apuestas obligatorias antes de repartir: arrancan el '
                'bote.',
          ),
          ExerciseChoice(
            label: 'PREMIOS',
            rating: ExerciseRating.poor,
            feedback: 'No premian a nadie: son un costo forzado.',
          ),
          ExerciseChoice(
            label: 'CARTAS COMUNES',
            rating: ExerciseRating.poor,
            feedback: 'Las ciegas son fichas, no cartas.',
          ),
        ],
        explanation: const [
          ExerciseExplainStep(
            text: 'SB y BB fuerzan que siempre haya fichas en juego.',
            anchor: TableAnchor.pot,
            dimOthers: false,
          ),
        ],
      );
}

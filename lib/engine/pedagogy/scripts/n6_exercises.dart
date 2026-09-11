import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 6 "La matemática de continuar".
///
/// Reutiliza, a propósito, el mismo hilo numérico de la teoría de N6
/// (bote 4 → apuesta rival 4 → bote actual 8 → call 4 → bote final 12 →
/// equity necesaria 33% → 9 outs/regla del 4 ≈36% → EV +0.32 BB), para
/// que el ejercicio refuerce el mismo ejemplo que ya vio en la ficha, no
/// uno nuevo que hay que volver a procesar desde cero.
class N6Exercises {
  N6Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '6.1': InteractiveExerciseSet([_outs()]),
    '6.2': InteractiveExerciseSet([_equityReal()]),
    '6.3': InteractiveExerciseSet([_reglaDel4()]),
    '6.4': InteractiveExerciseSet([_boteFinal()]),
    '6.5': InteractiveExerciseSet([_potOdds()]),
    '6.6': InteractiveExerciseSet([_evSign()]),
    '6.7': InteractiveExerciseSet([_foldEquity()]),
  };

  static TableSnapshot _flopColor({double pot = 8.0, double bet = 4.0}) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: TableBuilder.btnHero,
          folded: const {3, 2, 1},
          cards: const {0: ['Ah', '9h'], 4: ['Kd', 'Kc']},
          actions: {4: 'APUESTA'},
          bets: {4: bet},
        ),
        board: const ['Qh', '6h', '2c'],
        potBb: pot,
        buttonSlot: 0,
      );

  // ================================================================
  // 6.1 — Outs
  // ================================================================
  static InteractiveTableExercise _outs() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1, 5},
        cards: const {0: ['9c', '8d']},
      ),
      board: const ['7s', '6h', '2c'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.outs,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board, TableAnchor.heroCards],
      question: 'Tenés 9♣8♦ en un board 7♠6♥2♣: un proyecto de escalera '
          'abierto. ¿Cuántos outs tenés?',
      choices: const [
        ExerciseChoice(
          label: '8',
          rating: ExerciseRating.best,
          feedback: 'Correcto: cualquier 5 o cualquier 10 te completa la '
              'escalera — 4 cincos + 4 dieces = 8 outs.',
        ),
        ExerciseChoice(
          label: '4',
          rating: ExerciseRating.poor,
          feedback: 'Esos serían los outs de un gutshot (una sola carta '
              'específica en el medio). Un proyecto ABIERTO sirve por las '
              'dos puntas: 8 outs.',
        ),
        ExerciseChoice(
          label: '9',
          rating: ExerciseRating.poor,
          feedback: '9 outs es lo típico de un proyecto de COLOR, no de '
              'escalera. Acá no hay proyecto de color en juego.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '4 cincos + 4 dieces en el mazo = 8 cartas que te dan la '
              'mejor mano. Proyecto abierto = 8 outs.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 6.2 — Equity (proyecto vs. casi nada)
  // ================================================================
  static InteractiveTableExercise _equityReal() {
    final table = _flopColor();
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.equity,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Tenés A♥9♥ en un board con dos corazones más: proyecto de '
          'color de 9 outs. ¿Tu equity contra la pareja de reyes del '
          'rival es real, o prácticamente cero?',
      choices: const [
        ExerciseChoice(
          label: 'REAL Y SIGNIFICATIVA',
          rating: ExerciseRating.best,
          feedback: 'Correcto: 9 outs con dos cartas por venir es una '
              'chance real de terminar ganando, no un detalle menor.',
        ),
        ExerciseChoice(
          label: 'PRÁCTICAMENTE CERO',
          rating: ExerciseRating.poor,
          feedback: 'No: un proyecto de color con 9 outs y dos calles por '
              'venir tiene una equity considerable — se calcula en el '
              'próximo paso.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Todavía no le pusiste un número exacto — eso viene con '
              'la regla del 4 (próximo subnivel). Por ahora, la idea es: '
              'un buen proyecto SÍ tiene equity real.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 6.3 — Regla del 4
  // ================================================================
  static InteractiveTableExercise _reglaDel4() {
    final table = _flopColor();
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.equity,
      questionAnchor: TableAnchor.heroCards,
      question: 'Proyecto de color, 9 outs, en el FLOP (dos cartas por '
          'venir). Usando la regla del 4, ¿aproximadamente qué equity '
          'tenés?',
      choices: const [
        ExerciseChoice(
          label: '36%',
          rating: ExerciseRating.best,
          feedback: 'Exacto: 9 outs × 4 = 36%. Esa es tu equity '
              'aproximada para llegar al river.',
        ),
        ExerciseChoice(
          label: '18%',
          rating: ExerciseRating.poor,
          feedback: 'Esa sería la regla del 2 (una sola carta por venir, '
              'como en el turn). En el flop, con DOS cartas por venir, se '
              'usa la regla del 4.',
        ),
        ExerciseChoice(
          label: '9%',
          rating: ExerciseRating.poor,
          feedback: 'Ese es el número de outs, no el porcentaje. Outs y '
              'equity no son lo mismo: hay que multiplicar.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '9 outs × 4 = 36%. Guardá este número: se usa en los '
              'próximos subniveles para calcular si el call es rentable.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 6.4 — El precio de continuar (bote final)
  // ================================================================
  static InteractiveTableExercise _boteFinal() {
    final table = _flopColor();
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.pot, TableAnchor.bet(4)],
      question: 'Había 4 BB en el bote. El rival apuesta 4 BB (bote '
          'actual: 8 BB). Si pagás, ¿cuánto queda en el bote FINAL?',
      choices: const [
        ExerciseChoice(
          label: '12 BB',
          rating: ExerciseRating.best,
          feedback: 'Correcto: bote actual (8) + tu call (4) = 12 BB. Ese '
              'es el número que se usa para calcular pot odds.',
        ),
        ExerciseChoice(
          label: '8 BB',
          rating: ExerciseRating.poor,
          feedback: 'Ese es el bote ANTES de tu call. El bote final suma '
              'también lo que vos vas a poner.',
        ),
        ExerciseChoice(
          label: '16 BB',
          rating: ExerciseRating.poor,
          feedback: 'Eso sería si pagaras el doble de la apuesta. Tu call '
              'iguala los 4 BB del rival, no los duplica.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Bote final = bote actual + tu call = 8 + 4 = 12 BB.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 6.5 — Pot odds (la decisión completa)
  // ================================================================
  static InteractiveTableExercise _potOdds() {
    final table = _flopColor();
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.potOdds,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.pot, TableAnchor.heroCards],
      question: 'Bote final 12 BB, tu call 4 BB (equity necesaria ≈33%). '
          'Tu proyecto de color (9 outs) tiene ≈36% de equity. ¿Pagás o '
          'foldeás?',
      choices: const [
        ExerciseChoice(
          label: 'PAGAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: 36% de equity real supera el 33% '
              'necesario — un call rentable a la larga, aunque pierdas '
              'esa mano puntual la mayoría de las veces.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear acá tira un call +EV: tu equity (36%) ya '
              'supera lo que pedían las pot odds (33%).',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Equity real (36%) > equity necesaria (33%) = call '
              'rentable. El EV exacto de esta decisión es +0.32 BB.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 6.6 — EV: +EV o -EV
  // ================================================================
  static InteractiveTableExercise _evSign() {
    final table = _flopColor();
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.ev,
      questionAnchor: TableAnchor.pot,
      question: 'Mismo call (ganás 8 BB si acertás, perdés 4 BB si no), '
          'pero ahora tu equity real es solo 20% (mano más floja). '
          '¿Esa decisión es +EV o -EV?',
      choices: const [
        ExerciseChoice(
          label: '-EV',
          rating: ExerciseRating.best,
          feedback: 'Correcto: EV = (0.20×8) − (0.80×4) = 1.6 − 3.2 = '
              '−1.6 BB. Con solo 20% de equity, este call pierde fichas a '
              'la larga.',
        ),
        ExerciseChoice(
          label: '+EV',
          rating: ExerciseRating.poor,
          feedback: 'No: con 20% de equity contra el 33% que pide este '
              'bote, el cálculo da negativo (−1.6 BB). Acá lo correcto es '
              'foldear.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'La fórmula no cambia; lo que cambió es tu equity real. '
              'Con menos equity que la necesaria, la misma apuesta pasa a '
              'ser -EV.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 6.7 — El EV de cada acción (fold equity / farol)
  // ================================================================
  static InteractiveTableExercise _foldEquity() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        cards: const {0: ['7c', '5c']},
        toAct: 0,
      ),
      board: const ['Ks', '9d', '2h'],
      potBb: 4.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.ev,
      strategyDependent: true,
      questionAnchor: TableAnchor.pot,
      question: 'Fallaste por completo en un board seco donde el rival '
          'tiene motivos para haber fallado también. Apostás 4 BB para '
          'ganar un bote de 8 BB. Si el rival se retira la mitad de las '
          'veces, ¿el farol suma EV?',
      choices: const [
        ExerciseChoice(
          label: 'SÍ',
          rating: ExerciseRating.best,
          feedback: 'Correcto: EV = (0.5×8) − (0.5×4) = 4 − 2 = +2 BB. El '
              'farol gana gracias a la fold equity, no porque tu mano sea '
              'buena.',
        ),
        ExerciseChoice(
          label: 'NO',
          rating: ExerciseRating.poor,
          feedback: 'Con 50% de fold equity y esos números, el cálculo da '
              'positivo: +2 BB. Un farol no necesita la mejor mano, '
              'necesita suficiente fold equity.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El EV de un farol depende de la fold equity, no de tu '
              'mano real: ganás las veces que el rival se retira.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }
}

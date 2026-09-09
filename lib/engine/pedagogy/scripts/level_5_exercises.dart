import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos sobre la mesa — Nivel 5 (Open raise).
class Level5Exercises {
  Level5Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '5.4': InteractiveExerciseSet([
      _position(),
      _openFold(),
      _threeBet(),
    ]),
  };

  static const _labels = TableBuilder.btnHero;

  // Ej 1 — Posición (Hero BTN)
  static InteractiveTableExercise _position() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: _labels,
        bets: const {3: 3.0, 5: 0.5, 4: 1.0},
        actions: const {3: 'SUBE', 2: 'FOLD', 1: 'FOLD', 5: 'CIEGA', 4: 'CIEGA'},
        folded: const {2, 1},
        cards: const {0: ['As', 'Js']},
        toAct: 0,
      ),
      potBb: 4.5,
      buttonSlot: 0,
    );

    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.positionAdvantage,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.seat(0)],
      question: 'Estás en el BTN y {UTG} subió a 3 BB. Pensando en el flop, '
          'el turn y el river: ¿el BTN juega con ventaja o en desventaja?',
      choices: const [
        ExerciseChoice(
          label: 'CON VENTAJA',
          rating: ExerciseRating.best,
          feedback: 'Exacto: el BTN actúa último en todas las calles '
              'postflop. Ves qué hacen los demás antes de decidir.',
        ),
        ExerciseChoice(
          label: 'EN DESVENTAJA',
          rating: ExerciseRating.poor,
          feedback: 'No: en desventaja está quien habla primero. El BTN '
              'siempre habla último postflop.',
        ),
        ExerciseChoice(
          label: 'DEPENDE DE LA MANO',
          rating: ExerciseRating.poor,
          feedback: 'La ventaja posicional no depende de tus cartas, sino '
              'de dónde estás sentado. El BTN siempre actúa último.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El BTN es la única posición que actúa después de TODOS en '
              'cada calle postflop.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
        ),
        ExerciseExplainStep(
          text: '{UTG}, {SB} y {BB} van a tener que decidir sin saber todavía qué '
              'vas a hacer vos.',
          anchor: TableAnchor.seat(3),
          highlight: [
            TableAnchor.seat(3),
            TableAnchor.seat(5),
            TableAnchor.seat(4),
          ],
        ),
        ExerciseExplainStep(
          text: 'Por eso la posición no es decorativa: cambia qué manos '
              'jugás y cómo las jugás.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // Ej 2 — Open / Fold (Hero BTN, A♠7♠)
  static InteractiveTableExercise _openFold() {
    final situation = TableSnapshot(
      seats: TableBuilder.seats(
        labels: _labels,
        bets: const {5: 0.5, 4: 1.0},
        actions: const {
          3: 'FOLD',
          2: 'FOLD',
          1: 'FOLD',
          5: 'CIEGA',
          4: 'CIEGA',
        },
        folded: const {3, 2, 1},
        cards: const {0: ['As', '7s']},
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 0,
    );

    final after = TableSnapshot(
      seats: TableBuilder.seats(
        labels: _labels,
        bets: const {0: 2.5, 5: 0.5, 4: 1.0},
        actions: const {0: 'SUBE', 5: 'CIEGA', 4: 'CIEGA'},
        folded: const {3, 2, 1},
        cards: const {0: ['As', '7s']},
      ),
      potBb: 4.0,
      buttonSlot: 0,
    );

    return InteractiveTableExercise(
      situation: situation,
      afterDecision: after,
      concept: ConceptIds.openRaise,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: 'Todos foldean hasta vos. Estás en el BTN con A♠7♠. '
          '¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'FOLD',
          rating: ExerciseRating.poor,
          feedback: 'Demasiado tight. Desde el BTN se abre casi la mitad de '
              'las manos: A♠7♠ entra cómoda.',
        ),
        ExerciseChoice(
          label: 'OPEN',
          rating: ExerciseRating.best,
          feedback: 'Correcto. As suited desde el BTN es una apertura '
              'estándar: robás ciegas seguido y postflop jugás con ventaja.',
        ),
        ExerciseChoice(
          label: 'ALL-IN',
          rating: ExerciseRating.poor,
          feedback: 'Enorme sobra. Con 100 BB se abre a 2–2,5 BB; el all-in '
              'solo tiene sentido con stacks muy cortos.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Abrís a 2,5 BB, el tamaño estándar en 6-max.',
          anchor: TableAnchor.bet(0),
          highlight: [TableAnchor.bet(0)],
        ),
        ExerciseExplainStep(
          text: 'El rango de apertura del BTN es el más ancho de la mesa: '
              'cualquier par, ases, conectores y suited razonables.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
        ),
        ExerciseExplainStep(
          text: 'A♠7♠ no es fuerte, pero con posición y solo dos rivales por '
              'actuar, abrir gana fichas a largo plazo.',
          anchor: TableAnchor.heroCards,
          dimOthers: false,
        ),
      ],
    );
  }

  // Ej 3 — 3-bet (Hero BTN, A♠J♠, vs open de UTG)
  static InteractiveTableExercise _threeBet() {
    final situation = TableSnapshot(
      seats: TableBuilder.seats(
        labels: _labels,
        bets: const {3: 3.0, 5: 0.5, 4: 1.0},
        actions: const {
          3: 'SUBE',
          2: 'FOLD',
          1: 'FOLD',
          5: 'CIEGA',
          4: 'CIEGA',
        },
        folded: const {2, 1},
        cards: const {0: ['As', 'Js']},
        toAct: 0,
      ),
      potBb: 4.5,
      buttonSlot: 0,
    );

    final after = TableSnapshot(
      seats: TableBuilder.seats(
        labels: _labels,
        bets: const {0: 9.0, 3: 3.0, 5: 0.5, 4: 1.0},
        actions: const {0: 'SUBE', 3: 'SUBE'},
        folded: const {2, 1},
        cards: const {0: ['As', 'Js']},
        toAct: 3,
      ),
      potBb: 13.5,
      buttonSlot: 0,
    );

    return InteractiveTableExercise(
      situation: situation,
      afterDecision: after,
      strategyDependent: true,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.seat(3)],
      question: '{UTG} abre a 3 BB, {HJ} y {CO} foldean. Estás en el BTN con '
          'A♠J♠. ¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'FOLD',
          rating: ExerciseRating.poor,
          feedback: 'Demasiado débil. A♠J♠ tiene as, jota y proyecto de '
              'color: es claramente jugable con posición contra un open.',
        ),
        ExerciseChoice(
          label: 'CALL',
          rating: ExerciseRating.acceptable,
          feedback: 'Opción razonable: pagás con posición y jugás un bote '
              'controlado. Muchas estrategias lo hacen una parte del tiempo.',
        ),
        ExerciseChoice(
          label: '3-BET',
          rating: ExerciseRating.best,
          feedback: 'Buena elección. Resubir con A♠J♠ desde el BTN presiona '
              'el rango de {UTG}, te lleva la iniciativa y bloqueás sus AA/AK.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Con un 3-bet a ~9 BB, {UTG} ahora decide con un bote más '
              'grande y fuera de posición.',
          anchor: TableAnchor.bet(0),
          highlight: [TableAnchor.bet(0)],
        ),
        ExerciseExplainStep(
          text: 'El rango de {UTG} suele ser fuerte (parejas altas, ases '
              'buenos), pero igual foldea muchas manos ante un 3-bet.',
          anchor: TableAnchor.seat(3),
          highlight: [TableAnchor.seat(3)],
        ),
        ExerciseExplainStep(
          text: 'A♠J♠ es fuerte pero no premium: por eso 3-bet y call son '
              'ambas defendibles. La clave: no decidir SOLO mirando tus '
              'cartas.',
          anchor: TableAnchor.heroCards,
          highlight: [TableAnchor.heroCards],
        ),
        ExerciseExplainStep(
          text: 'La posición del BTN es lo que hace jugable esta mano: '
              'postflop siempre actuás último.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
          dimOthers: false,
        ),
      ],
    );
  }
}

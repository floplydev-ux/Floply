import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 7 "Guerra preflop: defensa y 3-bet".
class N7Exercises {
  N7Exercises._();

  // 7.2 ya tiene un set heredado ("ex-5.4": posición / open-fold / 3-bet,
  // ver AcademyExerciseScripts) que cubre bien ese subnivel — no se
  // duplica acá para no taparlo ni repetir el mismo tipo de decisión. Para
  // el checkpoint (7.4) sí hace falta una pregunta propia de 3-bet valor/
  // farol (_threeBetValueOrBluff más abajo): llamar al set heredado desde
  // acá crearía un ciclo de inicialización con AcademyExerciseScripts (que
  // a su vez depende de N7Exercises.byId), así que se escribe una pregunta
  // autocontenida en vez de referenciarlo.
  static final Map<String, InteractiveExerciseSet> byId = {
    '7.1': InteractiveExerciseSet([_callOFold()]),
    '7.3': InteractiveExerciseSet([_spr()]),
    // 7.4 es el checkpoint del nivel: la evaluación del módulo repasa
    // 7.1 (call o fold), 7.2 (3-bet valor/farol) y 7.3 (SPR) antes de
    // cerrar con su propio contenido (responder a una 3-bet).
    '7.4': InteractiveExerciseSet([
      _callOFold(),
      _threeBetValueOrBluff(),
      _spr(),
      _vsThreeBet(),
    ]),
  };

  // ================================================================
  // 7.1 — ¿Call o fold contra un open?
  // ================================================================
  static InteractiveTableExercise _callOFold() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: const {0: 'BB', 5: 'BTN', 4: 'SB', 3: 'UTG', 2: 'HJ', 1: 'CO'},
        folded: const {3, 2, 1},
        actions: const {5: 'ABRE'},
        bets: const {4: 0.5, 5: 2.5, 0: 1.0},
        cards: const {0: ['9h', '8h']},
        toAct: 0,
      ),
      potBb: 4.0,
      buttonSlot: 5,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.bbDefense,
      questionAnchor: const TableAnchor.seat(5),
      situationHighlight: const [TableAnchor.seat(5), TableAnchor.heroCards],
      question: '{BTN} abre. Estás en la BB con 9♥8♥ — ya tenés parte del '
          'precio pagado. ¿Pagás o foldeás?',
      choices: const [
        ExerciseChoice(
          label: 'PAGAR',
          rating: ExerciseRating.best,
          feedback: 'Bien: 98 suited juega bien postflop, y el rango de '
              'apertura del botón es el más ancho de la mesa — tu rango de '
              'defensa acá es amplio.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear una mano especulativa contra el rango más '
              'ancho de la mesa, con buen precio, regala una defensa '
              'rentable.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Contra un rango de apertura amplio (botón) y con buen '
              'precio (ya pusiste la BB), el rango de defensa se abre.',
          anchor: TableAnchor.seat(5),
        ),
      ],
    );
  }

  // ================================================================
  // 7.2 — 3-bet: valor o farol (usada solo en el checkpoint 7.4, ver
  // comentario de byId)
  // ================================================================
  static InteractiveTableExercise _threeBetValueOrBluff() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: const {0: 'CO', 5: 'BTN', 4: 'SB', 3: 'BB', 2: 'UTG', 1: 'HJ'},
        folded: const {2, 1, 4, 3},
        actions: const {0: 'ABRE', 5: '3-BET'},
        bets: const {0: 2.5, 5: 9.0},
        cards: const {5: ['As', '5s']},
        toAct: 0,
      ),
      potBb: 12.5,
      buttonSlot: 5,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(5),
      situationHighlight: const [TableAnchor.seat(5)],
      question: 'El CO abre. El botón 3-betea con A♠5♠ — una mano floja '
          'para solo pagar. ¿Esa 3-bet es por valor o como farol?',
      choices: const [
        ExerciseChoice(
          label: 'FAROL',
          rating: ExerciseRating.best,
          feedback: 'Correcto: A5 suited no le gana cómodo al rango de '
              'apertura del CO. Esta 3-bet busca que el resto de ese '
              'rango se retire — gana por fold equity, no por tener lo '
              'mejor.',
        ),
        ExerciseChoice(
          label: 'VALOR',
          rating: ExerciseRating.poor,
          feedback: 'Una 3-bet por valor busca meter fichas mientras estás '
              'mejor parado (como con KK). A5 suited no le gana cómodo al '
              'rango de apertura del CO: acá el motivo es otro.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Un rango de 3-bet bien armado combina manos de valor '
              '(AA-QQ, AK) con algunos faroles como este — así el rival '
              'nunca sabe con cuál de los dos está enfrentando.',
          anchor: TableAnchor.seat(5),
        ),
      ],
    );
  }

  // ================================================================
  // 7.3 — Anatomía del bote 3-bet (SPR)
  // ================================================================
  static InteractiveTableExercise _spr() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2},
        actions: const {1: 'PAGA', 0: '3-BET'},
        bets: const {1: 9.0, 0: 9.0},
        cards: const {0: ['Ac', 'Qc']},
        stacks: const {0: 91, 1: 91},
      ),
      board: const ['Jc', '7d', '3s'],
      potBb: 19.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.pot],
      question: 'Bote 3-bet: llegás al flop con 19 BB en el medio y 91 BB '
          'de stack restante (el más chico de los dos). ¿Cuál es, '
          'aproximadamente, el SPR?',
      choices: const [
        ExerciseChoice(
          label: '≈5 (91 ÷ 19)',
          rating: ExerciseRating.best,
          feedback: 'Correcto: SPR = stack ÷ bote = 91 ÷ 19 ≈ 4,8 — bien '
              'más bajo que en un bote normal con el mismo stack.',
        ),
        ExerciseChoice(
          label: '≈19 (el tamaño del bote)',
          rating: ExerciseRating.poor,
          feedback: 'Ese es el bote, no el SPR. El SPR es la RELACIÓN "cuántas '
              'veces entra el bote en el stack" — hay que dividir.',
        ),
        ExerciseChoice(
          label: '≈91 (el stack, sin dividir)',
          rating: ExerciseRating.poor,
          feedback: 'Falta dividir por el bote. El SPR compara el stack '
              'CONTRA el bote, no lo mira solo.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Con SPR bajo (≈5), esta mano ya se acerca a querer jugar '
              'por todo el stack si mejora en el flop — mucho menos margen '
              'que en un bote de SPR 15+.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 7.4 — Responder a una 3-bet / 4-bet
  // ================================================================
  static InteractiveTableExercise _vsThreeBet() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: const {0: 'CO', 5: 'BTN', 4: 'SB', 3: 'BB', 2: 'UTG', 1: 'HJ'},
        folded: const {2, 1, 4, 3},
        actions: const {0: 'ABRE', 5: '3-BET'},
        bets: const {0: 2.5, 5: 9.0},
        cards: const {0: ['Kh', '9d']},
        toAct: 0,
      ),
      potBb: 12.5,
      buttonSlot: 5,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(5),
      situationHighlight: const [TableAnchor.seat(5), TableAnchor.heroCards],
      question: 'Abriste con K♥9♦ desde el CO. El botón te 3-betea. ¿Qué '
          'hacés?',
      choices: const [
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: K9 offsuit no entra ni en tu rango de call '
              'ni de 4-bet contra una 3-bet. Abriste con una mano '
              'razonable; esto es parte normal del juego.',
        ),
        ExerciseChoice(
          label: 'PAGAR',
          rating: ExerciseRating.poor,
          feedback: 'K9o no juega bien un bote 3-bet fuera de posición '
              'contra un rango de 3-bet ya reforzado.',
        ),
        ExerciseChoice(
          label: '4-BETEAR',
          rating: ExerciseRating.poor,
          feedback: 'K9o está lejos de ser una mano de 4-bet, sea por '
              'valor o como farol bien elegido.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'La mayoría de las manos, la mayoría de las veces, se '
              'foldean contra una 3-bet — igual que preflop.',
          anchor: TableAnchor.seat(5),
        ),
      ],
    );
  }
}

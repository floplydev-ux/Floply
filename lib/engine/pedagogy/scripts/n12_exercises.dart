import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 12 "Integración y toma de decisiones".
///
/// Ningún ejercicio de N12 pregunta por una definición: todos presentan
/// una situación completa y piden una decisión, aplicando el checklist
/// de 12.1-12.2 en vez de recitarlo.
class N12Exercises {
  N12Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '12.1': InteractiveExerciseSet([_leerElSpot()]),
    '12.2': InteractiveExerciseSet([_tomarLaDecision()]),
    '12.3': InteractiveExerciseSet([_integrarPreflop()]),
    // 12.4 es el checkpoint del nivel: la evaluación del módulo repasa
    // leer el spot, tomar la decisión e integrar el preflop, antes de
    // cerrar con su propio contenido (integrar el postflop).
    '12.4': InteractiveExerciseSet([
      _leerElSpot(),
      _tomarLaDecision(),
      _integrarPreflop(),
      _integrarPostflop(),
    ]),
  };

  // ================================================================
  // 12.1 — El checklist: leer el spot
  // ================================================================
  static InteractiveTableExercise _leerElSpot() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        cards: const {0: ['Th', '9h']},
        toAct: 0,
      ),
      board: const ['Jh', '8h', '2c'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Posición: botón. Mano: T♥9♥. Board: J♥8♥2♣. Recorriendo '
          'el checklist ("¿qué mano tengo hecha?" + "¿qué proyectos '
          'tengo?"), ¿cómo se describe mejor esta mano?',
      choices: const [
        ExerciseChoice(
          label: 'SIN MANO HECHA, PERO CON DOBLE PROYECTO '
              '(ESCALERA Y COLOR)',
          rating: ExerciseRating.best,
          feedback: 'Correcto: no tenés pareja ni nada hecho todavía, '
              'pero T9 de corazones en este board tiene proyecto de '
              'escalera abierta Y de color al mismo tiempo.',
        ),
        ExerciseChoice(
          label: 'TOP PAIR',
          rating: ExerciseRating.poor,
          feedback: 'No emparejaste ninguna carta del board: T y 9 no '
              'están en la mesa. No hay pareja acá.',
        ),
        ExerciseChoice(
          label: 'NADA, MANO SIN VALOR',
          rating: ExerciseRating.poor,
          feedback: 'No tenés mano hecha, pero "nada" ignora un dato '
              'clave del checklist: los proyectos. Acá hay dos proyectos '
              'fuertes combinados.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El checklist no termina en "mano hecha": siempre se '
              'suma "¿qué proyectos tengo, además?" antes de pasar a '
              'decidir.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 12.2 — El checklist: tomar la decisión
  // ================================================================
  static InteractiveTableExercise _tomarLaDecision() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'APUESTA'},
        bets: const {4: 4.0},
        cards: const {0: ['Th', '9h']},
        toAct: 0,
      ),
      board: const ['Jh', '8h', '2c'],
      potBb: 8.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.pot, TableAnchor.heroCards],
      question: 'Misma mano que antes: T♥9♥, doble proyecto. La BB '
          'apuesta 4 BB en un bote de 8 BB (bote final 12, equity '
          'necesaria ≈33%). Con escalera abierta + color (equity bien '
          'por encima de eso), ¿pagás?',
      choices: const [
        ExerciseChoice(
          label: 'PAGAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: un doble proyecto (escalera abierta + '
              'color) tiene muchísima más equity que el 33% necesario '
              'acá — un call claramente rentable.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear tira un call muy rentable: con dos '
              'proyectos combinados, la equity real supera cómodo lo que '
              'piden las pot odds.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El checklist completo: leer el spot (12.1) + calcular '
              'equity contra lo necesario (12.2) = la decisión. No hace '
              'falta memoria, hace falta aplicar los pasos en orden.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 12.3 — Integrar el preflop
  // ================================================================
  static InteractiveTableExercise _integrarPreflop() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: const {0: 'BB', 5: 'BTN', 4: 'SB', 3: 'UTG', 2: 'HJ', 1: 'CO'},
        folded: const {3, 2, 1},
        actions: const {5: 'ABRE'},
        bets: const {4: 0.5, 5: 2.5, 0: 1.0},
        cards: const {0: ['Ks', 'Jd']},
        toAct: 0,
      ),
      potBb: 4.0,
      buttonSlot: 5,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: const TableAnchor.seat(5),
      situationHighlight: const [TableAnchor.seat(5), TableAnchor.heroCards],
      question: 'Integrando todo el preflop: posición (BB), mano (K♠J♦), '
          'acción previa ({BTN} abre, el rango más ancho de la mesa), y '
          'tu rango de defensa. ¿Cuál es la mejor línea?',
      choices: const [
        ExerciseChoice(
          label: 'CALL O 3-BET (SEGUIR EN LA MANO)',
          rating: ExerciseRating.best,
          feedback: 'Correcto: KJ offsuit, contra el rango más amplio de '
              'la mesa (botón) y con buen precio desde la BB, entra '
              'cómodo en tu rango de defensa — pagar o incluso '
              '3-betear son líneas razonables.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear KJ contra el rango más ancho de la mesa, '
              'con el precio que da la BB, regala una defensa rentable.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Rango de apertura del rival (amplio, por ser el botón) '
              '+ tu rango de defensa + el precio = la decisión completa, '
              'no una regla aislada.',
          anchor: TableAnchor.seat(5),
        ),
      ],
    );
  }

  // ================================================================
  // 12.4 — Integrar el postflop
  // ================================================================
  static InteractiveTableExercise _integrarPostflop() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        cards: const {0: ['Ac', 'Kc']},
        toAct: 0,
      ),
      board: const ['Kd', '7s', '2h'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Integrando el postflop: tenés la iniciativa, board seco '
          'K-7-2, top pair con el mejor kicker posible. ¿Cuál es la '
          'línea que junta todo lo que ya sabés de c-bet, board y mano '
          'hecha?',
      choices: const [
        ExerciseChoice(
          label: 'C-BETEAR POR VALOR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: iniciativa + board seco (c-bet frecuente) '
              '+ mano de valor real con manos peores dispuestas a pagar '
              '= c-bet por valor, sin dudarlo.',
        ),
        ExerciseChoice(
          label: 'PASAR PARA HACER POT CONTROL',
          rating: ExerciseRating.poor,
          feedback: 'Pot control es para manos medias que no le ganan a '
              'suficiente rango. Top pair con el mejor kicker posible en '
              'un board seco quiere apostar, no esconderse.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Ninguna variable sola decide: iniciativa + board + '
              'mano hecha, las tres juntas, son las que arman esta '
              'decisión.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }
}

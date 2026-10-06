import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 13 "Dominio de NL2" (capstone).
///
/// El último ejercicio (13.5) es el cierre de las 326 teorías: una mano
/// completa que integra pot odds, equity, rango y posición a la vez —
/// el mismo criterio que cierra T308.
class N13Exercises {
  N13Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '13.1': InteractiveExerciseSet([_entornoNL2()]),
    '13.2': InteractiveExerciseSet([_apostarMasFuerte()]),
    '13.3': InteractiveExerciseSet([_detectarError()]),
    '13.4': InteractiveExerciseSet([_allIn()]),
    // 13.5 es el checkpoint del último nivel Y el cierre de las 326
    // teorías: la evaluación del módulo repasa el entorno NL2, apostar
    // más fuerte por valor, detectar un error y la decisión de all-in,
    // antes de cerrar con la decisión integrada (pot odds + equity +
    // rango + posición, el mismo criterio que T308).
    '13.5': InteractiveExerciseSet([
      _entornoNL2(),
      _apostarMasFuerte(),
      _detectarError(),
      _allIn(),
      _decisionIntegrada(),
    ]),
  };

  // ================================================================
  // 13.1 — El entorno NL2
  // ================================================================
  static InteractiveTableExercise _entornoNL2() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: const {0: 'BB', 5: 'BTN', 4: 'SB', 3: 'UTG', 2: 'HJ', 1: 'CO'},
        actions: const {3: 'PAGA', 2: 'PAGA', 1: 'PAGA', 5: 'PAGA'},
        bets: const {3: 1.0, 2: 1.0, 1: 1.0, 5: 1.0, 4: 0.5, 0: 1.0},
        cards: const {0: ['7c', '2d']},
      ),
      potBb: 5.5,
      buttonSlot: 5,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [
        TableAnchor.seat(3),
        TableAnchor.seat(2),
        TableAnchor.seat(1),
        TableAnchor.seat(5),
      ],
      question: 'CUATRO jugadores limpearon (nadie subió) antes de '
          'llegar a tu BB. ¿Este patrón —limpear en vez de subir, varias '
          'manos por mesa— es típico de NL2 o de niveles más altos?',
      choices: const [
        ExerciseChoice(
          label: 'TÍPICO DE NL2',
          rating: ExerciseRating.best,
          feedback: 'Correcto: en NL2 es común ver varios limps antes de '
              'llegar a vos — errores frecuentes y visibles, mucho más '
              'que en niveles avanzados.',
        ),
        ExerciseChoice(
          label: 'TÍPICO DE NIVELES AVANZADOS',
          rating: ExerciseRating.poor,
          feedback: 'Al revés: en niveles avanzados casi nadie limpea. '
              'Esto es una señal característica de NL2.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'NL2 está lleno de errores frecuentes como este — parte '
              'del juego es reconocerlos y aprovecharlos, no solo '
              'evitarlos vos mismo.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 13.2 — Cómo se gana en NL2 (apostar más fuerte por valor)
  // ================================================================
  static InteractiveTableExercise _apostarMasFuerte() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'PAGA'},
        cards: const {0: ['Qh', 'Qd']},
        toAct: 0,
      ),
      board: const ['Qs', '8h', '3d', '6c', '9s'],
      potBb: 10.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.pot,
      question: 'Llegaste al río con un set de damas contra un rival de '
          'NL2 que ya pagó cada calle (un "calling station" típico). '
          '¿Qué tamaño de apuesta de valor tiene más sentido?',
      choices: const [
        ExerciseChoice(
          label: 'GRANDE (tamaño del bote o más)',
          rating: ExerciseRating.best,
          feedback: 'Correcto: en NL2, contra un rival que ya mostró que '
              'paga de más, un tamaño grande suele seguir cobrando el '
              'mismo pago — dejar fichas en la mesa con un tamaño chico '
              'es un error frecuente.',
        ),
        ExerciseChoice(
          label: 'CHICO (un tercio del bote)',
          rating: ExerciseRating.poor,
          feedback: 'Contra un rival que ya demostró que paga de más, un '
              'tamaño chico cobra mucho menos de lo que en realidad '
              'hubiera pagado.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'En NL2, con manos de valor claro, apostar más grande '
              'de lo habitual suele rendir — porque te pagan más de lo '
              'que un jugador avanzado pagaría.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 13.3 — Los 18 errores (detectar el error)
  // ================================================================
  static InteractiveTableExercise _detectarError() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'APUESTA GRANDE'},
        bets: const {4: 14.0},
        cards: const {0: ['9d', '9c']},
        toAct: 0,
      ),
      board: const ['Kh', 'Qh', 'Jh', '4c', '2s'],
      potBb: 14.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Tenés una pareja de nueves (por debajo de TODO el '
          'board) en un board con proyecto de color de corazones ya '
          'visible. El rival apuesta muy grande en el río. Pagar acá, '
          '"para ver", ¿qué error de los 18 estarías cometiendo?',
      choices: const [
        ExerciseChoice(
          label: 'HERO CALL POR CURIOSIDAD',
          rating: ExerciseRating.best,
          feedback: 'Correcto: tu pareja de nueves ni siquiera le gana a '
              'la mayoría del rango del rival en este board tan '
              'peligroso — pagar "para ver" acá es el error clásico de '
              'hero call sin fundamento.',
        ),
        ExerciseChoice(
          label: 'NO HACER VALUE BET',
          rating: ExerciseRating.poor,
          feedback: 'Ese error es sobre NO apostar tu propia mano de '
              'valor — acá el rival es el que apuesta, y la pregunta es '
              'si pagar o no.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Con una mano tan floja en un board tan peligroso, '
              'pagar "para ver" no tiene fundamento real — es el error '
              'de hero call por curiosidad.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 13.4 — Spots completos de río y all-in
  // ================================================================
  static InteractiveTableExercise _allIn() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2},
        actions: const {1: 'ALL-IN', 0: '3-BET'},
        bets: const {1: 60.0, 0: 60.0},
        cards: const {0: ['Ac', 'Ad']},
        stacks: const {0: 40, 1: 40},
      ),
      board: const ['Kh', '7d', '2c'],
      potBb: 79.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [TableAnchor.pot, TableAnchor.heroCards],
      question: 'Bote 3-bet, SPR muy bajo. El rival va all-in en el '
          'flop con A♣A♦ en tu mano — la mejor mano posible antes del '
          'flop. ¿Pagás el all-in?',
      choices: const [
        ExerciseChoice(
          label: 'PAGAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: con SPR tan bajo, AA (tu mano más fuerte '
              'posible) ya alcanza sobrado para ir por todo el stack. No '
              'hay margen ni motivo para foldear acá.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear la mejor mano posible con SPR bajo regala '
              'una decisión clarísima — este es exactamente el tipo de '
              'situación donde ir por todo el stack corresponde.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'SPR bajo + tu mejor mano posible = decisión de all-in '
              'clara, sin necesidad de cálculos finos.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 13.5 — La decisión integrada (capstone de las 326 teorías)
  // ================================================================
  static InteractiveTableExercise _decisionIntegrada() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'APUESTA'},
        bets: const {4: 4.0},
        cards: const {0: ['Th', '9h']},
        toAct: 0,
      ),
      board: const ['Jh', '8s', '2h'],
      potBb: 8.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: TableAnchor.pot,
      situationHighlight: const [
        TableAnchor.pot,
        TableAnchor.heroCards,
        TableAnchor.seat(4),
      ],
      question: 'Mano completa: abriste en el BOTÓN (rango amplio, en '
          'posición todo el resto de la mano) con T♥9♥. Te pagó la BB. '
          'En el flop J♥8♠2♥ tenés proyecto de escalera abierta y de '
          'color — doble proyecto. La BB apuesta 4 BB en un bote de '
          '8 BB (equity necesaria ≈33%; tu equity con este doble '
          'proyecto ronda el 50%+). Integrando pot odds, equity, el '
          'rango de defensa de la BB y tu posición: ¿pagás?',
      choices: const [
        ExerciseChoice(
          label: 'PAGAR (los cuatro factores apuntan a seguir)',
          rating: ExerciseRating.best,
          feedback: 'Los cuatro pilares coinciden: pot odds favorables '
              '(33% necesario), equity muy por encima (50%+ con doble '
              'proyecto), rango de la BB no especialmente fuerte acá, y '
              'jugás en posición el resto de la mano — cada factor '
              'suma en la misma dirección. Esta es, ni más ni menos, la '
              'decisión integrada que cierra toda la Academia.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear acá tira una decisión donde los cuatro '
              'pilares (pot odds, equity, rango, posición) apuntan '
              'juntos a seguir — exactamente lo opuesto a lo que integra '
              'T308.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Pot odds + equity + rango + posición, los cuatro '
              'juntos: esa es la decisión integrada. De T001 a esta '
              'mano, es el mismo juego completo.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }
}

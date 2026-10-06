import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 11 "Conceptos estratégicos".
///
/// La auditoría pedagógica marcó N11 como el bloque más abstracto del
/// currículo: 15 teorías EXPLICAR seguidas, sin ninguna práctica
/// intercalada. Acá cada subnivel (6) cierra con UN ejercicio de
/// aplicación inmediata — explicación → situación → decisión → feedback
/// — para cortar la racha de solo-lectura antes de que se acumule.
class N11Exercises {
  N11Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '11.1': InteractiveExerciseSet([_ventajaDeRango()]),
    '11.2': InteractiveExerciseSet([_sprEstrategico()]),
    '11.3': InteractiveExerciseSet([_condensado()]),
    '11.4': InteractiveExerciseSet([_bloqueador()]),
    '11.5': InteractiveExerciseSet([_mdf()]),
    // 11.6 es el checkpoint del nivel: la evaluación del módulo repasa
    // ventaja de rango, SPR estratégico, condensación, bloqueadores y
    // MDF, antes de cerrar con su propio contenido (explotar vs jugar
    // equilibrado).
    '11.6': InteractiveExerciseSet([
      _ventajaDeRango(),
      _sprEstrategico(),
      _condensado(),
      _bloqueador(),
      _mdf(),
      _explotar(),
    ]),
  };

  // ================================================================
  // 11.1 — Ventajas (rango/nuts/posición)
  // ================================================================
  static InteractiveTableExercise _ventajaDeRango() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.utgHero,
        folded: const {2, 1},
        cards: const {0: ['Kc', 'Kd']},
        toAct: 0,
      ),
      board: const ['Ks', 'Qh', '7c'],
      potBb: 6.0,
      buttonSlot: 3,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.rangeAdvantage,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: 'Abriste desde UTG (rango angosto y fuerte) y te pagó la '
          'BB (rango amplio y más flojo). Board K-Q-7. ¿Quién tiene, en '
          'promedio, ventaja de rango en este board?',
      choices: const [
        ExerciseChoice(
          label: 'VOS (el agresor de UTG)',
          rating: ExerciseRating.best,
          feedback: 'Correcto: tu rango de apertura de UTG tiene muchas '
              'más manos con cartas altas (K, Q, A) que el rango de '
              'defensa de la BB — en este board en particular, tu rango '
              'completo está mejor parado.',
        ),
        ExerciseChoice(
          label: 'LA BB (el defensor)',
          rating: ExerciseRating.poor,
          feedback: 'Al revés: un board con cartas altas favorece al '
              'rango más angosto y fuerte (UTG), no al más amplio y flojo '
              'de la BB.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Ventaja de rango = tu CONJUNTO completo, no tu mano '
              'puntual, gana más seguido en promedio en ese board.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 11.2 — Stacks y SPR (uso estratégico)
  // ================================================================
  static InteractiveTableExercise _sprEstrategico() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2},
        actions: const {1: 'PAGA', 0: '3-BET'},
        cards: const {0: ['Ac', 'Qc']},
        stacks: const {0: 85, 1: 85},
        toAct: 0,
      ),
      board: const ['Qh', '8d', '3s'],
      potBb: 18.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.pot],
      question: 'Bote 3-bet, SPR bajo (≈4,7). Tenés top pair con buen '
          'kicker — no la mejor mano posible, pero fuerte. ¿Con SPR tan '
          'bajo, alcanza para ir por todo el stack?',
      choices: const [
        ExerciseChoice(
          label: 'SÍ, ALCANZA',
          rating: ExerciseRating.best,
          feedback: 'Correcto: con SPR bajo, una mano buena-pero-no-la-'
              'mejor-posible ya alcanza para comprometerse. Con SPR alto '
              'haría falta mucho más.',
        ),
        ExerciseChoice(
          label: 'NO, HACE FALTA LA MEJOR MANO POSIBLE',
          rating: ExerciseRating.poor,
          feedback: 'Ese criterio es para SPR alto. Con SPR bajo, el '
              'margen para protegerte es chico: top pair fuerte ya '
              'alcanza.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'SPR bajo = manos buenas alcanzan para ir por todo. SPR '
              'alto = hace falta mucho más.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 11.3 — Polarización y condensación
  // ================================================================
  static InteractiveTableExercise _condensado() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'CHECK'},
        cards: const {0: ['Jd', 'Th']},
        toAct: 0,
      ),
      board: const ['9s', '6d', '2c', 'Kh'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.polarization,
      questionAnchor: const TableAnchor.seat(4),
      question: 'Ambos pasaron el flop y el turn con manos medias '
          '(pot control de los dos lados). Llegando al río, ¿el rango '
          'que queda en juego tiende a estar polarizado o condensado?',
      choices: const [
        ExerciseChoice(
          label: 'CONDENSADO — mayormente manos medias',
          rating: ExerciseRating.best,
          feedback: 'Correcto: cuando ambos pasan manos fuertes Y flojas '
              'por igual (protegiendo con pot control), lo que queda es '
              'mayormente fuerza media — sin los extremos marcados de un '
              'rango polarizado.',
        ),
        ExerciseChoice(
          label: 'POLARIZADO — solo lo mejor o faroles',
          rating: ExerciseRating.poor,
          feedback: 'Polarizado sería si cada uno pasara solo sus manos '
              'medias y APOSTARA sus extremos. Acá pasaron TODO tipo de '
              'mano por igual: eso condensa el rango, no lo polariza.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Condensado = mayormente manos medias, sin extremos '
              'marcados. Es el resultado típico de dos rondas de pot '
              'control de los dos lados.',
          anchor: TableAnchor.seat(4),
        ),
      ],
    );
  }

  // ================================================================
  // 11.4 — Bloqueadores
  // ================================================================
  static InteractiveTableExercise _bloqueador() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2},
        actions: const {1: 'PAGA', 0: '3-BET'},
        cards: const {0: ['Ac', '5c']},
        toAct: 0,
      ),
      board: const ['Jd', '7c', '2h'],
      potBb: 19.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.blockers,
      strategyDependent: true,
      questionAnchor: TableAnchor.heroCards,
      question: 'Vas a farolear un bote 3-bet contra un rango que '
          'incluye combos de AK y AA. Entre A♣5♣ y 8♣7♣ (fuerza '
          'parecida como farol), ¿cuál bloquea mejor las manos de valor '
          'del rival?',
      choices: const [
        ExerciseChoice(
          label: 'A♣5♣ — tiene el As',
          rating: ExerciseRating.best,
          feedback: 'Correcto: tener un As en tu mano reduce los combos '
              'de AA y AK que el rival puede tener — exactamente sus '
              'manos de valor más probables en este spot.',
        ),
        ExerciseChoice(
          label: '8♣7♣ — no importa, la fuerza es la misma',
          rating: ExerciseRating.poor,
          feedback: '8-7 no bloquea nada de valor del rival. Entre dos '
              'manos de farol parecidas, la que bloquea sus mejores '
              'combos es la mejor elección.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Bloqueador = una carta tuya que reduce los combos '
              'posibles de una mano del rival. El As en A5 hace menos '
              'probable que tenga AA o AK.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 11.5 — Frecuencias y equilibrio (MDF)
  // ================================================================
  static InteractiveTableExercise _mdf() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'APUESTA CHICA'},
        bets: const {4: 2.0},
        cards: const {0: ['9h', '8h']},
        toAct: 0,
      ),
      board: const ['Ks', '6d', '2c'],
      potBb: 6.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(4),
      question: 'El rival apuesta chica (un tercio del bote). Si '
          'foldearas casi SIEMPRE contra apuestas así de chicas, ¿qué le '
          'estarías regalando al rival?',
      choices: const [
        ExerciseChoice(
          label: 'QUE FAROLEE CON CUALQUIER MANO Y LE FUNCIONE',
          rating: ExerciseRating.best,
          feedback: 'Correcto: contra una apuesta chica, foldear de más '
              'le permite al rival farolear con cualquier mano y ganar '
              'igual — necesitás defender una porción grande de tu rango '
              'para evitarlo.',
        ),
        ExerciseChoice(
          label: 'NADA, FOLDEAR SIEMPRE ES SEGURO',
          rating: ExerciseRating.poor,
          feedback: 'Al revés: foldear de más contra una apuesta chica es '
              'justamente lo que hace que farolearte sea gratis para el '
              'rival.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'MDF, de forma intuitiva: cuanto más chica la apuesta, '
              'más necesitás defender para que el farol no sea '
              'automáticamente rentable.',
          anchor: TableAnchor.seat(4),
        ),
      ],
    );
  }

  // ================================================================
  // 11.6 — Explotar vs equilibrio
  // ================================================================
  static InteractiveTableExercise _explotar() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'APUESTA GRANDE'},
        bets: const {4: 12.0},
        cards: const {0: ['Ks', 'Th']},
        toAct: 0,
      ),
      board: const ['Kd', '9c', '4h', '2s', '7d'],
      potBb: 12.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.exploit,
      strategyDependent: true,
      questionAnchor: const TableAnchor.seat(4),
      question: 'Ya notaste, en varias manos anteriores, que este rival '
          'NUNCA farolea el río. Apuesta grande de nuevo. Tenés top pair '
          'decente (no la mejor mano posible). ¿Jugás "equilibrado" '
          '(pagando alguna vez como bluff catcher) o explotás el '
          'patrón?',
      choices: const [
        ExerciseChoice(
          label: 'EXPLOTAR: FOLDEAR CASI SIEMPRE CONTRA ÉL',
          rating: ExerciseRating.best,
          feedback: 'Correcto: contra un patrón real y ya observado '
              '(nunca farolea), desviarte del "equilibrio" y foldear más '
              'de lo habitual gana más fichas que jugar como si fuera un '
              'rival desconocido.',
        ),
        ExerciseChoice(
          label: 'JUGAR EQUILIBRADO, PAGANDO IGUAL A VECES',
          rating: ExerciseRating.acceptable,
          feedback: 'Jugar equilibrado te protege de cualquier rival, '
              'pero contra un patrón real ya confirmado, explotarlo '
              'rinde más — no hace falta protegerte de alguien que ya '
              'sabés que no farolea.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Explotar = desviarte a propósito de lo "equilibrado" '
              'para castigar un patrón concreto que ya observaste, no '
              'uno que suponés.',
          anchor: TableAnchor.seat(4),
        ),
      ],
    );
  }
}

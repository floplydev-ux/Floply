import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 9 "Turn y river".
///
/// N9 es el primer nivel AVANZADO y el más largo de esa banda (auditoría
/// pedagógica): acá la dificultad de los ejercicios escala a propósito,
/// subnivel por subnivel — 9.1 reconocimiento simple, 9.2-9.4 decisiones
/// de una calle, 9.5 cierra con una mano completa que integra varias
/// ideas del nivel a la vez.
class N9Exercises {
  N9Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '9.1': InteractiveExerciseSet([_scareCard()]),
    '9.2': InteractiveExerciseSet([_barrel()]),
    '9.3': InteractiveExerciseSet([_valueBet()]),
    '9.4': InteractiveExerciseSet([_bluffCatcher()]),
    // 9.5 es el checkpoint del nivel: la evaluación del módulo repasa
    // scare card (turn), barrel, value bet y bluff catcher antes de
    // cerrar con su propio contenido (una mano completa que integra
    // varias calles a la vez).
    '9.5': InteractiveExerciseSet([
      _scareCard(),
      _barrel(),
      _valueBet(),
      _bluffCatcher(),
      _lineaCompleta(),
    ]),
  };

  // ================================================================
  // 9.1 — Reevaluar en el turn (fácil: reconocimiento)
  // ================================================================
  static InteractiveTableExercise _scareCard() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        cards: const {0: ['Ad', 'Ac']},
      ),
      board: const ['Ks', '9s', '4c', '2s'],
      potBb: 8.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [TableAnchor.board],
      question: 'Board K♠9♠4♣, y el turn trae el 2♠: la CUARTA pica. Para '
          'vos y para el rival, ¿esta carta es un blank o una scare '
          'card?',
      choices: const [
        ExerciseChoice(
          label: 'SCARE CARD',
          rating: ExerciseRating.best,
          feedback: 'Correcto: completa un proyecto de color VISIBLE en '
              'el board. Asusta a los dos, exista o no ese color en '
              'concreto.',
        ),
        ExerciseChoice(
          label: 'BLANK',
          rating: ExerciseRating.poor,
          feedback: 'No es un blank: la cuarta carta de un mismo palo '
              'siempre es una scare card — completa un color posible.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Con AA no completaste el color, pero la carta cambia '
              'cómo va a jugar el rival el resto de la mano igual.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 9.2 — Barrel o pot control (medio: decisión de una calle)
  // ================================================================
  static InteractiveTableExercise _barrel() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'PAGA'},
        cards: const {0: ['Kd', 'Qd']},
        toAct: 0,
      ),
      board: const ['Ks', '7d', '2c', '9h'],
      potBb: 14.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: TableAnchor.board,
      question: 'C-beteaste el flop con top pair y te pagaron. El turn (9♥) '
          'es un blank: no cambia nada real. ¿Seguís con el double '
          'barrel, o pasás?',
      choices: const [
        ExerciseChoice(
          label: 'BARREL (seguir apostando)',
          rating: ExerciseRating.best,
          feedback: 'Bien: nada cambió en contra tuyo, tu top pair sigue '
              'fuerte — sostener la presión sigue teniendo sentido.',
        ),
        ExerciseChoice(
          label: 'PASAR (pot control)',
          rating: ExerciseRating.acceptable,
          feedback: 'No es incorrecto de por sí, pero con una mano que '
              'sigue tan fuerte y un turn que no cambió nada, seguir '
              'apostando suele cobrar más valor.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Cada barrel es una decisión nueva: se revisa la carta '
              'del turn, no se repite el flop por inercia.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 9.3 — El river: valor (medio)
  // ================================================================
  static InteractiveTableExercise _valueBet() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'PAGA'},
        cards: const {0: ['9c', '9d']},
        toAct: 0,
      ),
      board: const ['9s', '6d', '2c', 'Kh', '3s'],
      potBb: 20.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Llegaste al río con un set de nueves, en un board sin '
          'proyectos peligrosos completados. El rival pagó cada calle '
          'con un rango que incluye varias parejas peores. ¿Apostás por '
          'valor?',
      choices: const [
        ExerciseChoice(
          label: 'SÍ, APOSTAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: ya no quedan cartas por venir, tenés una '
              'mano fuerte, y existen manos peores del rango del rival '
              'dispuestas a pagar. Apostar cobra ese valor.',
        ),
        ExerciseChoice(
          label: 'PASAR',
          rating: ExerciseRating.poor,
          feedback: 'Pasar acá regala valor real: un set en el río, '
              'contra un rango con manos peores que pagarían, quiere '
              'apostar.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'En el río ya no hay "todavía puede mejorar": se compara '
              'tu mano final contra el rango final del rival.',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }

  // ================================================================
  // 9.4 — River: farol y bluff-catch (difícil: lectura)
  // ================================================================
  static InteractiveTableExercise _bluffCatcher() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'APUESTA GRANDE'},
        bets: const {4: 16.0},
        cards: const {0: ['Kc', 'Kd']},
        toAct: 0,
      ),
      board: const ['Kh', '7s', '2d', '4c', '9h'],
      potBb: 16.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: const TableAnchor.seat(4),
      situationHighlight: const [TableAnchor.seat(4), TableAnchor.heroCards],
      question: 'Tenés un set de reyes en un board sin proyectos '
          'posibles (ni color ni escalera). El rival apuesta grande en el '
          'río, apostando por primera vez en toda la mano. ¿Pagás como '
          'bluff catcher?',
      choices: const [
        ExerciseChoice(
          label: 'PAGAR',
          rating: ExerciseRating.best,
          feedback: 'Razonable: tu set le gana a casi cualquier mano de '
              'valor real que el rival pudiera tener en este board — la '
              'única forma de perder es contra una mano de valor '
              'improbable. Sin proyectos posibles, una apuesta grande '
              'recién ahora también puede ser un farol tardío.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.acceptable,
          feedback: 'No es descabellado con una apuesta tan grande, pero '
              'un set en un board sin proyectos le sigue ganando a la '
              'mayoría de lo que el rival podría representar de verdad.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Bluff catcher = tu mano solo le gana a un farol. Acá la '
              'pregunta central es si la línea del rival (recién apostar '
              'en el río) parece más un farol que una mano de valor real.',
          anchor: TableAnchor.seat(4),
        ),
      ],
    );
  }

  // ================================================================
  // 9.5 — Líneas de río y polarización (integradora: mano completa)
  // ================================================================
  static InteractiveTableExercise _lineaCompleta() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'CHECK'},
        cards: const {0: ['Ah', 'Jh']},
        toAct: 0,
      ),
      board: const ['Jd', '8h', '3c', 'Qs', '5d'],
      potBb: 14.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      strategyDependent: true,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards, TableAnchor.board],
      question: 'Mano completa: abriste, c-beteaste flop y turn (pagaron '
          'las dos veces), y en el río la BB pasa. Tenés A♥J♥: top pair '
          'con buen kicker, sin proyectos peligrosos completados en el '
          'board. ¿Cuál es la mejor línea ahora?',
      choices: const [
        ExerciseChoice(
          label: 'APOSTAR VALOR (tamaño chico-medio)',
          rating: ExerciseRating.best,
          feedback: 'Bien: un check del rival suele sacar sus manos MÁS '
              'fuertes del rango (T217, N10) — tu top pair con buen '
              'kicker sigue teniendo manos peores dispuestas a pagar. Es '
              'value fino, no hace falta un tamaño enorme.',
        ),
        ExerciseChoice(
          label: 'CHECK BACK',
          rating: ExerciseRating.acceptable,
          feedback: 'No es un error grave, pero después de un check del '
              'rival, tu mano suele ganarle a suficiente rango como para '
              'que valga la pena una apuesta chica de valor.',
        ),
        ExerciseChoice(
          label: 'APOSTAR COMO FAROL PURO',
          rating: ExerciseRating.poor,
          feedback: 'No tiene sentido farolear con una mano que YA le '
              'gana a buena parte del rango del rival — esta apuesta es '
              'de valor, no de farol.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Esta mano junta todo el nivel: leer el check (9.1/N10), '
              'decidir con la mano ya hecha (9.3, value fino) y no '
              'confundirla con un farol (9.4/9.5, polarización).',
          anchor: TableAnchor.board,
        ),
      ],
    );
  }
}

import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 3.
class N3ClosingExamples {
  N3ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '3.2': _ordenDeAccion(),
  };

  // 3.2 — El orden de acción (pre y postflop)
  // Héroe en BTN (slot 0). Preflop: UTG(3)→HJ(2)→CO(1)→BTN(0)→SB(5)→BB(4).
  // Postflop (con SB/BB fuera): CO(1) actúa antes que BTN(0).
  static TableLessonScript _ordenDeAccion() {
    const labels = TableBuilder.btnHero; // 0=BTN · 1=CO · 2=HJ · 3=UTG · 4=BB · 5=SB

    TableSnapshot base({
      Map<int, double> bets = const {},
      Map<int, String> actions = const {},
      Map<int, List<String>> cards = const {},
      Set<int> folded = const {},
      int? toAct,
      List<String> board = const [],
      double? pot,
    }) =>
        TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: bets,
            actions: actions,
            cards: cards,
            folded: folded,
            toAct: toAct,
          ),
          board: board,
          potBb: pot ?? (1.5 + bets.values.fold(0.0, (a, b) => a + b)),
          buttonSlot: 0,
        );

    return TableLessonScript([
      // Paso 1 — preflop: orden horario desde UTG
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0},
          actions: const {5: 'CIEGA', 4: 'CIEGA'},
          toAct: 3, // UTG actúa primero
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [
          TableAnchor.seat(3),
          TableAnchor.seat(2),
          TableAnchor.seat(1),
          TableAnchor.heroCards,
          TableAnchor.seat(5),
          TableAnchor.seat(4),
        ],
        bubble: 'Preflop: la acción arranca en UTG y va en dirección horaria. '
            'Orden: UTG → HJ → CO → BTN → SB → BB.',
      ),
      // Paso 2 — UTG y HJ foldean, CO sube, te toca al BTN
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0, 1: 2.5},
          actions: const {5: 'CIEGA', 4: 'CIEGA', 1: 'SUBA', 3: 'FOLD', 2: 'FOLD'},
          folded: const {3, 2},
          toAct: 0, // BTN (héroe) actúa ahora
        ),
        anchor: TableAnchor.heroCards,
        bubble: 'UTG y HJ foldean. CO sube a 2,5 BB. Te toca a vos — el '
            'BTN es el penúltimo en hablar preflop.',
      ),
      // Paso 3 — héroe llama, acción pasa a SB y BB
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0, 1: 2.5, 0: 2.5},
          actions: const {5: 'CIEGA', 4: 'CIEGA', 1: 'SUBA', 3: 'FOLD', 2: 'FOLD', 0: 'CALL'},
          folded: const {3, 2},
          toAct: 5, // SB actúa ahora
        ),
        anchor: const TableAnchor.seat(5),
        highlight: const [TableAnchor.seat(5), TableAnchor.seat(4)],
        bubble: 'Llamás. Ahora SB y BB tienen que hablar — son los últimos '
            'en el orden preflop. Tienen que igualar la suba o irse.',
      ),
      // Paso 4 — flop, postflop: CO actúa antes que BTN
      TableStep(
        table: base(
          bets: const {},
          actions: const {},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['Ah', 'Kd'], 1: ['?', '?']},
          board: const ['Qc', '7s', '2h'],
          pot: 6.5,
          toAct: 1, // CO actúa primero postflop
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.seat(1)],
        bubble: 'Llega el flop. Postflop el orden cambia: actúa primero el '
            'jugador activo más a la izquierda del BTN. Aquí es CO — habla '
            'antes que vos.',
      ),
      // Paso 5 — BTN actúa último postflop (ventaja de posición)
      TableStep(
        table: base(
          bets: const {1: 3.0},
          actions: const {1: 'APUESTA'},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['Ah', 'Kd'], 1: ['?', '?']},
          board: const ['Qc', '7s', '2h'],
          pot: 9.5,
          toAct: 0, // BTN actúa último
        ),
        anchor: TableAnchor.heroCards,
        bubble: 'CO apostó. Ahora te toca a vos — el BTN siempre actúa '
            'ÚLTIMO postflop. Esa es la ventaja de la posición: decidís '
            'con toda la información disponible.',
      ),
    ]);
  }
}

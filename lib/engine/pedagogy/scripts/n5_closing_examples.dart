import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 5 (5.4 y 5.6).
class N5ClosingExamples {
  N5ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '5.4': _tamanioDeApertura(),
    '5.6': _contraLimpers(),
  };

  static const _labels = TableBuilder.btnHero;

  // ================================================================
  // 5.4 — El tamaño de apertura
  // Héroe en BTN abre a distintos tamaños; la mesa muestra el bote resultante.
  // ================================================================
  static TableLessonScript _tamanioDeApertura() {
    TableSnapshot base({
      Map<int, double> bets = const {},
      Map<int, String> actions = const {},
      Set<int> folded = const {},
      int? toAct,
      double pot = 1.5,
    }) =>
        TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            bets: {5: 0.5, 4: 1.0, ...bets},
            actions: {5: 'CIEGA', 4: 'CIEGA', ...actions},
            folded: folded,
            toAct: toAct,
          ),
          potBb: pot,
          buttonSlot: 0,
        );

    return TableLessonScript([
      // Paso 1 — las ciegas ya están, es tu turno (BTN, primero actúa UTG)
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0},
          folded: const {3, 2, 1},
          toAct: 0,
          pot: 1.5,
        ),
        anchor: TableAnchor.heroCards,
        bubble: 'UTG, HJ y CO foldean. Te toca a vos desde el BTN — tenés '
            'position sobre todos. Ahora decidís cuánto abrís.',
      ),
      // Paso 2 — apertura 2x
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0, 0: 2.0},
          actions: const {0: 'SUBA'},
          folded: const {3, 2, 1},
          pot: 3.5,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0), TableAnchor.pot],
        bubble: 'APERTURA 2x: subís a 2 BB (el doble de la ciega). '
            'Bote total: 3,5 BB. Es un tamaño agresivo y efectivo '
            'en las mesas modernas, especialmente desde el BTN.',
      ),
      // Paso 3 — apertura 2.5x
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0, 0: 2.5},
          actions: const {0: 'SUBA'},
          folded: const {3, 2, 1},
          pot: 4.0,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0), TableAnchor.pot],
        bubble: 'APERTURA 2.5x: subís a 2,5 BB. Bote: 4 BB. '
            'Tamaño más común en posición tardía (CO, BTN). '
            'Equilibra extraer valor y no armar un bote enorme con manos débiles.',
      ),
      // Paso 4 — apertura 3x
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0, 0: 3.0},
          actions: const {0: 'SUBA'},
          folded: const {3, 2, 1},
          pot: 4.5,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0), TableAnchor.pot],
        bubble: 'APERTURA 3x: subís a 3 BB. Bote: 4,5 BB. '
            'Tamaño estándar en posición temprana (UTG, HJ). '
            'Más grande porque hay más jugadores activos detrás.',
      ),
      // Paso 5 — el rango del tamaño correcto
      TableStep(
        table: base(
          bets: const {5: 0.5, 4: 1.0, 0: 2.5},
          actions: const {0: 'SUBA'},
          folded: const {3, 2, 1},
          pot: 4.0,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Regla práctica: abrí entre 2 BB y 3 BB. Más pequeño y '
            'das odds baratos a todos; más grande y solo jugás botes '
            'gigantes con manos marginales.',
      ),
    ]);
  }

  // ================================================================
  // 5.6 — Contra limpers / iso raise
  // ================================================================
  static TableLessonScript _contraLimpers() {
    TableSnapshot base({
      Map<int, double> bets = const {},
      Map<int, String> actions = const {},
      Set<int> folded = const {},
      int? toAct,
      double? pot,
    }) =>
        TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            bets: {5: 0.5, 4: 1.0, ...bets},
            actions: {5: 'CIEGA', 4: 'CIEGA', ...actions},
            folded: folded,
            toAct: toAct,
          ),
          potBb: pot ?? (1.5 + bets.values.fold(0.0, (a, b) => a + b)),
          buttonSlot: 0,
        );

    return TableLessonScript([
      // Paso 1 — qué es un limp
      TableStep(
        table: base(
          bets: const {3: 1.0},
          actions: const {3: 'LIMP'},
          folded: const {2, 1},
          toAct: 0,
          pot: 2.5,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.seat(3)],
        bubble: 'LIMP: entrar al bote igualando la ciega grande (1 BB) sin '
            'subirla. UTG limpea — entra barato, pero sin iniciar acción. '
            'Es una jugada pasiva.',
      ),
      // Paso 2 — isolation raise (ISO)
      TableStep(
        table: base(
          bets: const {3: 1.0, 0: 3.5},
          actions: const {3: 'LIMP', 0: 'ISO'},
          folded: const {2, 1},
          toAct: 5,
          pot: 6.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.bet(0)],
        bubble: 'ISO RAISE: subís más grande para jugar la mano de a dos '
            'con el limper. 3-4 BB es típico. Buscás que SB, BB y UTG '
            'foldeen para tener posición sobre UTG.',
      ),
      // Paso 3 — SB y BB foldean, va heads-up contra el limper
      TableStep(
        table: base(
          bets: const {3: 3.5, 0: 3.5},
          actions: const {3: 'CALL', 0: 'ISO'},
          folded: const {2, 1, 5, 4},
          pot: 8.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(3)],
        bubble: 'SB y BB foldean. UTG llama. Resultado buscado: jugás '
            'heads-up contra el limper CON posición. Tenés más '
            'información que él postflop.',
      ),
      // Paso 4 — cuándo overlimp
      TableStep(
        table: base(
          bets: const {3: 1.0, 2: 1.0, 0: 1.0},
          actions: const {3: 'LIMP', 2: 'LIMP', 0: 'LIMP'},
          folded: const {1},
          toAct: 5,
          pot: 4.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'OVERLIMP: si ya hay varios limpers y tu mano especulativa '
            '(conectores, pares pequeños) paga la llamada, a veces conviene '
            'entrar barato buscando un bote multiway.',
      ),
      // Paso 5 — el bote limpeado postflop
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['9h', '8h']},
            folded: const {2, 1, 5, 4},
          ),
          board: const ['7d', '6c', 'Ks'],
          potBb: 4.5,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'En un bote limpeado los stacks siguen profundos y el bote '
            'es chico. Postflop, una apuesta de continuation con tus '
            'manos fuertes o draws captura ese bote con frecuencia.',
      ),
    ]);
  }
}

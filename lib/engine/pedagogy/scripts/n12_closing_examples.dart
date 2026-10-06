import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 12 (Checklists integradas).
class N12ClosingExamples {
  N12ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '12.1': _checklistLectura(),
    '12.2': _checklistDecision(),
    '12.3': _integradoPreflop(),
    '12.4': _integradoPostflop(),
  };

  static const _labels = TableBuilder.btnHero;

  static TableSnapshot _street({
    required List<String> board,
    required List<String> hero,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    Set<int> folded = const {5, 4, 3, 2},
    double pot = 20,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          cards: {0: hero, 1: const ['?', '?']},
          bets: bets,
          actions: actions,
          folded: folded,
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  static TableSnapshot _preflop({
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    Set<int> folded = const {},
    Map<int, List<String>> cards = const {},
    int? toAct,
    double pot = 1.5,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          bets: {5: 0.5, 4: 1.0, ...bets},
          actions: {5: 'CIEGA', 4: 'CIEGA', ...actions},
          cards: cards,
          folded: folded,
          toAct: toAct,
        ),
        potBb: pot,
        buttonSlot: 0,
      );

  // 12.1 — Checklist de lectura (¿qué hay en la mesa?)
  static TableLessonScript _checklistLectura() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
          pot: 30,
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'CHECKLIST DE LECTURA — 1. ¿Cómo es el board? '
            'K-7-2 rainbow: seco, pocos draws. '
            'El que conectó K tiene ventaja clara. Board sin flush ni escalera possible.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
          pot: 30,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.seat(1), TableAnchor.bet(1)],
        bubble: '2. ¿Qué historia contó el rival? '
            'CO llamó preflop, chequea flop, apuesta turn. '
            'Historia: o conectó algo en el turn (A, par de 7), '
            'o apostó en la calle que "da más miedo".',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
          pot: 30,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: '3. ¿Cuál es mi mano? AK = top pair, kicker as. '
            '4. ¿Cuál es el bote vs la apuesta? 30 vs 10 → pot odds 25%. '
            '5. ¿Es mi mano lo suficientemente fuerte? '
            'Top pair kicker as en K-7-2 → sí, call o subida.',
      ),
    ]);
  }

  // 12.2 — Checklist de decisión (¿qué hago?)
  static TableLessonScript _checklistDecision() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As'],
          hero: const ['Kd', '9h'],
          bets: const {1: 15.0},
          actions: const {1: 'APUESTA'},
          pot: 35,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Tenés K9 (top pair, kicker 9) en K-7-2-A. El rival apuesta. '
            'CHECKLIST: 1. ¿Cuántas manos que me ganan hay en su rango? '
            'AK, A7, A2 (dos pares) — varias manos te superan.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As'],
          hero: const ['Kd', '9h'],
          bets: const {1: 15.0},
          actions: const {1: 'APUESTA'},
          pot: 35,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.bet(1)],
        bubble: '2. ¿Cuántas manos que me pierden hay en su rango? '
            'KQ, KJ, K8 (kicker peor). Si llama mucho, tiene manos débiles también. '
            '3. ¿Mis pot odds justifican llamar? '
            '15 / 50 = 30%. ¿Ganás más del 30% contra su rango?',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As'],
          hero: const ['Kd', '9h'],
          bets: const {1: 15.0},
          actions: const {1: 'APUESTA'},
          pot: 35,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: '4. ¿Qué pasa si llamo y viene otra calle costosa? '
            'Con K9 en K-A-7-2 estás en posición vulnerable. '
            'Conclusión: call marginal / fold defensivo. '
            'No todas las manos hechas justifican continuar.',
      ),
    ]);
  }

  // 12.3 — Mano integrada preflop
  static TableLessonScript _integradoPreflop() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {3: 2.5},
          actions: const {3: 'SUBA'},
          folded: const {2, 1},
          cards: const {0: ['Jh', 'Td']},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(3)],
        bubble: 'UTG abre a 2,5 BB. En BTN con JTo. '
            'CHECKLIST PREFLOP: 1. ¿Cuál es el rango de UTG? Estrecho — '
            'premium y conectores buenos. 2. ¿Mi posición? BTN, actúo último postflop.',
      ),
      TableStep(
        table: _preflop(
          bets: const {3: 2.5},
          actions: const {3: 'SUBA'},
          folded: const {2, 1},
          cards: const {0: ['Jh', 'Td']},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: '3. ¿Mi mano funciona bien contra ese rango? '
            'JTo es especulativo, puede quedar dominado por AJ, KJ. '
            '4. ¿El precio vale? 2,5 BB para un bote de ~7 BB postflop. '
            '5. Decisión: CALL — posición compensa el riesgo de dominio.',
      ),
      TableStep(
        table: _street(
          board: const ['Jh', '8d', '4c'],
          hero: const ['Jd', 'Td'],
          pot: 6.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Flop J-8-4. Pegaste top pair. '
            'Continuidad del análisis postflop: ¿el rival puede tener manos '
            'que te ganan? AJ lo gana. KK lo gana. '
            'Si chequea, apostás para información y valor.',
      ),
    ]);
  }

  // 12.4 — Mano integrada postflop
  static TableLessonScript _integradoPostflop() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Qh', '9d', '3c'],
          hero: const ['Kh', 'Qd'],
          bets: const {1: 5.0},
          actions: const {1: 'C-BET'},
          pot: 15,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'CO c-bet en Q-9-3. Tenés KQ (top pair, kicker rey). '
            'ANÁLISIS COMPLETO: '
            '1. Board: semirrpido, posible escalera 9-T-J. '
            '2. Mano: top pair kicker K — muy fuerte.',
      ),
      TableStep(
        table: _street(
          board: const ['Qh', '9d', '3c'],
          hero: const ['Kh', 'Qd'],
          bets: const {1: 5.0, 0: 14.0},
          actions: const {1: 'C-BET', 0: 'CHECK-RAISE'},
          pot: 29,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: '3. Acción: CHECK-RAISE. Chequeas, CO apuesta, subís. '
            '¿Por qué? Tenés mano muy fuerte en un board donde el rival '
            'puede tener draws. El check-raise construye el bote y '
            'cobra un precio a sus draws.',
      ),
      TableStep(
        table: _street(
          board: const ['Qh', '9d', '3c'],
          hero: const ['Kh', 'Qd'],
          bets: const {1: 5.0, 0: 14.0},
          actions: const {1: 'C-BET', 0: 'CHECK-RAISE'},
          pot: 29,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: '4. Plan para el turn/river: si llama, apostás big en el turn '
            'con boards inofensivos. Si sube → fold (tiene set o mejor). '
            'Cada calle actualiza el análisis — la decisión de hoy '
            'depende de las calles anteriores.',
      ),
    ]);
  }
}

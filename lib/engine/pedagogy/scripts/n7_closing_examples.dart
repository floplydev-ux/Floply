import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 7 (Preflop: calls, 3-bets, 4-bets).
class N7ClosingExamples {
  N7ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '7.1': _callOFold(),
    '7.2': _tresBetValorFarol(),
    '7.3': _anatomiaBot3Bet(),
    '7.4': _responder3bet(),
  };

  static const _labels = TableBuilder.btnHero;
  // slot 0=BTN(héroe) · 1=CO · 2=HJ · 3=UTG · 4=BB · 5=SB

  static TableSnapshot _preflop({
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    Set<int> folded = const {},
    Map<int, List<String>> cards = const {},
    int? toAct,
    double? pot,
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
        potBb: pot ?? (1.5 + bets.values.fold(0.0, (a, b) => a + b)),
        buttonSlot: 0,
      );

  // ================================================================
  // 7.1 — ¿Call o fold contra un open?
  // ================================================================
  static TableLessonScript _callOFold() {
    return TableLessonScript([
      // Paso 1 — UTG abre, llega a BTN
      TableStep(
        table: _preflop(
          bets: const {3: 2.5},
          actions: const {3: 'SUBA'},
          folded: const {2, 1},
          cards: const {0: ['Kh', 'Jd']},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(3)],
        bubble: 'UTG abre a 2,5 BB. HJ y CO foldean. Te toca a vos en el BTN '
            'con K♥J♦. Tenés posición sobre UTG — eso suma valor al call.',
      ),
      // Paso 2 — la posición importa: call en el BTN
      TableStep(
        table: _preflop(
          bets: const {3: 2.5, 0: 2.5},
          actions: const {3: 'SUBA', 0: 'CALL'},
          folded: const {2, 1, 5, 4},
          cards: const {0: ['Kh', 'Jd']},
          pot: 6.5,
        ),
        anchor: TableAnchor.heroCards,
        bubble: 'Llamás. KJo en el BTN vs UTG es call razonable: tenés '
            'posición postflop y mano broadway. En early position sin '
            'ventaja posicional, sería fold.',
      ),
      // Paso 3 — el tamaño del open cambia la decisión
      TableStep(
        table: _preflop(
          bets: const {3: 4.0},
          actions: const {3: 'SUBA'},
          folded: const {2, 1},
          cards: const {0: ['Kh', 'Jd']},
          toAct: 0,
          pot: 5.5,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.bet(3)],
        bubble: 'Si UTG abre a 4 BB en vez de 2,5 BB, el precio sube. '
            'KJo pierde valor: tenés que ganar más veces para recuperar '
            'lo invertido. Muchas veces convierte en fold.',
      ),
      // Paso 4 — ciega contra ciega
      TableStep(
        table: _preflop(
          bets: const {5: 2.5},
          actions: const {5: 'SUBA'},
          folded: const {3, 2, 1, 0},
          cards: const {4: ['Kh', 'Jd']},
          toAct: 4,
          pot: 3.0,
        ),
        anchor: const TableAnchor.seat(4),
        highlight: const [TableAnchor.seat(4), TableAnchor.seat(5)],
        bubble: 'SB abre y vos estás en la BB: es el único caso donde '
            'tenés que actuar primero postflop aunque hayas pagado. '
            'Podés pagar más amplio porque cerrás la acción preflop.',
      ),
    ]);
  }

  // ================================================================
  // 7.2 — 3-bet: valor y farol
  // ================================================================
  static TableLessonScript _tresBetValorFarol() {
    return TableLessonScript([
      // Paso 1 — CO abre, BTN 3-betea por valor
      TableStep(
        table: _preflop(
          bets: const {1: 2.5, 0: 8.0},
          actions: const {1: 'SUBA', 0: '3-BET'},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['Ah', 'Ad']},
          toAct: 1,
          pot: 10.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.bet(0)],
        bubble: 'CO abre a 2,5 BB. Tenés AA → 3-bet a 8 BB. '
            '3-BET POR VALOR: subís con las manos más fuertes para '
            'construir un bote grande con ventaja.',
      ),
      // Paso 2 — 3-bet como farol con A5s
      TableStep(
        table: _preflop(
          bets: const {1: 2.5, 0: 8.0},
          actions: const {1: 'SUBA', 0: '3-BET'},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['As', '5s']},
          toAct: 1,
          pot: 10.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: '3-BET COMO FAROL con A5s: mano que tiene poco valor de '
            'call pero bloquea el rango de AA, AK y KK del rival '
            '(tenés un as). Si foldea, ganás. Si paga, tenés equity y '
            'podés mejorar a color.',
      ),
      // Paso 3 — rango polarizado
      TableStep(
        table: _preflop(
          bets: const {1: 2.5, 0: 8.0},
          actions: const {1: 'SUBA', 0: '3-BET'},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['?', '?']},
          toAct: 1,
          pot: 10.5,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Rango de 3-bet equilibrado: manos premium (AA-QQ, AKs) '
            'para valor + manos especulativas con bloqueador (A5s, A4s) '
            'para farol. Las manos medianas (KQ, JTs) suelen llamar, '
            'no 3-betear.',
      ),
      // Paso 4 — el squeeze
      TableStep(
        table: _preflop(
          bets: const {3: 2.5, 2: 2.5, 0: 9.0},
          actions: const {3: 'SUBA', 2: 'CALL', 0: 'SQUEEZE'},
          folded: const {1, 5, 4},
          cards: const {0: ['Kh', 'Ks']},
          toAct: 3,
          pot: 13.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.bet(0)],
        bubble: 'SQUEEZE: hay un open y uno o más calls. '
            'Subís más grande porque hay más fichas en el bote. '
            'Todos tienen que foldear o pagar un precio enorme. '
            'Muy efectivo con manos fuertes.',
      ),
    ]);
  }

  // ================================================================
  // 7.3 — Anatomía del bote 3-bet
  // ================================================================
  static TableLessonScript _anatomiaBot3Bet() {
    return TableLessonScript([
      // Paso 1 — construcción del bote 3-bet
      TableStep(
        table: _preflop(
          bets: const {1: 8.0, 0: 8.0},
          actions: const {1: 'CALL 3B', 0: '3-BET'},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['Ah', 'Kd'], 1: ['?', '?']},
          pot: 17.5,
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot],
        bubble: 'CO abre 2,5 → BTN 3-betea a 8 → CO llama. '
            'Bote preflop: 17,5 BB. Los stacks efectivos bajaron a ~92 BB. '
            'Es un bote grande antes de ver el flop.',
      ),
      // Paso 2 — SPR (stack-to-pot ratio)
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Ah', 'Kd'], 1: const ['?', '?']},
            folded: const {3, 2, 5, 4},
            stacks: const {0: 92, 1: 92},
          ),
          board: const ['Ks', '7h', '2d'],
          potBb: 17.5,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot],
        bubble: 'En el flop: SPR = stack / bote = 92 / 17,5 ≈ 5. '
            'SPR bajo → decisiones más simples (all-in con top pair fuerte). '
            'SPR alto → más calles para navegar.',
      ),
      // Paso 3 — rango del 3-bettor
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Ah', 'Kd'], 1: const ['?', '?']},
            folded: const {3, 2, 5, 4},
          ),
          board: const ['Ks', '7h', '2d'],
          potBb: 17.5,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'En un bote 3-bet el rango del 3-bettor (vos) es polarizado: '
            'manos muy fuertes o manos especulativas. '
            'El que llama la 3-bet tiene un rango más lineal y denso.',
      ),
      // Paso 4 — posición en el bote 3-bet
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Ah', 'Kd'], 1: const ['?', '?']},
            folded: const {3, 2, 5, 4},
          ),
          board: const ['Ks', '7h', '2d'],
          potBb: 17.5,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'BTN vs CO: el BTN tiene posición en todos los calles. '
            'Eso vale mucho en botes grandes — podés hacer calls más '
            'amplios y detectar weakness del rival más fácilmente.',
      ),
    ]);
  }

  // ================================================================
  // 7.4 — Responder a una 3-bet / 4-bet
  // ================================================================
  static TableLessonScript _responder3bet() {
    return TableLessonScript([
      // Paso 1 — abrís UTG, BTN 3-betea
      TableStep(
        table: _preflop(
          bets: const {3: 2.5, 0: 8.0},
          actions: const {3: 'SUBA', 0: '3-BET'},
          folded: const {2, 1, 5, 4},
          cards: const {3: ['Kh', 'Qd']},
          toAct: 3,
          pot: 10.5,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.seat(3), TableAnchor.seat(0)],
        bubble: 'Abriste UTG con KQo a 2,5 BB. BTN sube a 8 BB. '
            'Tenés tres opciones: fold, call o 4-bet. '
            'Con KQo desde UTG, la mayoría foldea aquí.',
      ),
      // Paso 2 — fold con mano marginal
      TableStep(
        table: _preflop(
          bets: const {0: 8.0},
          actions: const {3: 'FOLD', 0: '3-BET'},
          folded: const {2, 1, 5, 4, 3},
          cards: const {},
          pot: 10.5,
        ),
        anchor: const TableAnchor.seat(0),
        bubble: 'Fold: KQo está dominado por mucho del rango de 3-bet del BTN '
            '(AA, KK, QQ, AK). Cuando el rival muestra fuerza desde el BTN '
            'contra un open UTG, el rango es apretado.',
      ),
      // Paso 3 — 4-bet por valor
      TableStep(
        table: _preflop(
          bets: const {3: 22.0, 0: 8.0},
          actions: const {0: '3-BET', 3: '4-BET'},
          folded: const {2, 1, 5, 4},
          cards: const {3: ['Ah', 'As']},
          toAct: 0,
          pot: 30.0,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.bet(3)],
        bubble: '4-BET POR VALOR: con AA o KK, subís a ~22 BB. '
            'El bote crece a 30 BB y generalmente termina en all-in preflop. '
            'Es la respuesta correcta con manos premium.',
      ),
      // Paso 4 — 4-bet como farol
      TableStep(
        table: _preflop(
          bets: const {3: 22.0, 0: 8.0},
          actions: const {0: '3-BET', 3: '4-BET'},
          folded: const {2, 1, 5, 4},
          cards: const {3: ['As', '5s']},
          toAct: 0,
          pot: 30.0,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.seat(3)],
        bubble: '4-BET COMO FAROL: A5s tiene el bloqueador del as y '
            'es difícil que el BTN tenga AA o AK (vos tenés un as). '
            'Farolear aquí es rentable si el rival 3-betea amplio y '
            'puede foldear ante una resistencia fuerte.',
      ),
    ]);
  }
}

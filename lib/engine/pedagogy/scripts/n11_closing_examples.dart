import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 11 (Ventajas y GTO básico).
class N11ClosingExamples {
  N11ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '11.1': _ventajas(),
    '11.2': _stacksYSpr(),
    '11.3': _polarizacionYCondensacion(),
    '11.4': _bloqueadores(),
    '11.5': _frecuenciasYMdf(),
    '11.6': _explotarVsGto(),
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

  // 11.1 — Las tres ventajas
  static TableLessonScript _ventajas() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'As'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'VENTAJA DE RANGO: cuando tus manos son sistemáticamente '
            'más fuertes que las del rival en este board. '
            'El que abrió UTG tiene más KK, AA, AK en su rango que el que llamó.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Kd', 'Kc'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'VENTAJA DE NUTS: cuando tenés acceso a las manos '
            'más fuertes del board. K-7-2: el que tiene KK o 77 o 22 '
            '(set) tiene ventaja de nuts — solo ciertos rangos las incluyen.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 8.0},
          actions: const {1: 'APUESTA'},
          pot: 28,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'VENTAJA POSICIONAL: el BTN actúa último postflop — ve la '
            'acción del rival antes de decidir. Si el rival apuesta, '
            'podés pagar o subir con más información. Vale mucho en calles grandes.',
      ),
    ]);
  }

  // 11.2 — Stacks y SPR
  static TableLessonScript _stacksYSpr() {
    return TableLessonScript([
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Ah', 'Kd'], 1: const ['?', '?']},
            folded: const {5, 4, 3, 2},
            stacks: const {0: 100, 1: 100},
          ),
          board: const ['Kh', '7d', '2c'],
          potBb: 10,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot],
        bubble: 'SPR = stack efectivo / bote. '
            'Stack: 100 BB. Bote: 10 BB. SPR = 10. '
            'SPR ALTO: hay mucho dinero por apostar relativo al bote — '
            'cada calle importa, hay espacio para maniobrar.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Ah', 'Kd'], 1: const ['?', '?']},
            folded: const {5, 4, 3, 2},
            stacks: const {0: 30, 1: 30},
          ),
          board: const ['Kh', '7d', '2c'],
          potBb: 17,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot],
        bubble: 'SPR = 30 / 17 ≈ 1,8. SPR BAJO (bote 3-bet): '
            'top pair fuerte justifica ir all-in. '
            'Con SPR bajo, manos "medias" como AK se juegan directas.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['7h', '7d'], 1: const ['?', '?']},
            folded: const {5, 4, 3, 2},
            stacks: const {0: 100, 1: 100},
          ),
          board: const ['Kh', '8d', '3c'],
          potBb: 10,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'SPR alto (10) con par de 7s en K-8-3: mano mediana en un '
            'board coordinado. Con SPR alto, podés fold/call selectivo '
            '— no hay urgencia de meter todo. Con SPR bajo, sería más difícil.',
      ),
    ]);
  }

  // 11.3 — Rangos polarizados y condensados
  static TableLessonScript _polarizacionYCondensacion() {
    return TableLessonScript([
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
        highlight: const [TableAnchor.bet(0)],
        bubble: 'RANGO POLARIZADO: el 3-bettor tiene manos extremas — '
            'muy fuertes (AA, KK, AKs) O muy especulativas (A5s, A4s bluff). '
            'Las manos medias (KQ, JTs) suelen quedar fuera.',
      ),
      TableStep(
        table: _preflop(
          bets: const {1: 2.5, 0: 2.5},
          actions: const {1: 'SUBA', 0: 'CALL'},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['?', '?']},
          pot: 6.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'RANGO CONDENSADO: el que llama la apertura tiene manos '
            'medianas sólidas — KQ, JTs, 99-55, AJ. '
            'Sin los extremos (AA fold → 3-bet; 72o fold → fold). '
            'Rango "apretado en el centro".',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kd', '8h'],
          bets: const {1: 25.0},
          actions: const {1: 'APUESTA'},
          pot: 50,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'En el river, quien apuesta tiene RANGO POLARIZADO: '
            'valor (AK, K9, set) o farol (draw fallido). '
            'Quien chequea tiene RANGO CONDENSADO: manos medias '
            'que no quieren apostar pero tampoco foldearon.',
      ),
    ]);
  }

  // 11.4 — Bloqueadores
  static TableLessonScript _bloqueadores() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {3: 2.5, 1: 2.5, 0: 9.0},
          actions: const {3: 'SUBA', 1: 'CALL', 0: 'SQUEEZE'},
          folded: const {2, 5, 4},
          cards: const {0: ['As', '5s']},
          toAct: 3,
          pot: 13.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'BLOQUEADOR: tenés A♠5♠. El as que tenés reduce la probabilidad '
            'de que UTG tenga AA o AK (solo quedan 3 ases en el mazo). '
            'Bloqueás las manos con las que el rival llamaría un squeeze.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', 'Qh', '7h'],
          hero: const ['Ah', 'Tc'],
          bets: const {0: 15.0},
          actions: const {0: 'FAROL'},
          pot: 35,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Board K♥Q♥7♥ (monotono). Tenés A♥: bloqueás el color '
            'del rival. Si el rival tiene un color de corazones, necesita '
            'que vos no tengas el as. El A♥ reduce la posibilidad de que llame.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Ah', 'Kd'],
          bets: const {0: 25.0},
          actions: const {0: 'VALUE BET'},
          pot: 50,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Con AK tenés bloqueadores de valor: bloqueás AK del rival '
            '(no puede tener dos pares AK igual que vos), bloqueás AA. '
            'Los bloqueadores también afectan al apostador — reducen tu valor '
            'de algunos combos, pero AK sigue siendo mano fuerte para apostar.',
      ),
    ]);
  }

  // 11.5 — Frecuencias y MDF
  static TableLessonScript _frecuenciasYMdf() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Qd'],
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
          pot: 20,
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot, TableAnchor.bet(1)],
        bubble: 'MDF (Minimum Defense Frequency): cuántas veces tenés que '
            'defender para que el rival no gane apostando cualquier mano. '
            'Formula: MDF = bote / (bote + apuesta) = 20 / (20+10) = 67%.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Qd'],
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
          pot: 20,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Si foldeas más del 33% del tiempo, el rival gana apostando '
            'cualquier carta. Si defendés (call + raise) más del 67%, '
            'el rival necesita tener manos reales para ganar.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Qd'],
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
          pot: 20,
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'El MDF no significa llamar todo — algunos pares débiles '
            'y cartas altas sin proyecto deberían foldearse de todas formas. '
            'La clave es defender con las manos correctas '
            'hasta alcanzar la frecuencia de defensa mínima.',
      ),
    ]);
  }

  // 11.6 — Explotar vs GTO
  static TableLessonScript _explotarVsGto() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Qd'],
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'GTO (Game Theory Optimal): estrategia equilibrada que no '
            'puede ser explotada. Combinás valor y farol en proporciones '
            'matemáticamente correctas. El rival no puede ganar explotando tus frecuencias.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Qd'],
          bets: const {0: 10.0},
          actions: const {0: 'APUESTA'},
          pot: 30,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'EXPLOTACIÓN: si el rival es predecible, te desviás de GTO '
            'para explotar su error. Rival que fold siempre → apostás más faroles. '
            'Rival que llama siempre → eliminás faroles, solo apostás valor.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Qd'],
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'En NL2 (el nivel de inicio) los rivales tienen errores claros. '
            'La explotación es más rentable que GTO puro — identificás '
            'el error más frecuente y lo explotás. GTO es el punto de partida '
            'para entender por qué la explotación funciona.',
      ),
    ]);
  }
}

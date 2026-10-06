import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 6 (Matemática básica).
class N6ClosingExamples {
  N6ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '6.1': _outs(),
    '6.2': _equity(),
    '6.3': _reglaDelDos(),
    '6.4': _precioDeContinuar(),
    '6.5': _potOdds(),
    '6.6': _ev(),
    '6.7': _evDeAccion(),
  };

  static const _labels = TableBuilder.btnHero;

  static TableSnapshot _sd({
    required List<String> board,
    required List<String> hero,
    required List<String> rival,
    double pot = 20,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          folded: const {5, 4, 2, 1},
          cards: {0: hero, 3: rival},
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  static TableSnapshot _hero({
    required List<String> hero,
    required List<String> board,
    double pot = 20,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          cards: {0: hero, 1: const ['?', '?']},
          folded: const {5, 4, 3, 2},
          bets: bets,
          actions: actions,
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  // ================================================================
  // 6.1 — Outs
  // ================================================================
  static TableLessonScript _outs() {
    return TableLessonScript([
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Tenés K♥Q♥ con board A♥8♥3♦. '
            'Ya tenés 4 corazones — solo falta uno más para el color. '
            'Cada carta que completa tu mano se llama OUT.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'Hay 13 corazones en total. Ya ves 4 (K♥Q♥A♥8♥). '
            'Quedan 9 corazones escondidos en el mazo — esos son tus '
            '9 OUTS para el color.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Jh', 'Tc'],
          board: const ['Qd', '9s', '3h'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'OUT SUCIO: J♥T♣ con board Q♦9♠3♥. '
            'Un 8 o un K completan tu escalera (8 outs), pero si '
            'el rival tiene un corazón, esa carta también le mejora '
            'el proyecto de color — out "sucio".',
      ),
    ]);
  }

  // ================================================================
  // 6.2 — Equity
  // ================================================================
  static TableLessonScript _equity() {
    return TableLessonScript([
      TableStep(
        table: _sd(
          board: const ['?', '?', '?', '?', '?'],
          hero: const ['Ah', 'Kd'],
          rival: const ['Jh', 'Jd'],
          pot: 20,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'EQUITY: el porcentaje de veces que tu mano gana si se '
            'juega hasta el showdown. AK vs JJ antes del flop: '
            'AK tiene aprox. 43% y JJ tiene 57%.',
      ),
      TableStep(
        table: _sd(
          board: const ['As', '7c', '2d'],
          hero: const ['Ah', 'Kd'],
          rival: const ['Jh', 'Jd'],
          pot: 20,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'En el flop A-7-2: AK mejoró a top pair. La equity de AK '
            'subió a ~80% — las JJ solo ganan si cae una J en el turn '
            'o el river.',
      ),
      TableStep(
        table: _sd(
          board: const ['As', '7c', '2d', 'Jh'],
          hero: const ['Ah', 'Kd'],
          rival: const ['Jh', 'Jd'],
          pot: 20,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.seat(3), TableAnchor.board],
        bubble: 'Turn J♥: {UTG} mejoró a set de jotas. Ahora la equity '
            'cambia: JJ tiene ~85%. La equity no es fija — varía '
            'con cada carta que cae.',
      ),
    ]);
  }

  // ================================================================
  // 6.3 — Estimar rápido (regla del 2 y del 4)
  // ================================================================
  static TableLessonScript _reglaDelDos() {
    return TableLessonScript([
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Tenés un flush draw con 9 outs y quedan turn Y river. '
            'REGLA DEL 4: outs × 4 ≈ equity. '
            '9 × 4 = 36%. Tenés aprox. 36% de probabilidad de mejorar.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d', '5c'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Turn 5♣: no completaste el color. Ahora solo queda el river. '
            'REGLA DEL 2: outs × 2 ≈ equity. '
            '9 × 2 = 18%. Solo una carta más — la mitad de probabilidad.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Jc', 'Th'],
          board: const ['Qd', '9s', '3h'],
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'Regla de bolsillo: escalera abierta = 8 outs → '
            '8×4 ≈ 32% en el flop, 8×2 ≈ 16% en el turn. '
            'Color = 9 outs → 36% en flop, 18% en turn.',
      ),
    ]);
  }

  // ================================================================
  // 6.4 — El precio de continuar
  // ================================================================
  static TableLessonScript _precioDeContinuar() {
    return TableLessonScript([
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.bet(1),
        highlight: const [TableAnchor.bet(1), TableAnchor.pot],
        bubble: 'Bote: 20 BB. CO apuesta 10 BB. '
            'Para seguir en la mano tenés que PAGAR 10 BB.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 30,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot],
        bubble: 'Si pagás, el bote TOTAL será 20 + 10 (apuesta) + 10 (tu call) '
            '= 40 BB. Ese bote total es el premio que ganás si ganás la mano.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Precio del call: 10 BB. Premio potencial: 40 BB. '
            'Antes de pagar, tenés que preguntarte: "¿mi mano '
            'gana suficientes veces para que esto sea rentable?"',
      ),
    ]);
  }

  // ================================================================
  // 6.5 — Pot odds
  // ================================================================
  static TableLessonScript _potOdds() {
    return TableLessonScript([
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot, TableAnchor.bet(1)],
        bubble: 'POT ODDS: el bote ofrece 20 BB + 10 BB = 30 BB. '
            'Tenés que pagar 10 BB. La fracción es '
            '10 / (30 + 10) = 10 / 40 = 25%. '
            'Necesitás ganar más del 25% de las veces.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Tu equity con el flush draw: 9 outs × 2 (solo el turn) '
            '≈ 18% — menor al 25% requerido. '
            'En el river no tenés odds suficientes para pagar solo por el color.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Pero en el FLOP con dos cartas por venir: 9 × 4 ≈ 36%. '
            '36% > 25% → los pot odds justifican pagar. '
            'Misma apuesta, diferente calle, diferente decisión.',
      ),
    ]);
  }

  // ================================================================
  // 6.6 — EV
  // ================================================================
  static TableLessonScript _ev() {
    return TableLessonScript([
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 30,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.pot],
        bubble: 'EV (Expected Value): el promedio de lo que ganás o perdés '
            'con una decisión repetida muchas veces. '
            'No mide si ganás ESTA mano — mide si la decisión es correcta.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 30,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Call de 10 BB con flush draw en el flop (36% equity). '
            'Bote si ganás: 40 BB. EV = (0,36 × 40) − 10 = '
            '14,4 − 10 = +4,4 BB. Decisión +EV.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Th', '9h'],
          board: const ['Ad', 'Kc', '7s'],
          pot: 30,
          bets: const {1: 20.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Call de 20 BB con carta alta (sin proyecto real, ~15% equity). '
            'Bote si ganás: 70 BB. EV = (0,15 × 70) − 20 = '
            '10,5 − 20 = −9,5 BB. Decisión −EV: foldear es mejor.',
      ),
    ]);
  }

  // ================================================================
  // 6.7 — El EV de cada acción
  // ================================================================
  static TableLessonScript _evDeAccion() {
    return TableLessonScript([
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Ante la apuesta de CO, tenés tres opciones. '
            'El EV de FOLD siempre es 0 — no ganás ni perdés más '
            '(el bote ya invertido no cuenta: es un costo hundido).',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'EV del CALL con flush draw (36% equity): '
            '+4,4 BB (calculado antes). Supera al fold → call es mejor.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 20,
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'FOLD EQUITY (al apostar o subir): si subís, a veces el '
            'rival foldea y ganás el bote sin llegar al showdown. '
            'Esa probabilidad de fold suma EV a tu apuesta.',
      ),
      TableStep(
        table: _hero(
          hero: const ['Kh', 'Qh'],
          board: const ['Ah', '8h', '3d'],
          pot: 30,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Regla de oro: elegís siempre la acción con el EV más alto. '
            'A veces es fold (0 > −EV), a veces call, a veces apuesta. '
            'El poker es tomar la decisión correcta, no ganar cada mano.',
      ),
    ]);
  }
}

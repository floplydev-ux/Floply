import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 13 (Entorno NL2 real).
class N13ClosingExamples {
  N13ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '13.1': _entornoNl2(),
    '13.2': _comoGanarNl2(),
    '13.3': _erroresNl2(),
    '13.4': _riverYAllIn(),
    '13.5': _decisionIntegrada(),
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

  // 13.1 — El entorno NL2
  static TableLessonScript _entornoNl2() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {3: 2.5},
          actions: const {3: 'LIMP'},
          folded: const {},
          cards: const {0: ['Ah', 'Kd']},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.seat(3)],
        bubble: 'NL2: rivales típicos hacen limps con cualquier mano — '
            'a7o, 84s, 33 desde UTG. El rango defensivo es muy amplio. '
            'Estos jugadores no saben que el rango de UTG debería ser estrecho.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 2.0},
          actions: const {1: 'MINBET'},
          pot: 20,
        ),
        anchor: const TableAnchor.bet(1),
        highlight: const [TableAnchor.bet(1)],
        bubble: 'Minbet frecuente en NL2: el rival apuesta solo 2 BB en un '
            'bote de 20. Esto da odds enormes para llamar con draws. '
            'No te adjustás buscando sofisticación — simplemente explotás.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 40.0},
          actions: const {1: 'OVERBET'},
          pot: 20,
        ),
        anchor: const TableAnchor.bet(1),
        highlight: const [TableAnchor.bet(1)],
        bubble: 'Overbet enorme en NL2: casi siempre significa mano muy fuerte '
            '(set, full, escalera). El jugador típico de NL2 no farola '
            'con montos gigantes — solo apuesta cuando tiene algo enorme. '
            'Fold con manos medias ante overbet.',
      ),
    ]);
  }

  // 13.2 — Cómo ganar en NL2
  static TableLessonScript _comoGanarNl2() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {3: 2.5},
          actions: const {3: 'SUBA'},
          folded: const {2, 1},
          cards: const {0: ['Ah', 'As']},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'ESTRATEGIA PRINCIPAL EN NL2: jugá VALUE POKER. '
            'Con manos fuertes (AA, KK, AK), construí el bote. '
            'Apostá grande cuando tenés la mejor mano — los rivales llaman '
            'con manos peores frecuentemente.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Kd', 'Qh'],
          bets: const {0: 15.0},
          actions: const {0: 'VALUE BET'},
          pot: 35,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.bet(0)],
        bubble: 'APOSTÁ GRANDE CON VALOR: en NL2 los rivales llaman '
            'aunque sepan que probablemente estén perdidos. '
            'Con top pair en K-7-2, apostás 2/3 del bote o más — '
            'no des descuento innecesario.',
      ),
      TableStep(
        table: _street(
          board: const ['Jh', '9h', '8d'],
          hero: const ['Kd', 'Qh'],
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'REDUCÍ LOS FAROLES ELABORADOS: en NL2 los rivales no foldeán '
            'fácilmente. Un farol con carta alta en un board coordinado '
            'no funciona bien. Reservá los faroles para situaciones simples '
            'y priorizá el valor cuando conectés.',
      ),
    ]);
  }

  // 13.3 — Los 18 errores frecuentes en NL2
  static TableLessonScript _erroresNl2() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {3: 2.5, 2: 2.5, 1: 2.5},
          actions: const {3: 'SUBA', 2: 'CALL', 1: 'CALL'},
          folded: const {},
          cards: const {0: ['7h', '6d']},
          toAct: 0,
          pot: 9.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'ERROR #1: llamar con cualquier mano porque "es barato". '
            '76o en un bote multiway contra 3 jugadores preflop es un call '
            'que pierde dinero a largo plazo — la mano es muy débil para '
            'las calles posteriores.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ad', 'Qh'],
          bets: const {1: 20.0},
          actions: const {1: 'APUESTA'},
          pot: 20,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'ERROR #2: no foldear manos fuertes cuando el rival muestra '
            'mucha agresión. AQ sin pegar en K-7-2 NO tiene valor. '
            'Carta alta sin par → fold contra apuesta grande. '
            'No es debilidad, es correcta lectura del rango rival.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Ah', 'Kd'],
          bets: const {0: 5.0},
          actions: const {0: 'MINBET'},
          pot: 40,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'ERROR #3: apostar demasiado poco con manos fuertes. '
            'Con AK (doble pareja) en el river, una minbet deja '
            'dinero en la mesa — el rival hubiera pagado mucho más. '
            'Apostá 50-75% del bote para maximizar.',
      ),
    ]);
  }

  // 13.4 — Spots de river y all-in
  static TableLessonScript _riverYAllIn() {
    return TableLessonScript([
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Ah', 'Ad'], 1: const ['?', '?']},
            stacks: const {0: 20, 1: 20},
            folded: const {5, 4, 3, 2},
            bets: const {1: 20.0, 0: 20.0},
            actions: const {1: 'ALL-IN', 0: 'CALL'},
          ),
          board: const ['Ah', 'Kd', '7c', '2s', '5h'],
          potBb: 40,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'ALL-IN en el river con AA (set de ases en A-K-7-2-5). '
            'Rango del rival que apuesta all-in: AK (doble pareja), '
            'set menor (KK, 77, 22). Todos los perdés a AA. '
            'El call es correcto — tenés la mano más fuerte posible.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Kh', '9d'], 1: const ['?', '?']},
            stacks: const {0: 60, 1: 60},
            folded: const {5, 4, 3, 2},
            bets: const {1: 40.0},
            actions: const {1: 'ALL-IN'},
          ),
          board: const ['Kd', '7h', '2c', '3s', 'Jh'],
          potBb: 60,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'K9 en K-7-2-3-J. El rival apuesta all-in. '
            'Rango de valor que te gana: KJ (K+J pareja), sets, '
            'manos con 45 (no encaja en el board). '
            'K9 con kicker 9 → FOLD. El all-in dice "tengo algo mejor".',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: _labels,
            cards: const {0: ['Kh', '9d'], 1: const ['?', '?']},
            stacks: const {0: 60, 1: 60},
            folded: const {5, 4, 3, 2},
            bets: const {1: 40.0},
            actions: const {1: 'ALL-IN'},
          ),
          board: const ['Kd', '7h', '2c', '3s', 'Jh'],
          potBb: 60,
          buttonSlot: 0,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'En NL2, los all-ins como farol son RAROS. '
            'La mayoría de los rivales de NL2 no meten todo con nada. '
            'Cuando el rival apuesta all-in en el river, '
            'sospecháste que tiene mano fuerte — es casi siempre correcto.',
      ),
    ]);
  }

  // 13.5 — La decisión integrada: todos los conceptos juntos
  static TableLessonScript _decisionIntegrada() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {1: 2.5},
          actions: const {1: 'SUBA'},
          folded: const {3, 2, 5, 4},
          cards: const {0: ['Kh', 'Qs']},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(1)],
        bubble: 'CO abre a 2,5 BB. BTN con KQo. '
            'DECISIÓN INTEGRADA — preflop: posición (tengo BTN), '
            'mano (KQo: no premium pero buena), '
            'rango del rival (CO amplio). → CALL.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Kh', 'Qd'],
          pot: 6.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Flop K-7-2. Top pair, kicker dama. El rival chequea. '
            'Integración: board seco (ventaja de rango), tengo iniciativa '
            'si hubiera abierto (no aquí — llamé). '
            'Apuesto para valor y para "cobrar" a manos peores.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As'],
          hero: const ['Kh', 'Qd'],
          bets: const {1: 12.0},
          actions: const {1: 'APUESTA'},
          pot: 26,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.bet(1)],
        bubble: 'Turn As. Rival apuesta 12 BB. '
            'Nuevo análisis: el A cambió el rango del rival (AK gana, A7 gana). '
            'KQ sigue siendo fuerte pero está más vulnerable. '
            'Call manteniendo el tamaño del bote. Fold si el river cuesta demasiado.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kh', 'Qd'],
          pot: 38,
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'River 9♥ (blank). Rival chequea. '
            'Decisión final integrada: con KQ en K-A-7-2-9, podemos apostar '
            'valor fino (queremos llamada de K peor). '
            'Todos los conceptos juntos: mano, posición, rango rival, '
            'tamaño, historia. Así se juega una mano completa.',
      ),
    ]);
  }
}

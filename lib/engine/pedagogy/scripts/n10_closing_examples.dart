import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 10 (Lectura de rangos).
class N10ClosingExamples {
  N10ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '10.1': _accionesComoInfo(),
    '10.2': _rangoTrasAgresion(),
    '10.3': _reducirRango(),
    '10.4': _valorVsFarol(),
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

  // 10.1 — Las acciones como información
  static TableLessonScript _accionesComoInfo() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {3: 2.5},
          actions: const {3: 'SUBA'},
          folded: const {2, 1},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: const TableAnchor.seat(3),
        highlight: const [TableAnchor.seat(3)],
        bubble: 'UTG sube a 2,5 BB. ¿Qué manos sube UTG? '
            'Desde early position se abren las mejores manos: '
            'pares grandes, AK, AQ, KQs. El RANGO es estrecho.',
      ),
      TableStep(
        table: _preflop(
          bets: const {0: 2.5},
          actions: const {0: 'SUBA'},
          folded: const {3, 2, 1, 5, 4},
          toAct: 0,
          pot: 4.0,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Comparado: BTN abre con el mismo tamaño. '
            'BTN tiene rango MUCHO más amplio: suma conectores suited, '
            'Ax, pares pequeños. La posición define qué manos son rentables.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['?', '?'],
          bets: const {1: 10.0},
          actions: const {1: 'APUESTA'},
          pot: 30,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.bet(1)],
        bubble: 'CO apuesta en el flop K-7-2. Esa acción actualiza su rango: '
            'manos que conectaron K (KQ, KJ, KT), sets (77, 22), pares medianos. '
            'Las manos débiles suelen chequear. La apuesta dice "conecté o presiono".',
      ),
    ]);
  }

  // 10.2 — El rango después de la agresión
  static TableLessonScript _rangoTrasAgresion() {
    return TableLessonScript([
      TableStep(
        table: _preflop(
          bets: const {3: 2.5, 0: 8.0},
          actions: const {3: 'SUBA', 0: '3-BET'},
          folded: const {2, 1, 5, 4},
          toAct: 3,
          pot: 10.5,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.bet(0)],
        bubble: 'El BTN 3-betea a UTG. Eso comunica: manos premium (AA-QQ, AKs) '
            'o manos de farol (A5s, A4s). El rango del 3-bettor es POLARIZADO '
            '— muy fuerte o especulativo.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 15.0},
          actions: const {1: 'BARREL'},
          pot: 35,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.bet(1)],
        bubble: 'Doble barrel en el turn. Después de c-bet + barrel, '
            'el rango del rival se ESTRECHA: principalmente manos hechas '
            '(K, set) o draws semijugados. Los faroles puros se filtran '
            'porque los faroles baratos ya foldean antes.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 25.0},
          actions: const {1: 'TRIPLE'},
          pot: 60,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.bet(1)],
        bubble: 'Triple barrel en el river. Rango POLARIZADO: '
            'manos hechas muy fuertes (AK, set, full) que buscan valor, '
            'o faroles con nada. El rival con mano media está atrapado — '
            'tiene que decidir si el rival puede tener tanto manos fuertes como faroles.',
      ),
    ]);
  }

  // 10.3 — Reducir el rango del rival calle a calle
  static TableLessonScript _reducirRango() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          pot: 20,
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'Flop K-7-2. El rival chequea. Rango posible: cualquier mano '
            'que pagó preflop — pair+, draws, carta alta. Amplio todavía.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 10.0},
          actions: const {1: 'CHECK'},
          pot: 20,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.seat(1)],
        bubble: 'Turn As. El rival chequea de nuevo. '
            'Eliminamos del rango: sets de AA o AK (los hubiera apostado). '
            'Se mantienen: KQ, K-menor, manos débiles, draws.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Ah', 'Kd'],
          bets: const {1: 15.0},
          actions: const {1: 'APUESTA'},
          pot: 35,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.bet(1)],
        bubble: 'River 9♥. El rival APUESTA. '
            'Nueva información: eliminamos las manos débiles que hubieran '
            'llegado al showdown gratis. Rango activo: K9 (dos pares), '
            'A9, quizás farol con carta alta. AK tuyo sigue siendo muy fuerte.',
      ),
    ]);
  }

  // 10.4 — Distinguir valor de farol
  static TableLessonScript _valorVsFarol() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kd', '8h'],
          bets: const {1: 30.0},
          actions: const {1: 'APUESTA'},
          pot: 50,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.bet(1)],
        bubble: 'El rival apuesta grande en el river. Tenés K8 (top pair, kicker 8). '
            '¿Está apostando por valor o farol? '
            'Revisá la historia de la mano para separar las dos posibilidades.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kd', '8h'],
          bets: const {1: 30.0},
          actions: const {1: 'APUESTA'},
          pot: 50,
        ),
        anchor: const TableAnchor.seat(1),
        highlight: const [TableAnchor.seat(1)],
        bubble: 'Manos de VALOR que apostarían: AK (doble pareja), K9 (dos pares), '
            'A9 (dos pares), set de 9s. Son manos que te GANAN. '
            'Si su rango tiene muchas de estas → call pierde dinero.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kd', '8h'],
          bets: const {1: 30.0},
          actions: const {1: 'APUESTA'},
          pot: 50,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Manos de FAROL que apostando: QJ (falló escalera), '
            'JT (falló escalera), 65 corazones (falló color). '
            'Si chequean todas las calles anteriores sin resistencia, '
            'puede ser farol de draw perdido. Equilibrá los dos rangos.',
      ),
    ]);
  }
}

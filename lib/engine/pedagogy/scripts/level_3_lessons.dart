import '../table_lesson.dart';
import 'script_builders.dart';

/// Guiones de teoría interactiva sobre la mesa — Nivel 3 (Posición).
class Level3Lessons {
  Level3Lessons._();

  static final Map<String, TableLessonScript> byId = {
    '3.1': _positions(),
    '3.3': _positionalAdvantage(),
  };

  // 3.1 — Las posiciones en 6-max  (héroe: UTG)
  static TableLessonScript _positions() {
    const labels = {0: 'UTG', 5: 'HJ', 4: 'CO', 3: 'BTN', 2: 'SB', 1: 'BB'};
    const btn = 3;

    TableSnapshot base({
      Map<int, List<String>> cards = const {},
      int? toAct,
    }) =>
        TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {2: 0.5, 1: 1.0},
            actions: const {2: 'CIEGA', 1: 'CIEGA'},
            cards: cards,
            toAct: toAct,
          ),
          potBb: 1.5,
          buttonSlot: btn,
        );

    return TableLessonScript([
      TableStep(
        table: base(),
        anchor: TableAnchor.pot,
        highlight: const [
          TableAnchor.bet(2),
          TableAnchor.bet(1),
          TableAnchor.pot,
        ],
        bubble: 'Antes de repartir, la SB pone 0,5 BB y la BB pone 1 BB. '
            'Ya hay 1,5 BB en el bote.',
      ),
      TableStep(
        table: base(),
        anchor: const TableAnchor.seat(0),
        bubble: 'Vos estás en UTG ("under the gun"): la primera posición '
            'en actuar preflop.',
      ),
      TableStep(
        table: base(cards: const {0: ['As', 'Ks']}, toAct: 0),
        anchor: TableAnchor.heroCards,
        bubble: 'Recibís tus dos cartas y te toca decidir primero, sin '
            'ver qué hacen los demás.',
      ),
      TableStep(
        table: base(cards: const {0: ['As', 'Ks']}),
        anchor: const TableAnchor.seat(5),
        highlight: const [
          TableAnchor.seat(5),
          TableAnchor.seat(4),
          TableAnchor.seat(3),
        ],
        bubble: 'Después de UTG hablan HJ, CO y BTN, en ese orden.',
      ),
      TableStep(
        table: base(cards: const {0: ['As', 'Ks']}),
        anchor: const TableAnchor.seat(3),
        bubble: 'El BTN es la mejor posición: actúa último en el flop, el '
            'turn y el river.',
      ),
      TableStep(
        table: base(cards: const {0: ['As', 'Ks']}),
        anchor: const TableAnchor.seat(2),
        highlight: const [TableAnchor.seat(2), TableAnchor.seat(1)],
        bubble: 'La SB y la BB son "las ciegas": ya pusieron fichas y '
            'postflop les toca actuar primero, en desventaja.',
      ),
      TableStep(
        table: base(cards: const {0: ['As', 'Ks']}),
        anchor: TableAnchor.pot,
        dimOthers: false,
        highlight: const [],
        bubble: 'Orden preflop: UTG → HJ → CO → BTN → SB → BB. Cuanto más '
            'tarde actuás, mejor.',
      ),
    ]);
  }

  // 3.3 — Ventaja posicional  (héroe: CO, rival: BTN)
  static TableLessonScript _positionalAdvantage() {
    const labels = {0: 'CO', 5: 'BTN', 4: 'SB', 3: 'BB', 2: 'UTG', 1: 'HJ'};
    const btn = 5;

    return TableLessonScript([
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {4: 0.5, 3: 1.0},
            actions: const {4: 'CIEGA', 3: 'CIEGA', 2: 'FOLD', 1: 'FOLD'},
            folded: const {2, 1},
            cards: const {0: ['Qh', 'Qs']},
            toAct: 0,
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(0),
        bubble: 'Estás en el CO. {UTG} y {HJ} foldearon: el único que puede '
            'actuar después tuyo es {BTN}.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {0: 2.5, 4: 0.5, 3: 1.0},
            actions: const {0: 'SUBE', 4: 'CIEGA', 3: 'CIEGA'},
            folded: const {2, 1},
            cards: const {0: ['Qh', 'Qs']},
          ),
          potBb: 4.0,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.bet(0),
        bubble: 'Abrís a 2,5 BB con Q♥Q♠.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {0: 2.5, 5: 2.5, 4: 0.5, 3: 1.0},
            actions: const {0: 'SUBE', 5: 'PAGA'},
            folded: const {2, 1},
            cards: const {0: ['Qh', 'Qs']},
          ),
          potBb: 6.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(5),
        bubble: '{BTN} paga. {SB} y {BB} foldean. Van los dos al flop.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {2, 1, 4, 3},
            actions: const {4: 'FOLD', 3: 'FOLD'},
            cards: const {0: ['Qh', 'Qs']},
          ),
          board: const ['Kh', '9c', '4d'],
          potBb: 6.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.board,
        bubble: 'Llega el flop. En cada calle postflop, ¿quién habla '
            'primero?',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {2, 1, 4, 3},
            cards: const {0: ['Qh', 'Qs']},
            toAct: 0,
          ),
          board: const ['Kh', '9c', '4d'],
          potBb: 6.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(0),
        bubble: 'Vos, el CO. Tenés que decidir sin saber qué hará {BTN}.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {2, 1, 4, 3},
            actions: const {0: 'PASA'},
            cards: const {0: ['Qh', 'Qs']},
            toAct: 5,
          ),
          board: const ['Kh', '9c', '4d'],
          potBb: 6.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(5),
        bubble: '{BTN} decide DESPUÉS de verte a vos. Ya sabe algo que vos '
            'no sabías.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {2, 1, 4, 3},
            cards: const {0: ['Qh', 'Qs']},
          ),
          board: const ['Kh', '9c', '4d'],
          potBb: 6.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(5),
        dimOthers: false,
        bubble: 'Actuar último = ver primero lo que hacen los demás. Por '
            'eso las posiciones tardías abren más manos.',
      ),
    ]);
  }
}

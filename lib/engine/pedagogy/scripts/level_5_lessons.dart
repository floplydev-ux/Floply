import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de teoría interactiva sobre la mesa — Nivel 5 (Open raise).
class Level5Lessons {
  Level5Lessons._();

  static final Map<String, TableLessonScript> byId = {
    '5.1': _openOrFold(),
  };

  // 5.1 — Abrir o foldear  (héroe: BTN)
  static TableLessonScript _openOrFold() {
    const labels = TableBuilder.btnHero;
    const btn = 0;

    return TableLessonScript([
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: const {5: 0.5, 4: 1.0},
            actions: const {5: 'CIEGA', 4: 'CIEGA'},
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(0),
        bubble: 'Sos el BTN. La acción llega hasta vos sin que nadie haya '
            'subido.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: const {5: 0.5, 4: 1.0},
            actions: const {5: 'CIEGA', 4: 'CIEGA', 3: 'FOLD'},
            folded: const {3},
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(3),
        bubble: '{UTG} mira su mano y foldea.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: const {5: 0.5, 4: 1.0},
            actions: const {
              5: 'CIEGA',
              4: 'CIEGA',
              3: 'FOLD',
              2: 'FOLD',
              1: 'FOLD',
            },
            folded: const {3, 2, 1},
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(2),
        highlight: const [TableAnchor.seat(2), TableAnchor.seat(1)],
        bubble: '{HJ} y {CO} también foldean. Ahora te toca a vos.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: const {5: 0.5, 4: 1.0},
            actions: const {5: 'CIEGA', 4: 'CIEGA'},
            folded: const {3, 2, 1},
            cards: const {0: ['Ah', '5h']},
            toAct: 0,
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.heroCards,
        bubble: 'Tenés A♥5♥. Desde el BTN, esta mano entra en el rango de '
            'apertura.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: const {0: 2.5, 5: 0.5, 4: 1.0},
            actions: const {0: 'SUBE', 5: 'CIEGA', 4: 'CIEGA'},
            folded: const {3, 2, 1},
            cards: const {0: ['Ah', '5h']},
          ),
          potBb: 4.0,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'Abrís (open raise) a 2,5 BB: el tamaño estándar en 6-max.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: const {0: 2.5, 5: 0.5, 4: 1.0},
            actions: const {0: 'SUBE'},
            folded: const {3, 2, 1},
            cards: const {0: ['Ah', '5h']},
            toAct: 4,
          ),
          potBb: 4.0,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(5),
        highlight: const [TableAnchor.seat(5), TableAnchor.seat(4)],
        bubble: 'Ahora {SB} y {BB} deciden si pagan, resuben o foldean.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: labels,
            bets: const {0: 2.5, 5: 0.5, 4: 1.0},
            folded: const {3, 2, 1},
            cards: const {0: ['Ah', '5h']},
          ),
          potBb: 4.0,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(0),
        dimOthers: false,
        bubble: 'Regla: primero en el bote, abrís si la mano entra en el '
            'rango de tu posición; si no, fold.',
      ),
    ]);
  }
}

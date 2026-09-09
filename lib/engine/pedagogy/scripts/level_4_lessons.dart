import '../table_lesson.dart';
import 'script_builders.dart';

/// Guiones de teoría interactiva sobre la mesa — Nivel 4 (Rangos).
class Level4Lessons {
  Level4Lessons._();

  static final Map<String, TableLessonScript> byId = {
    '4.1': _whatIsARange(),
  };

  // 4.1 — Qué es un rango  (héroe: HJ)
  static TableLessonScript _whatIsARange() {
    const labels = {0: 'HJ', 5: 'CO', 4: 'BTN', 3: 'SB', 2: 'BB', 1: 'UTG'};
    const btn = 4;

    TableSnapshot base({
      Map<int, List<String>> cards = const {},
      int? toAct,
    }) =>
        TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {3: 0.5, 2: 1.0},
            actions: const {3: 'CIEGA', 2: 'CIEGA', 1: 'FOLD'},
            folded: const {1},
            cards: cards,
            toAct: toAct,
          ),
          potBb: 1.5,
          buttonSlot: btn,
        );

    return TableLessonScript([
      TableStep(
        table: base(toAct: 0),
        anchor: const TableAnchor.seat(0),
        bubble: 'Estás en el HJ. UTG foldeó y sos el primero en poder '
            'entrar al bote.',
      ),
      TableStep(
        table: base(cards: const {0: ['Ad', 'Qs']}, toAct: 0),
        anchor: TableAnchor.heroCards,
        bubble: 'Con A♦Q♠ abrirías. Pero no decidimos mirando una sola '
            'mano.',
      ),
      TableStep(
        table: base(cards: const {0: ['Ad', 'Qs']}),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Pensamos en RANGOS: el conjunto de TODAS las manos con '
            'las que abrirías desde el HJ.',
      ),
      TableStep(
        table: base(cards: const {0: ['Ad', 'Qs']}),
        anchor: const TableAnchor.seat(0),
        bubble: 'Ese rango son parejas medias y altas, ases buenos y '
            'conectores altos. AJo entra; 8♣3♦ no.',
      ),
      TableStep(
        table: base(cards: const {0: ['Ad', 'Qs']}),
        anchor: const TableAnchor.seat(4),
        highlight: const [TableAnchor.seat(4)],
        bubble: 'Cada posición tiene su propio rango. El del BTN es mucho '
            'más ancho que el del HJ.',
      ),
      TableStep(
        table: base(cards: const {0: ['Ad', 'Qs']}),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Jugás en rangos y también leés al rival en rangos: "qué '
            'manos podría tener acá".',
      ),
    ]);
  }
}

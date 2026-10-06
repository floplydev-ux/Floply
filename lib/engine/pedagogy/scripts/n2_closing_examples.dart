import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 2.
class N2ClosingExamples {
  N2ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '2.2': _compararYDesempatar(),
  };

  static const _labels = TableBuilder.btnHero; // 0=BTN(héroe) · 3=UTG(rival)

  static TableSnapshot _sd({
    required List<String> board,
    List<String> hero = const ['?', '?'],
    List<String> rival = const ['?', '?'],
    double pot = 14,
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

  // 2.2 — Comparar y desempatar
  static TableLessonScript _compararYDesempatar() {
    const board1 = ['Kd', 'Tc', '7h', '4s', '2c'];
    const board2 = ['Ac', 'Kh', 'Qd', 'Jc', 'Tc'];
    const board3 = ['Ah', 'Kd', 'Qc', 'Jh', '2s'];

    return TableLessonScript([
      // Paso 1 — intro: showdown, cartas boca abajo, concepto "mejor 5 de 7"
      TableStep(
        table: _sd(board: board1),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Llegaron al showdown. Para comparar, cada uno elige la mejor '
            'combinación de 5 cartas entre sus 2 privadas y las 5 del board '
            '— 7 disponibles en total.',
      ),
      // Paso 2 — categoría decide primero (pareja vs carta alta)
      TableStep(
        table: _sd(board: board1, hero: const ['Kh', '9d'], rival: const ['Ac', 'Jh']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'La CATEGORÍA decide primero. Vos tenés pareja de reyes; '
            '{UTG}, solo carta alta (sin pareja). La pareja gana — no hace '
            'falta seguir comparando.',
      ),
      // Paso 3 — misma categoría → kicker
      TableStep(
        table: _sd(board: board1, hero: const ['Kh', 'Qd'], rival: const ['Ks', '8c']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(3)],
        bubble: 'Cuando la categoría empata (los dos tienen pareja de reyes), '
            'se pasa al KICKER: la carta más alta que no forma parte de la '
            'pareja. Q > 8 → ganás vos.',
      ),
      // Paso 4 — el board juega → bote dividido
      TableStep(
        table: _sd(board: board2, hero: const ['4h', '2d'], rival: const ['9s', '3c']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.board],
        bubble: 'El board A-K-Q-J-T ya forma la mejor escalera posible. '
            'Ninguna carta privada la mejora: "el board juega" para los dos '
            '→ bote dividido en partes iguales.',
      ),
      // Paso 5 — elegir la mejor combinación de 5
      TableStep(
        table: _sd(board: board3, hero: const ['Ts', '9c'], rival: const ['?', '?']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Con 7 cartas disponibles, siempre elegís la MEJOR de 5. '
            'Tu T♠ completa la Broadway (A-K-Q-J-T) con el board — la pareja '
            'de nueves queda afuera porque la escalera es mejor.',
      ),
    ]);
  }
}

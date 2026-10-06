import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de teoría interactiva sobre la mesa — Nivel 2 (Ranking de manos).
///
/// La jerarquía se enseña con showdowns reales: dos jugadores muestran las
/// cartas, se resalta la mano ganadora y la burbuja nombra las categorías.
class Level2Lessons {
  Level2Lessons._();

  static final Map<String, TableLessonScript> byId = {
    '2.1': _hierarchy(),
  };

  static const _labels = TableBuilder.btnHero; // 0=BTN (usuario), 3=UTG rival

  /// Mesa heads-up en el showdown: usuario (slot 0) vs rival (slot 3),
  /// el resto foldeado.
  static TableSnapshot _showdown({
    required List<String> board,
    required List<String> heroCards,
    required List<String> rivalCards,
    double pot = 12,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          folded: const {5, 4, 2, 1},
          cards: {0: heroCards, 3: rivalCards},
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  static TableStep _cmp({
    required List<String> board,
    required List<String> hero,
    required List<String> rival,
    required String bubble,
    bool heroWins = true,
  }) =>
      TableStep(
        table: _showdown(board: board, heroCards: hero, rivalCards: rival),
        anchor: TableAnchor.heroCards,
        highlight: [
          if (heroWins) TableAnchor.heroCards else const TableAnchor.seat(3),
        ],
        bubble: bubble,
      );

  static TableLessonScript _hierarchy() {
    return TableLessonScript([
      TableStep(
        table: _showdown(
          board: const ['Kd', '9s', '4h', '2c', '7s'],
          heroCards: const ['?', '?'],
          rivalCards: const ['?', '?'],
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Vos y {UTG} llegaron al showdown. Gana la mejor mano de 5 '
            'cartas… pero primero decide la CATEGORÍA.',
      ),
      _cmp(
        board: const ['Kd', '9s', '4h', '2c', '7s'],
        hero: const ['Ah', 'Ac'],
        rival: const ['Qc', 'Jd'],
        bubble: 'Vos tenés PAREJA de ases. {UTG} solo tiene carta alta. '
            'La pareja gana.',
      ),
      _cmp(
        board: const ['Td', '6s', '6h', '3c', 'Ks'],
        hero: const ['Tc', '9d'],
        rival: const ['Ah', '8d'],
        bubble: 'Vos tenés DOBLE PAREJA (dieces y seises). {UTG} solo una '
            'pareja. La doble pareja gana.',
      ),
      _cmp(
        board: const ['Qd', 'Qs', '8h', '4c', '2d'],
        hero: const ['Qc', '5d'],
        rival: const ['8s', '4h'],
        bubble: 'Vos tenés TRÍO de reinas. {UTG} tiene doble pareja. '
            'El trío gana.',
      ),
      _cmp(
        board: const ['9d', '8c', '5h', '3s', 'Kd'],
        hero: const ['7s', '6d'],
        rival: const ['9s', '9h'],
        bubble: 'Vos tenés ESCALERA (9-8-7-6-5). {UTG} tiene trío. '
            'La escalera gana.',
      ),
      _cmp(
        board: const ['As', 'Ks', 'Qs', '4d', '2h'],
        hero: const ['Js', '7s'],
        rival: const ['Jd', 'Tc'],
        bubble: 'Vos tenés COLOR (5 picas). {UTG} tiene escalera (A-K-Q-J-T). '
            'El color gana.',
      ),
      _cmp(
        board: const ['8s', '8h', '3s', '3c', 'Ks'],
        hero: const ['8c', '5d'],
        rival: const ['As', 'Qs'],
        bubble: 'Vos tenés FULL (8-8-8-3-3). {UTG} tiene color. El full '
            'gana.',
      ),
      TableStep(
        table: _showdown(
          board: const ['8s', '8h', '3s', '3c', 'Ks'],
          heroCards: const ['8c', '5d'],
          rivalCards: const ['As', 'Qs'],
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Regla: primero la categoría. Carta alta < pareja < doble '
            'pareja < trío < escalera < color < full < póker < escalera de '
            'color.',
      ),
    ]);
  }
}

import '../table_lesson.dart';

/// Constructor de mesas para la Academia: arma la `List<SeatState>` de una
/// mesa 6-max a partir de mapas concisos (etiquetas, apuestas, cartas…).
/// Lo usan tanto la teoría interactiva como los ejercicios; no duplicar
/// esta lógica por archivo.
///
/// Convención de asientos (portrait, 6 slots fijos):
///   slot 0 = héroe (abajo, centro)   · 1 = abajo-der · 2 = arriba-der
///   slot 3 = arriba, centro          · 4 = arriba-izq · 5 = abajo-izq
/// El orden de acción preflop recorre los slots 0 → 5 → 4 → 3 → 2 → 1 — y,
/// con esta distribución, ese recorrido es horario en pantalla (ver
/// [TablePositions] en `table_position.dart` para el modelo de posiciones
/// explícito: BTN→SB→BB→UTG→HJ→CO es exactamente ese mismo orden de slot
/// decreciente, para cualquier `buttonSlot`, no solo estos dos presets).
class TableBuilder {
  TableBuilder._();

  /// Etiquetas típicas con el héroe en el BTN.
  static const Map<int, String> btnHero = {
    0: 'BTN',
    5: 'SB',
    4: 'BB',
    3: 'UTG',
    2: 'HJ',
    1: 'CO',
  };

  /// Etiquetas típicas con el héroe en UTG (primero en actuar).
  static const Map<int, String> utgHero = {
    0: 'UTG',
    5: 'HJ',
    4: 'CO',
    3: 'BTN',
    2: 'SB',
    1: 'BB',
  };

  /// Construye los 6 asientos de una mesa 6-max.
  static List<SeatState> seats({
    required Map<int, String> labels,
    int heroSlot = 0,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    Map<int, List<String>> cards = const {},
    Map<int, double> stacks = const {},
    Set<int> folded = const {},
    int? toAct,
  }) {
    return [
      for (var i = 0; i < 6; i++)
        SeatState(
          slot: i,
          label: labels[i] ?? '',
          isHero: i == heroSlot,
          cards: cards[i] ??
              (labels.containsKey(i) ? const ['?', '?'] : const <String>[]),
          betBb: bets[i] ?? 0,
          stackBb: stacks[i] ?? 100,
          action: actions[i],
          folded: folded.contains(i),
          toAct: toAct == i,
        ),
    ];
  }
}

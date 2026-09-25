/// Reglas de póker de una mesa 6-max: **posiciones y orden de acción**,
/// separadas a propósito de la geometría visual ([TableLayout], en
/// `poker_table_view.dart`).
///
/// La cadena de dependencia es siempre:
/// ```
/// reglas de póker (acá) → slot → geometría visual
/// ```
/// nunca al revés. La geometría puede cambiar (otra pantalla, otra
/// distribución) sin que esto se entere; esto puede evolucionar (heads-up,
/// más asientos) sin tocar un solo `Offset`.
///
/// No reemplaza nada existente: `TableBuilder.seats(labels: ...)` sigue
/// siendo válido tal cual está (los guiones ya escritos no se tocan). Esto
/// es la fuente de verdad *computable* que antes no existía — útil para
/// tests, para validar guiones, y para cualquier contenido nuevo que
/// prefiera no escribir el mapa de labels a mano.
library;

import '../poker/position.dart';
import '../poker/street.dart';

export '../poker/position.dart' show Position;
export '../poker/street.dart' show Street;

/// Posiciones y orden de acción de una mesa 6-max, derivados de un único
/// dato: qué asiento (`slot`, 0..5) tiene el botón.
///
/// Convención de slots: la misma que ya usa `TableBuilder`
/// (`btnHero`/`utgHero`): contando **hacia atrás en el índice de slot**
/// desde el botón se recorre BTN → SB → BB → UTG → HJ → CO. Esta clase
/// generaliza esa convención (antes solo cubierta por esos 2 presets fijos)
/// a cualquier `buttonSlot`.
class TablePositions {
  TablePositions(this.buttonSlot) {
    if (buttonSlot < 0 || buttonSlot >= seatCount) {
      throw ArgumentError.value(buttonSlot, 'buttonSlot',
          'debe estar entre 0 y ${seatCount - 1}');
    }
  }

  /// Slot (0..5) que tiene el botón del dealer.
  final int buttonSlot;

  static const int seatCount = 6;

  /// Orden BTN→SB→BB→UTG→HJ→CO expresado como distancia "hacia atrás" en
  /// slot desde el botón (k=0 es el propio botón).
  static const List<Position> _byOffset = [
    Position.btn,
    Position.sb,
    Position.bb,
    Position.utg,
    Position.hj,
    Position.co,
  ];

  /// Posición del asiento [slot], derivada de [buttonSlot]. Única fuente de
  /// verdad — reemplaza tener que escribir `labels: {...}` a mano para
  /// saber qué posición le toca a cada slot.
  Position positionOf(int slot) => _byOffset[(buttonSlot - slot) % seatCount];

  /// El slot que ocupa la posición [p], dado [buttonSlot].
  int slotOf(Position p) => (buttonSlot - _byOffset.indexOf(p)) % seatCount;

  /// Mapa slot → etiqueta, listo para pasarle a
  /// `TableBuilder.seats(labels: ...)` si un guion nuevo prefiere no
  /// escribirlo a mano.
  Map<int, String> get labels => {
        for (var s = 0; s < seatCount; s++) s: positionOf(s).label,
      };

  /// Los 6 slots en el orden real de acción de [street] (sin filtrar por
  /// jugadores activos). Preflop arranca en UTG; postflop arranca en SB —
  /// el resto de la vuelta es la misma rotación en ambos casos.
  List<int> order(Street street) {
    final startOffset = street == Street.preflop ? 3 : 1; // utg : sb
    return [
      for (var i = 0; i < seatCount; i++)
        slotOf(_byOffset[(startOffset + i) % seatCount]),
    ];
  }

  /// [order] filtrado a los asientos realmente en mano: ni vacíos ni
  /// foldeados, mismo orden relativo.
  List<int> activeOrder(
    Street street, {
    Set<int> folded = const {},
    Set<int> empty = const {},
  }) =>
      order(street)
          .where((s) => !folded.contains(s) && !empty.contains(s))
          .toList();

  /// El primer slot en actuar en [street], entre los asientos activos.
  /// `null` si no queda nadie (mesa vacía o todos foldeados/ausentes).
  int? firstToAct(
    Street street, {
    Set<int> folded = const {},
    Set<int> empty = const {},
  }) {
    final active = activeOrder(street, folded: folded, empty: empty);
    return active.isEmpty ? null : active.first;
  }

  /// El slot que actúa después de [afterSlot] en [street], saltando
  /// automáticamente a los foldeados/vacíos. `afterSlot` no necesita seguir
  /// activo (típicamente acaba de actuar); sirve igual como punto de
  /// partida del recorrido. `null` si no queda nadie más por actuar (la
  /// calle se cierra: cero o un solo jugador activo).
  int? nextToAct(
    int afterSlot,
    Street street, {
    Set<int> folded = const {},
    Set<int> empty = const {},
  }) {
    final full = order(street);
    final active = activeOrder(street, folded: folded, empty: empty).toSet();
    if (active.isEmpty) return null;
    final start = full.indexOf(afterSlot);
    final from = start < 0 ? 0 : start;
    for (var i = 1; i < full.length; i++) {
      final candidate = full[(from + i) % full.length];
      if (active.contains(candidate)) return candidate;
    }
    return null;
  }
}

/// Modelo de una **lección interactiva sobre una mesa de póker**.
///
/// No es un segundo motor: es contenido pedagógico (como [TheoryBlock] o
/// [ComprehensionCheck]) que describe, paso a paso, cómo se desarrolla una
/// mano mientras el "profesor" explica. La UI (`InteractiveTableLesson`)
/// dibuja la mesa y las burbujas; acá solo viven los datos.
///
/// Pensado para teléfono en vertical: la mesa tiene 6 asientos fijos
/// (`slot` 0 = el usuario, abajo al centro; 1..5 en arco). El guion asigna
/// a cada slot una posición ("UTG", "BB", ...) y un estado; el **nombre**
/// de cada jugador NO se hardcodea en el guion: lo resuelve
/// [TableSnapshot.withCast] (el usuario usa su nombre real; los rivales,
/// personajes de [AcademyPlayers]).
library;

import 'academy_players.dart';

/// Estado de un asiento en un instante de la mano.
class SeatState {
  const SeatState({
    required this.slot,
    required this.label,
    this.isHero = false,
    this.cards = const [],
    this.betBb = 0,
    this.stackBb = 100,
    this.action,
    this.folded = false,
    this.toAct = false,
    this.empty = false,
    this.name,
    this.avatarId,
  });

  /// Asiento vacío (no hay jugador sentado).
  const SeatState.empty(this.slot)
      : label = '',
        isHero = false,
        cards = const [],
        betBb = 0,
        stackBb = 0,
        action = null,
        folded = false,
        toAct = false,
        empty = true,
        name = null,
        avatarId = null;

  /// 0..5. El 0 es el asiento del usuario (abajo, al centro).
  final int slot;

  /// Etiqueta de posición: `UTG`, `HJ`, `CO`, `BTN`, `SB`, `BB`.
  final String label;

  final bool isHero;

  /// Nombre del jugador. `null` en el guion; lo completa `withCast`
  /// (nombre real del usuario, o personaje de [AcademyPlayers]).
  final String? name;

  /// Id de avatar (0..9). `null` hasta que `withCast` lo asigna.
  final int? avatarId;

  /// Cartas del asiento:
  ///  * `[]`  → todavía sin cartas;
  ///  * `['?', '?']` → boca abajo;
  ///  * `['As', 'Ks']` → boca arriba (notación compacta, ver `Card.parse`).
  final List<String> cards;

  /// Fichas ya apostadas por este asiento en la calle actual.
  final double betBb;

  /// Stack (fichas disponibles) del asiento, en BB. Por defecto 100.
  final double stackBb;

  /// Acción tomada, para mostrar sobre el asiento: `RAISE`, `FOLD`, `CALL`,
  /// `CHECK`, `POST` (ciega).
  final String? action;

  final bool folded;

  /// `true` si es el turno de este asiento (halo suave).
  final bool toAct;

  final bool empty;

  SeatState copyWith({
    String? label,
    bool? isHero,
    List<String>? cards,
    double? betBb,
    double? stackBb,
    Object? action = _noChange,
    bool? folded,
    bool? toAct,
    bool? empty,
    String? name,
    int? avatarId,
  }) {
    return SeatState(
      slot: slot,
      label: label ?? this.label,
      isHero: isHero ?? this.isHero,
      cards: cards ?? this.cards,
      betBb: betBb ?? this.betBb,
      stackBb: stackBb ?? this.stackBb,
      action: action == _noChange ? this.action : action as String?,
      folded: folded ?? this.folded,
      toAct: toAct ?? this.toAct,
      empty: empty ?? this.empty,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}

const Object _noChange = Object();

/// Foto completa de la mesa en un instante.
class TableSnapshot {
  const TableSnapshot({
    required this.seats,
    this.board = const [],
    this.potBb = 0,
    this.buttonSlot = 3,
  });

  /// Siempre 6 asientos (6-max), en orden de slot.
  final List<SeatState> seats;

  /// Cartas comunitarias, notación compacta (`['Ah','Kd','2c']`).
  final List<String> board;

  final double potBb;

  /// Slot que tiene el botón del dealer.
  final int buttonSlot;

  SeatState seatAt(int slot) =>
      seats.firstWhere((s) => s.slot == slot, orElse: () => SeatState.empty(slot));

  SeatState get hero => seats.firstWhere((s) => s.isHero,
      orElse: () => seats.isNotEmpty ? seats.first : const SeatState(slot: 0, label: ''));

  TableSnapshot copyWith({
    List<SeatState>? seats,
    List<String>? board,
    double? potBb,
    int? buttonSlot,
  }) {
    return TableSnapshot(
      seats: seats ?? this.seats,
      board: board ?? this.board,
      potBb: potBb ?? this.potBb,
      buttonSlot: buttonSlot ?? this.buttonSlot,
    );
  }

  /// Devuelve una copia cambiando un solo asiento (por slot).
  TableSnapshot withSeat(int slot, SeatState Function(SeatState) update) {
    return copyWith(
      seats: [
        for (final s in seats) s.slot == slot ? update(s) : s,
      ],
    );
  }

  /// Completa los nombres y avatares: el asiento del usuario usa
  /// [userName]; los rivales, personajes de [AcademyPlayers] elegidos con
  /// [seed] (determinista: misma lección → mismo elenco).
  ///
  /// No toca los asientos que ya tengan `name` (permite override puntual
  /// desde un guion si alguna vez hiciera falta).
  TableSnapshot withCast(String userName, int seed) {
    final npcSlots = seats
        .where((s) => !s.empty && !s.isHero && s.name == null)
        .map((s) => s.slot)
        .toList()
      ..sort();
    final cast = AcademyPlayers.pick(seed, npcSlots.length);

    return copyWith(seats: [
      for (final s in seats)
        if (s.empty || s.name != null)
          s
        else if (s.isHero)
          s.copyWith(name: userName)
        else
          () {
            final i = npcSlots.indexOf(s.slot);
            final p = i >= 0 && i < cast.length ? cast[i] : null;
            return s.copyWith(
              name: p?.name ?? s.label,
              avatarId: p?.avatarId ?? 0,
            );
          }(),
    ]);
  }
}

/// Resuelve los marcadores de nombre en un texto pedagógico contra una
/// mesa ya "casteada" (con nombres):
///  * `{me}`      → el nombre del usuario;
///  * `{UTG}` / `{BTN}` / `{SB}` / `{BB}` / `{HJ}` / `{CO}` → el nombre del
///    jugador que ocupa esa posición (o la etiqueta si el asiento está
///    vacío / es el usuario).
///
/// Así los guiones no hardcodean "Nico": escriben `{BTN} paga` y queda
/// "Nico paga" (o "Vos pagás" no aplica — para el usuario se escribe el
/// texto directo). Un texto sin marcadores pasa igual.
String resolveTableText(String raw, TableSnapshot table) {
  if (!raw.contains('{')) return raw;
  return raw.replaceAllMapped(RegExp(r'\{([A-Za-z]+)\}'), (m) {
    final key = m.group(1)!;
    if (key == 'me') return table.hero.name ?? 'Vos';
    for (final s in table.seats) {
      if (s.empty) continue;
      if (s.label.toUpperCase() == key.toUpperCase()) {
        return s.name ?? s.label;
      }
    }
    return key;
  });
}

/// A qué parte de la mesa apunta / resalta una burbuja.
enum TableAnchorKind { seat, bet, pot, board, heroCards }

class TableAnchor {
  const TableAnchor._(this.kind, this.slot);

  const TableAnchor.seat(int slot) : this._(TableAnchorKind.seat, slot);
  const TableAnchor.bet(int slot) : this._(TableAnchorKind.bet, slot);

  static const TableAnchor pot = TableAnchor._(TableAnchorKind.pot, -1);
  static const TableAnchor board = TableAnchor._(TableAnchorKind.board, -1);
  static const TableAnchor heroCards =
      TableAnchor._(TableAnchorKind.heroCards, -1);

  final TableAnchorKind kind;

  /// Slot (0..5) para `seat` / `bet`; `-1` para el resto.
  final int slot;

  @override
  bool operator ==(Object other) =>
      other is TableAnchor && other.kind == kind && other.slot == slot;

  @override
  int get hashCode => Object.hash(kind, slot);
}

/// Un paso del guion: una foto de la mesa + una burbuja educativa que
/// aparece en un lugar concreto.
class TableStep {
  const TableStep({
    required this.table,
    required this.bubble,
    required this.anchor,
    this.highlight = const [],
    this.dimOthers = true,
  });

  final TableSnapshot table;

  /// Texto de la burbuja (corto: 1–2 frases).
  final String bubble;

  /// Dónde aparece la burbuja (y hacia dónde apunta su "cola").
  final TableAnchor anchor;

  /// Qué elementos de la mesa se iluminan en este paso. Si está vacío,
  /// se ilumina [anchor].
  final List<TableAnchor> highlight;

  /// Si `true`, todo lo que no está resaltado se ve secundario.
  final bool dimOthers;

  List<TableAnchor> get effectiveHighlight =>
      highlight.isNotEmpty ? highlight : [anchor];
}

/// El guion completo de una lección interactiva.
class TableLessonScript {
  const TableLessonScript(this.steps);

  final List<TableStep> steps;

  int get length => steps.length;
  bool get isEmpty => steps.isEmpty;
}

/// De dónde viene una carta puntual, para [CardRef].
enum CardSource { hero, board, seat }

/// Referencia a **una carta concreta** de la mesa (más fino que
/// [TableAnchor], que resalta zonas enteras). Pensado para el piloto visual:
/// "esta carta en particular es la que importa", por ejemplo un out en el
/// board o la carta que completa un set.
class CardRef {
  const CardRef.hero(this.index)
      : source = CardSource.hero,
        slot = -1;
  const CardRef.board(this.index)
      : source = CardSource.board,
        slot = -1;
  const CardRef.seat(this.slot, this.index) : source = CardSource.seat;

  final CardSource source;

  /// Asiento (0..5), solo para [CardSource.seat].
  final int slot;

  /// Posición de la carta dentro de su lista (`hero.cards[index]`,
  /// `board[index]`, `seat.cards[index]`).
  final int index;
}

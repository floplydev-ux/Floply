/// Entorno de **Flutter Widget Preview** para [PokerTableView] — pensado
/// para iterar rápido sobre la geometría panel → cartas privadas sin tener
/// que navegar toda la Academia (elegir teoría, avanzar pasos, etc.) cada
/// vez que se toca una constante.
///
/// **Cómo usarlo:** desde la raíz del proyecto,
/// ```
/// flutter widget-preview start
/// ```
/// abre una pestaña del navegador con hot reload: cualquier cambio en
/// `poker_table_view.dart` (o en los snapshots de acá abajo) se refleja al
/// instante, sin recompilar la app ni pasar por la navegación real.
///
/// Este archivo **no se usa en producción** — ningún screen real lo
/// importa, es solo el banco de pruebas del previewer. No cambia estilo,
/// navegación, Academia, niveles ni lecciones: solo monta [PokerTableView]
/// con snapshots de ejemplo.
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../engine/pedagogy/table_lesson.dart';
import 'poker_table_view.dart';

/// Caja + fondo — el mismo tipo de contenedor en el que vive la mesa en la
/// app real (`SizedBox` de alto fijo sobre el fondo oscuro de Academia; ver
/// `table_explanation_view.dart`), para que lo que se ve acá se parezca a
/// lo que se va a ver de verdad.
Widget _stage(
  TableSnapshot snapshot, {
  Set<TableAnchor> highlight = const {},
}) {
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF13172E), Color(0xFF060812)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 360,
          height: 420,
          child: PokerTableView(snapshot: snapshot, highlight: highlight),
        ),
      ),
    ),
  );
}

/// Snapshot con un solo asiento ocupado (el resto vacíos) — para ver el
/// vínculo panel→cartas de ESE asiento sin que el resto de la mesa
/// compita por la atención. `slot` decide en qué lugar del óvalo cae, así
/// que sirve para comparar la misma fórmula en distintos ángulos.
TableSnapshot _onlySeat(SeatState seat) {
  return TableSnapshot(
    seats: [
      for (var i = 0; i < 6; i++) i == seat.slot ? seat : SeatState.empty(i)
    ],
    buttonSlot: seat.slot,
  );
}

// ===================================================================
// Mesa completa: el escenario más parecido a una lección real, para ver
// TODOS los anclajes panel→cartas a la vez (héroe + rivales revelados,
// ocultos y foldeados, todo junto).
// ===================================================================

@Preview(name: 'Mesa completa (6-max)')
Widget previewFullTable() {
  return _stage(const TableSnapshot(
    seats: [
      SeatState(
          slot: 0,
          label: 'BTN',
          isHero: true,
          name: 'Vos',
          cards: ['Ah', 'Ad']),
      SeatState(
          slot: 1,
          label: 'CO',
          name: 'Villain',
          cards: ['Kd', '9d'],
          winner: true),
      SeatState(slot: 2, label: 'HJ', name: 'Marco', folded: true),
      SeatState(
          slot: 3, label: 'UTG', name: 'Valen', cards: ['?', '?'], toAct: true),
      SeatState(slot: 4, label: 'BB', name: 'Yuki', folded: true),
      SeatState(slot: 5, label: 'SB', name: 'Sofia', cards: ['?', '?']),
    ],
    board: ['Ks', '7d', '2c', '9h', '3s'],
    potBb: 1360,
    buttonSlot: 0,
  ));
}

// ===================================================================
// Cada asiento aislado: comparar la MISMA fórmula panel→cartas en los 6
// ángulos posibles, ocultas y reveladas (revelada = 18dp de distancia,
// oculta = 14dp — ver TableLayout.pocketCards).
// ===================================================================

@Preview(name: 'Solo héroe (slot 0) · ocultas')
Widget previewHeroHidden() => _stage(_onlySeat(const SeatState(
      slot: 0,
      label: 'BTN',
      isHero: true,
      name: 'Vos',
      cards: ['?', '?'],
    )));

@Preview(name: 'Solo héroe (slot 0) · reveladas')
Widget previewHeroRevealed() => _stage(_onlySeat(const SeatState(
      slot: 0,
      label: 'BTN',
      isHero: true,
      name: 'Vos',
      cards: ['Ah', 'Ad'],
    )));

@Preview(name: 'Solo rival CO (slot 1) · ocultas')
Widget previewSlot1Hidden() => _stage(_onlySeat(const SeatState(
      slot: 1,
      label: 'CO',
      name: 'Villain',
      cards: ['?', '?'],
    )));

@Preview(name: 'Solo rival HJ (slot 2) · reveladas')
Widget previewSlot2Revealed() => _stage(_onlySeat(const SeatState(
      slot: 2,
      label: 'HJ',
      name: 'Marco',
      cards: ['Qc', 'Qh'],
    )));

@Preview(name: 'Solo rival arriba UTG (slot 3) · ocultas')
Widget previewTopSeatHidden() => _stage(_onlySeat(const SeatState(
      slot: 3,
      label: 'UTG',
      name: 'Valen',
      cards: ['?', '?'],
    )));

@Preview(name: 'Solo rival arriba UTG (slot 3) · reveladas')
Widget previewTopSeatRevealed() => _stage(_onlySeat(const SeatState(
      slot: 3,
      label: 'UTG',
      name: 'Valen',
      cards: ['Kd', '9d'],
    )));

@Preview(name: 'Solo rival BB (slot 4) · ocultas')
Widget previewSlot4Hidden() => _stage(_onlySeat(const SeatState(
      slot: 4,
      label: 'BB',
      name: 'Yuki',
      cards: ['?', '?'],
    )));

@Preview(name: 'Solo rival SB (slot 5) · reveladas')
Widget previewSlot5Revealed() => _stage(_onlySeat(const SeatState(
      slot: 5,
      label: 'SB',
      name: 'Sofia',
      cards: ['7h', '2d'],
    )));

// ===================================================================
// Los 6 asientos con cartas ocultas y nadie foldeado — la vista más
// directa para chequear de un vistazo que la fórmula es idéntica en los
// 6 ángulos (ninguno debería verse "distinto" al resto salvo por dónde
// cae el panel).
// ===================================================================

@Preview(name: 'Los 6 asientos · todas ocultas')
Widget previewAllSeatsHidden() {
  return _stage(const TableSnapshot(
    seats: [
      SeatState(
          slot: 0, label: 'BTN', isHero: true, name: 'Vos', cards: ['?', '?']),
      SeatState(slot: 1, label: 'CO', name: 'Villain', cards: ['?', '?']),
      SeatState(slot: 2, label: 'HJ', name: 'Marco', cards: ['?', '?']),
      SeatState(slot: 3, label: 'UTG', name: 'Valen', cards: ['?', '?']),
      SeatState(slot: 4, label: 'BB', name: 'Yuki', cards: ['?', '?']),
      SeatState(slot: 5, label: 'SB', name: 'Sofia', cards: ['?', '?']),
    ],
    buttonSlot: 0,
  ));
}

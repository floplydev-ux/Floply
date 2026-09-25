import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_lesson.dart';
import 'table/community_cards.dart';
import 'table/dealer_button.dart';
import 'table/player_seat.dart';
import 'table/pot_and_bets.dart';
import 'table/table_highlight.dart';
import 'table/table_layout.dart';
import 'table/table_surface.dart';

// `TableLayout`/`TableMaterial` y las claves de test
// (`kAcademyTableHeroCardsKey`, `kAcademyTableBoardKey`,
// `kAcademyTableAvatarKey`) viven en `table/table_layout.dart` (la base sin
// dependencias de `table/`, usada tanto por PlayerSeat como por
// CommunityCards) y se re-exportan acá para que el import público existente
// (`import '.../poker_table_view.dart'`) siga funcionando sin cambios —
// `visual_theory_stage.dart` y `test/engine/table_geometry_test.dart` usan
// `TableLayout` directamente a través de este import.
export 'table/table_layout.dart'
    show
        TableLayout,
        TableMaterial,
        kAcademyTableHeroCardsKey,
        kAcademyTableBoardKey,
        kAcademyTableAvatarKey;

/// La mesa de póker interactiva. Dibuja el paño, los paneles de jugador,
/// las cartas, las fichas y el bote a partir de un [TableSnapshot], y
/// resalta los elementos indicados. La misma instancia permanece montada
/// toda la lección: sólo cambian el snapshot y el foco.
///
/// **Raíz compositora**: esta es la única clase de la mesa que conoce
/// TODAS sus piezas (paño, asientos, board, bote/apuestas, dealer) — cada
/// pieza vive en su propio archivo dentro de `table/`, con una
/// responsabilidad propia y sin depender entre sí más de lo necesario (ver
/// `table/` para el detalle de cada una). `PokerTableView` solo decide
/// DÓNDE va cada una (vía [TableLayout]) y las compone en un `Stack`.
class PokerTableView extends StatelessWidget {
  const PokerTableView({
    super.key,
    required this.snapshot,
    this.highlight = const {},
    this.dimOthers = false,
    this.glow = 1,
    this.cardGlow = const {},
  });

  final TableSnapshot snapshot;
  final Set<TableAnchor> highlight;
  final bool dimOthers;

  /// 0..1, para el latido del resaltado.
  final double glow;

  /// Cartas puntuales a resaltar de forma individual (además del resaltado
  /// de zona de [highlight]). Vacío por defecto: no cambia nada para los
  /// guiones existentes. Pensado para el piloto visual (p. ej. señalar un
  /// out concreto en el board).
  final Set<CardRef> cardGlow;

  Set<int> _cardGlowIndices(CardSource source, {int slot = -1}) => {
        for (final r in cardGlow)
          if (r.source == source &&
              (source != CardSource.seat || r.slot == slot))
            r.index,
      };

  bool _isHi(TableAnchor a) => highlight.contains(a);

  /// Atenuación del elemento no enfocado. El foco ya destaca con halo +
  /// escala, así que la atenuación es suave y **nunca** toca el contexto
  /// que hay que poder comparar: board, bote y cualquier asiento con
  /// cartas reveladas.
  double _opacityFor(TableAnchor a, {bool context = false}) {
    if (!dimOthers || _isHi(a)) return 1;
    return context ? 0.85 : 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final layout = TableLayout(size);
      final s = layout.scale;

      Widget dim(TableAnchor a, Widget child, {bool context = false}) =>
          Opacity(opacity: _opacityFor(a, context: context), child: child);

      return SizedBox.fromSize(
        size: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
                child: CustomPaint(painter: TableSurfacePainter())),

            // --- Bote (rótulo, arriba del paño, asociado al board) ---
            _pin(
              layout.clampInFelt(layout.pot, Size(100 * s, 38 * s)),
              dim(
                TableAnchor.pot,
                Highlightable(
                  active: _isHi(TableAnchor.pot),
                  glow: glow,
                  radius: 10,
                  color: TableMaterial.focus,
                  child: PotBadge(bb: snapshot.potBb, scale: s),
                ),
                context: true,
              ),
            ),

            // --- Board: zona central única, recortada al verde ---
            if (snapshot.board.isNotEmpty)
              _pin(
                layout.clampInFelt(
                  layout.board,
                  Size(snapshot.board.length * 24.0 * s + 16, 40 * s),
                ),
                dim(
                  TableAnchor.board,
                  Highlightable(
                    active: _isHi(TableAnchor.board),
                    glow: glow,
                    radius: 10,
                    color: TableMaterial.focus,
                    child: CommunityCards(
                      codes: snapshot.board,
                      scale: s,
                      glowIndices: _cardGlowIndices(CardSource.board),
                    ),
                  ),
                  context: true,
                ),
              ),

            // --- Fichas apostadas: en la línea jugador → centro ---
            for (final seat in snapshot.seats)
              if (!seat.empty && seat.betBb > 0)
                _pin(
                  layout.bet(seat.slot),
                  dim(
                    TableAnchor.bet(seat.slot),
                    ChipEntrance(
                      // Re-anima solo cuando este monto es nuevo para este
                      // asiento (sube o aparece) — no en cada rebuild donde
                      // la apuesta ya estaba mostrada.
                      key: ValueKey('bet_${seat.slot}_${seat.betBb}'),
                      from: layout.seat(seat.slot) - layout.bet(seat.slot),
                      child: Highlightable(
                        active: _isHi(TableAnchor.bet(seat.slot)),
                        glow: glow,
                        radius: 12,
                        color: TableMaterial.focus,
                        child: BetChip(bb: seat.betBb, scale: s),
                      ),
                    ),
                  ),
                ),

            // --- Los 6 jugadores: un único PlayerSeat por asiento, con
            //     sus propias cartas ancladas ADENTRO (ver player_seat.dart).
            //     La mesa solo decide dónde va el asiento (layout.panel) —
            //     nunca dónde van las cartas de ese jugador; eso lo
            //     resuelve el propio PlayerSeat con un offset local.
            //     Mismo componente y mismo código para los 6, héroe
            //     incluido: la única diferencia es el propio SeatState y
            //     qué anchor/tabla de resaltado le corresponde (abajo). ---
            for (final seat in snapshot.seats)
              if (!seat.empty)
                _pin(
                  layout.panel(seat.slot),
                  PlayerSeat(
                    key: kAcademyTableAvatarKey(seat.slot),
                    seat: seat,
                    scale: s,
                    panelHighlighted: _isHi(TableAnchor.seat(seat.slot)),
                    // Único lugar donde el héroe recibe un valor distinto
                    // — no una estructura distinta: su glow depende de
                    // TableAnchor.heroCards en vez de seat(slot), igual
                    // que antes de fusionar cartas y panel en una pieza.
                    cardsHighlighted:
                        seat.isHero ? _isHi(TableAnchor.heroCards) : false,
                    glow: glow,
                    cardGlowIndices: seat.isHero
                        ? _cardGlowIndices(CardSource.hero)
                        : _cardGlowIndices(CardSource.seat, slot: seat.slot),
                  ),
                ),

            // --- Botón del dealer: SOBRE EL PAÑO, separado del panel del
            //     jugador que lo tiene pero derivado de su posición (ver
            //     TableLayout.dealerButton) — no vive dentro de PlayerSeat
            //     a propósito, para no leerse como parte del panel. Si el
            //     panel se mueve, o el botón cambia de asiento, lo sigue
            //     solo. ---
            _pin(
              layout.dealerButton(snapshot.buttonSlot),
              DealerButton(scale: s),
            ),
          ],
        ),
      );
    });
  }

  /// Coloca [child] centrado en la coordenada [c].
  Widget _pin(Offset c, Widget child) {
    return Positioned(
      left: c.dx,
      top: c.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: child,
      ),
    );
  }
}

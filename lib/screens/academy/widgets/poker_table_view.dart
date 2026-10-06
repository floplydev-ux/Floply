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
///
/// **Animación de recolección:** cuando el snapshot cambia y todas las
/// apuestas pasan a 0 mientras el bote crece (= nueva calle o showdown),
/// las fichas viejas vuelan hacia el centro antes de que el nuevo estado
/// sea visible.
class PokerTableView extends StatefulWidget {
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

  @override
  State<PokerTableView> createState() => _PokerTableViewState();
}

/// Par (slot, betBb) usado durante la animación de recolección.
typedef _CollectEntry = ({int slot, double betBb});

class _PokerTableViewState extends State<PokerTableView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _collectCtrl;
  late final Animation<double> _collectAnim;

  /// Fichas que se están animando hacia el bote (slot + monto del snapshot anterior).
  List<_CollectEntry> _collectingBets = const [];

  @override
  void initState() {
    super.initState();
    _collectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _collectAnim = CurvedAnimation(
      parent: _collectCtrl,
      curve: Curves.easeInCubic,
    );
    _collectCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _collectingBets = const []);
      }
    });
  }

  @override
  void didUpdateWidget(PokerTableView old) {
    super.didUpdateWidget(old);
    if (old.snapshot == widget.snapshot) return;

    final prev = old.snapshot;
    final next = widget.snapshot;

    // Detectar recolección: había apuestas, el nuevo snapshot no tiene
    // ninguna y el bote creció → nueva calle o showdown.
    final prevBetting =
        prev.seats.where((s) => !s.empty && s.betBb > 0).toList();
    final nextBetting =
        next.seats.where((s) => !s.empty && s.betBb > 0).toList();

    if (prevBetting.isNotEmpty &&
        nextBetting.isEmpty &&
        next.potBb > prev.potBb) {
      setState(() {
        _collectingBets =
            prevBetting.map((s) => (slot: s.slot, betBb: s.betBb)).toList();
      });
      _collectCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _collectCtrl.dispose();
    super.dispose();
  }

  Set<int> _cardGlowIndices(CardSource source, {int slot = -1}) => {
        for (final r in widget.cardGlow)
          if (r.source == source &&
              (source != CardSource.seat || r.slot == slot))
            r.index,
      };

  bool _isHi(TableAnchor a) => widget.highlight.contains(a);

  double _opacityFor(TableAnchor a, {bool context = false}) {
    if (!widget.dimOthers || _isHi(a)) return 1;
    return context ? 0.85 : 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    return AnimatedBuilder(
      animation: _collectAnim,
      builder: (context, _) {
        return LayoutBuilder(builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final layout = TableLayout(size);
          final s = layout.scale;

          Widget dim(TableAnchor a, Widget child, {bool context = false}) =>
              Opacity(opacity: _opacityFor(a, context: context), child: child);

          // Posición del bote — destino de la animación de recolección.
          final potTarget =
              layout.clampInFelt(layout.pot, Size(100 * s, 38 * s));

          // Fichas fantasma animadas hacia el bote.
          final collectWidgets = [
            for (final e in _collectingBets)
              _animatedCollect(
                from: layout.bet(e.slot),
                to: potTarget,
                t: _collectAnim.value,
                child: BetChip(bb: e.betBb, scale: s),
              ),
          ];

          return SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                    child: CustomPaint(painter: TableSurfacePainter())),

                // --- Bote ---
                _pin(
                  potTarget,
                  dim(
                    TableAnchor.pot,
                    Highlightable(
                      active: _isHi(TableAnchor.pot),
                      glow: widget.glow,
                      radius: 10,
                      color: TableMaterial.focus,
                      child: PotBadge(bb: snapshot.potBb, scale: s),
                    ),
                    context: true,
                  ),
                ),

                // --- Board ---
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
                        glow: widget.glow,
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

                // --- Fichas apostadas normales (nuevo snapshot) ---
                for (final seat in snapshot.seats)
                  if (!seat.empty && seat.betBb > 0)
                    _pin(
                      layout.bet(seat.slot),
                      dim(
                        TableAnchor.bet(seat.slot),
                        ChipEntrance(
                          key: ValueKey('bet_${seat.slot}_${seat.betBb}'),
                          from: layout.seat(seat.slot) - layout.bet(seat.slot),
                          child: Highlightable(
                            active: _isHi(TableAnchor.bet(seat.slot)),
                            glow: widget.glow,
                            radius: 12,
                            color: TableMaterial.focus,
                            child: BetChip(bb: seat.betBb, scale: s),
                          ),
                        ),
                      ),
                    ),

                // --- Fichas fantasma (animación de recolección al bote) ---
                ...collectWidgets,

                // --- Los 6 jugadores ---
                for (final seat in snapshot.seats)
                  if (!seat.empty)
                    _pin(
                      layout.panel(seat.slot),
                      PlayerSeat(
                        key: kAcademyTableAvatarKey(seat.slot),
                        seat: seat,
                        scale: s,
                        panelHighlighted:
                            _isHi(TableAnchor.seat(seat.slot)),
                        cardsHighlighted:
                            seat.isHero ? _isHi(TableAnchor.heroCards) : false,
                        glow: widget.glow,
                        cardGlowIndices: seat.isHero
                            ? _cardGlowIndices(CardSource.hero)
                            : _cardGlowIndices(CardSource.seat,
                                slot: seat.slot),
                      ),
                    ),

                // --- Botón del dealer ---
                _pin(
                  layout.dealerButton(snapshot.buttonSlot),
                  DealerButton(scale: s),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// Chip volando desde [from] hasta [to] según [t] ∈ [0,1],
  /// con fade-out en la segunda mitad.
  Widget _animatedCollect({
    required Offset from,
    required Offset to,
    required double t,
    required Widget child,
  }) {
    final pos = Offset.lerp(from, to, t)!;
    final opacity = (1.0 - t * 2).clamp(0.0, 1.0);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Opacity(opacity: opacity, child: child),
      ),
    );
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_lesson.dart';
import '../../../theme/app_colors.dart';
import 'educational_panel.dart';
import 'poker_table_view.dart';

/// Composición **mesa persistente + foco visual + explicación inferior**
/// para la teoría y los ejercicios interactivos.
///
/// La misma mesa ([PokerTableView]) permanece montada durante toda la
/// lección: al cambiar de paso solo cambian el *snapshot*, el *foco*
/// (highlight + atenuación del resto) y el texto del [EducationalPanel] de
/// abajo. No se reconstruye la mesa, no se navega, no hay burbujas sobre
/// las cartas.
///
/// Es sólo *capa de presentación*: consume el sistema pedagógico existente
/// ([TableSnapshot], [TableAnchor]). Va dentro de un `Expanded`; los
/// controles (SIGUIENTE / opciones) los pone cada pantalla.
class TableExplanationView extends StatefulWidget {
  const TableExplanationView({
    super.key,
    required this.table,
    required this.text,
    required this.anchor,
    required this.highlight,
    required this.dimOthers,
    required this.stepNumber,
    required this.transitionTag,
    this.accent = AppColors.violetPrimary,
    this.panelIcon,
    this.cardGlow = const {},
  });

  /// Mesa ya "casteada" (con nombres y avatares).
  final TableSnapshot table;

  /// Texto educativo ya resuelto (marcadores `{me}` / `{BTN}` reemplazados).
  final String text;

  /// Elemento de la mesa que enfoca este paso.
  final TableAnchor anchor;

  /// Elementos a resaltar. Si está vacío, se resalta [anchor].
  final List<TableAnchor> highlight;

  /// Atenúa el resto de la mesa para destacar el foco.
  final bool dimOthers;

  /// Número de paso / ítem para el indicador del panel.
  final int stepNumber;

  /// Cambia cuando cambia el contenido del paso: dispara el pulso del foco
  /// y la transición del panel.
  final String transitionTag;

  final Color accent;
  final IconData? panelIcon;

  /// Cartas puntuales a resaltar de forma individual, además del resaltado
  /// de zona de [highlight]. Vacío por defecto: no cambia nada para los
  /// consumidores existentes.
  final Set<CardRef> cardGlow;

  // --- Reparto vertical: constantes con motivo, no proporciones al azar ---

  /// Fracción del **alto de pantalla** que ocupa la mesa. Con ~44 % la
  /// mesa muestra 6 asientos + board + cartas del héroe con holgura y
  /// queda como elemento protagonista, dejando ~40 % para la explicación
  /// y ~15 % para encabezado + controles + barra del sistema. Se toma de
  /// la pantalla (no del hueco disponible) para que **no cambie** entre
  /// pasos ni entre pregunta y feedback.
  static const double _tableScreenFraction = 0.56;

  /// Techo relativo al ancho para el **área** de la mesa: evita que en
  /// pantallas muy altas el paño se estire vertical y se vea deforme.
  static const double _tableWidthCeiling = 1.05;

  /// Piso por debajo del cual cartas, avatares y posiciones dejan de
  /// leerse en los teléfonos más chicos.
  static const double _minTableHeight = 236;

  /// El panel necesita al menos esto (encabezado + ~2 líneas) antes de
  /// tener que hacer scroll interno.
  static const double _minPanelHeight = 116;

  static const double _gap = 12;

  /// Alto **estable** de la mesa, derivado del tamaño de pantalla.
  static double tableHeightFor(Size screen) => (screen.height *
          _tableScreenFraction)
      .clamp(_minTableHeight, screen.width * _tableWidthCeiling);

  @override
  State<TableExplanationView> createState() => _TableExplanationViewState();
}

class _TableExplanationViewState extends State<TableExplanationView>
    with SingleTickerProviderStateMixin {
  /// Pulso corto del foco: 0 → 1 cada vez que cambia el paso. La mesa NO se
  /// reconstruye; solo se reanima el resaltado.
  late final AnimationController _focus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void didUpdateWidget(TableExplanationView old) {
    super.didUpdateWidget(old);
    if (old.transitionTag != widget.transitionTag) {
      _focus.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Set<TableAnchor> get _highlightSet =>
      (widget.highlight.isEmpty ? [widget.anchor] : widget.highlight).toSet();

  @override
  Widget build(BuildContext context) {
    // Alto de la mesa: fracción del alto de PANTALLA (estable), pero sin
    // pasarse del hueco real menos el mínimo del panel (pantallas muy
    // cortas o controles muy altos).
    final screen = MediaQuery.of(context).size;
    final wantTable = TableExplanationView.tableHeightFor(screen);
    final hi = _highlightSet;

    return LayoutBuilder(builder: (context, constraints) {
      // El panel siempre conserva su mínimo: si el hueco no alcanza para
      // los dos, la mesa cede (hasta un piso duro) antes que aplastar la
      // explicación.
      final regionCap = constraints.maxHeight -
          TableExplanationView._minPanelHeight -
          TableExplanationView._gap;
      final tableHeight = math.max(
        150.0,
        math.min(wantTable, regionCap),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Mesa persistente (misma instancia toda la lección) ---
          SizedBox(
            height: tableHeight,
            child: AnimatedBuilder(
              animation: _focus,
              builder: (context, _) => PokerTableView(
                snapshot: widget.table,
                highlight: hi,
                dimOthers: widget.dimOthers,
                glow: Curves.easeOutCubic.transform(_focus.value),
                cardGlow: widget.cardGlow,
              ),
            ),
          ),
          const SizedBox(height: TableExplanationView._gap),
          // --- Explicación (el "profesor"): se ajusta a su contenido; el
          // espacio que sobra queda como aire sobre los controles, no como
          // una caja violeta vacía. Scroll interno sólo si el texto excede.
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              layoutBuilder: (current, previous) => Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  ...previous,
                  if (current != null) current,
                ],
              ),
              child: EducationalPanel(
                key: ValueKey('panel${widget.transitionTag}'),
                text: widget.text,
                stepNumber: widget.stepNumber,
                contextLabel: _anchorLabel(widget.anchor),
                icon: widget.panelIcon,
                accent: widget.accent,
              ),
            ),
          ),
        ],
      );
    });
  }

  String _anchorLabel(TableAnchor a) {
    switch (a.kind) {
      case TableAnchorKind.seat:
        final s = widget.table.seatAt(a.slot);
        return s.isHero ? 'VOS' : (s.name ?? s.label);
      case TableAnchorKind.bet:
        return 'LA APUESTA';
      case TableAnchorKind.pot:
        return 'EL BOTE';
      case TableAnchorKind.board:
        return switch (widget.table.board.length) {
          <= 3 => 'EL FLOP',
          4 => 'EL TURN',
          _ => 'EL RIVER',
        };
      case TableAnchorKind.heroCards:
        return 'TUS CARTAS';
    }
  }
}

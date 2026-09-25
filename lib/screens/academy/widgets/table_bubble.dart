import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_lesson.dart';
import '../../../theme/app_colors.dart';
import 'poker_table_view.dart';

/// La mesa con una burbuja de diálogo flotando encima, anclada al elemento
/// que se está señalando ([anchor]) y posicionada con la misma geometría
/// ([TableLayout]) que usa [PokerTableView] para el resto de la mesa.
///
/// Extraído de `visual_theory_stage.dart` (piloto visual, T093/T082/T098/
/// T099) para que `MentorLessonStageView` lo reutilice tal cual en vez de
/// duplicar la lógica de posicionamiento — es la única pieza de ese piloto
/// que un turno de mentor con mesa necesita.
class TableWithBubble extends StatelessWidget {
  const TableWithBubble({
    super.key,
    required this.table,
    required this.anchor,
    required this.highlight,
    required this.cardGlow,
    required this.glow,
    required this.bubbleText,
  });

  final TableSnapshot table;
  final TableAnchor anchor;
  final Set<TableAnchor> highlight;
  final Set<CardRef> cardGlow;
  final double glow;
  final String bubbleText;

  Offset _anchorPoint(TableLayout layout) {
    switch (anchor.kind) {
      case TableAnchorKind.seat:
        return layout.seat(anchor.slot);
      case TableAnchorKind.bet:
        return layout.bet(anchor.slot);
      case TableAnchorKind.pot:
        return layout.pot;
      case TableAnchorKind.board:
        return layout.board;
      case TableAnchorKind.heroCards:
        // Las cartas del héroe no tienen coordenada propia en TableLayout
        // (viven ancladas a su _PlayerPanel, en poker_table_view.dart) —
        // apuntamos al panel del héroe (asiento 0), de donde nacen.
        return layout.panel(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final layout = TableLayout(size);
      final maxBubbleWidth = size.width * 0.74;
      final target = _anchorPoint(layout);

      // Del lado con más lugar dentro del paño — nunca tapa al elemento
      // que está señalando.
      final spaceAbove = target.dy - layout.feltRect.top;
      final spaceBelow = layout.feltRect.bottom - target.dy;
      final placeBelow = spaceBelow > spaceAbove;

      const margin = 10.0;
      final halfW = maxBubbleWidth / 2;
      final left = (target.dx - halfW)
          .clamp(margin, size.width - margin - maxBubbleWidth);
      final boxCenterX = left + halfW;
      final tailOffsetX =
          (target.dx - boxCenterX).clamp(-halfW + 16, halfW - 16);

      final gap = 10.0 * layout.scale;
      final anchorY = placeBelow ? target.dy + gap : target.dy - gap;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: PokerTableView(
              snapshot: table,
              highlight: highlight,
              cardGlow: cardGlow,
              dimOthers: true,
              glow: glow,
            ),
          ),
          Positioned(
            left: left,
            width: maxBubbleWidth,
            top: placeBelow ? anchorY.clamp(0, size.height) : null,
            bottom: placeBelow
                ? null
                : (size.height - anchorY).clamp(0, size.height),
            child: SpeechBubble(
              key: ValueKey(bubbleText),
              text: bubbleText,
              maxWidth: maxBubbleWidth,
              scale: layout.scale,
              pointUp: placeBelow,
              tailOffsetX: tailOffsetX,
            ),
          ),
        ],
      );
    });
  }
}

/// La burbuja de diálogo en sí (cuerpo + colita), reutilizable fuera de
/// [TableWithBubble] — `MentorLessonStageView` la usa también para los
/// turnos de mentor con mesa.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    required this.maxWidth,
    required this.scale,
    required this.pointUp,
    required this.tailOffsetX,
  });

  final String text;
  final double maxWidth;
  final double scale;

  /// `true`: la burbuja está DEBAJO del elemento, la colita apunta hacia
  /// arriba (y va antes del cuerpo). `false`: arriba del elemento, colita
  /// hacia abajo (después del cuerpo).
  final bool pointUp;

  /// Corrimiento horizontal de la colita respecto al centro del cuerpo,
  /// para que siga apuntando al elemento aunque el cuerpo se haya corrido
  /// para no salirse de pantalla.
  final double tailOffsetX;

  @override
  Widget build(BuildContext context) {
    final tail = Transform.translate(
      offset: Offset(tailOffsetX, 0),
      child: CustomPaint(
        size: Size(14 * scale, 7 * scale),
        painter: BubbleTailPainter(pointUp: pointUp),
      ),
    );
    final box = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF14100A).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE0B860).withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.chat_bubble_rounded,
                size: 13 * scale, color: const Color(0xFFE0B860)),
            SizedBox(width: 7 * scale),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5 * scale,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * (pointUp ? 6 : -6)),
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: pointUp ? [tail, box] : [box, tail],
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  const BubbleTailPainter({this.pointUp = false});

  /// `false` (burbuja arriba del elemento): triángulo apunta hacia abajo.
  /// `true` (burbuja abajo del elemento): apunta hacia arriba.
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pointUp
        ? (Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width / 2, 0)
          ..close())
        : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close());
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF14100A).withValues(alpha: 0.94),
    );
  }

  @override
  bool shouldRepaint(covariant BubbleTailPainter oldDelegate) => false;
}

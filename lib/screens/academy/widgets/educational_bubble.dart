import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Una burbuja educativa que aparece sobre la mesa, conectada por una
/// línea al punto que explica. Aparece de a una.
///
/// Posicionamiento (mobile, portrait):
///  * la burbuja vive en la franja superior de la mesa (nunca tapa el
///    board, el bote ni las cartas del héroe);
///  * si el ancla está muy arriba, la burbuja va justo debajo;
///  * se clampea horizontalmente para no salirse de pantalla;
///  * ancho acotado (texto legible sin zoom) y una línea + punto conectan
///    la burbuja con el elemento que explica.
class EducationalBubble extends StatelessWidget {
  const EducationalBubble({
    super.key,
    required this.text,
    required this.anchor,
    required this.containerSize,
    required this.stepNumber,
  });

  final String text;
  final Offset anchor;
  final Size containerSize;
  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    final w = containerSize.width;
    final h = containerSize.height;

    final bubbleWidth = (w - 24).clamp(200.0, 280.0);
    final minCenter = bubbleWidth / 2 + 10;
    final maxCenter = (w - bubbleWidth / 2 - 10);
    final centerX = maxCenter <= minCenter
        ? w / 2
        : anchor.dx.clamp(minCenter, maxCenter);

    const gap = 12.0;

    // El ancla solo dispara "abajo" cuando está pegada al borde superior
    // (asiento de arriba al centro). El resto: burbuja arriba, con tope
    // para no invadir la zona central (board / bote / cartas del héroe).
    final placeBelow = anchor.dy < h * 0.20;

    // Y del borde de la burbuja que da al ancla.
    final double edgeY;
    if (placeBelow) {
      edgeY = anchor.dy + gap;
    } else {
      edgeY = (anchor.dy - gap).clamp(gap, h * 0.42);
    }

    final tailX = maxCenter <= minCenter
        ? anchor.dx
        : anchor.dx.clamp(
            centerX - bubbleWidth / 2 + 16,
            centerX + bubbleWidth / 2 - 16,
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: containerSize,
          painter: _ConnectorPainter(
            anchor: anchor,
            edge: Offset(tailX, edgeY),
          ),
        ),
        Positioned(
          left: centerX - bubbleWidth / 2,
          width: bubbleWidth.toDouble(),
          top: placeBelow ? edgeY : null,
          bottom: placeBelow ? null : (h - edgeY),
          child: _BubbleBox(
            text: text,
            stepNumber: stepNumber,
            tailUp: placeBelow,
            tailOffsetFromLeft: tailX - (centerX - bubbleWidth / 2),
          ),
        ),
      ],
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({required this.anchor, required this.edge});

  final Offset anchor;
  final Offset edge;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      anchor,
      edge,
      Paint()
        ..color = AppColors.violetBright.withValues(alpha: 0.8)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(anchor, 4, Paint()..color = AppColors.violetBright);
    canvas.drawCircle(
      anchor,
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.anchor != anchor || old.edge != edge;
}

class _BubbleBox extends StatelessWidget {
  const _BubbleBox({
    required this.text,
    required this.stepNumber,
    required this.tailUp,
    required this.tailOffsetFromLeft,
  });

  final String text;
  final int stepNumber;
  final bool tailUp;
  final double tailOffsetFromLeft;

  @override
  Widget build(BuildContext context) {
    final tail = CustomPaint(
      size: const Size(16, 7),
      painter: _TailPainter(up: tailUp),
    );

    final box = Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 12, 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          colors: [Color(0xFF241C4A), Color(0xFF171136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violetPrimary,
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.38,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    final clampedTail = tailOffsetFromLeft.clamp(14.0, 240.0) - 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tailUp)
          Padding(padding: EdgeInsets.only(left: clampedTail), child: tail),
        box,
        if (!tailUp)
          Padding(padding: EdgeInsets.only(left: clampedTail), child: tail),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter({required this.up});

  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF1D1642));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.violetPrimary.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => old.up != up;
}

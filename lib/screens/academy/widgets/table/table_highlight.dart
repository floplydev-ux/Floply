import 'package:flutter/material.dart';

import 'table_layout.dart';

/// Resaltado genérico (halo + pulso de escala) — envuelve cualquier pieza
/// de la mesa (panel, cartas, board, bote, ficha apostada) para marcarla
/// como el foco de un paso de lección. No sabe nada de a QUÉ envuelve.
class Highlightable extends StatelessWidget {
  const Highlightable({
    super.key,
    required this.child,
    required this.active,
    required this.glow,
    this.radius = 12,
    this.color = TableMaterial.focus,
  });

  final Widget child;
  final bool active;
  final double glow;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final pulse = glow.clamp(0.0, 1.0);
    return Transform.scale(
      scale: 1 + 0.05 * pulse,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28 + 0.42 * pulse),
              blurRadius: 10 + 12 * pulse,
              spreadRadius: 1 + 2 * pulse,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

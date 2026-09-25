import 'package:flutter/material.dart';

import 'table_layout.dart';

/// Paño — óvalo real (no rectángulo redondeado). Pinta fieltro, riel de
/// madera y textura; no sabe nada de jugadores, cartas ni fichas.
class TableSurfacePainter extends CustomPainter {
  const TableSurfacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final layout = TableLayout(size);
    final felt = layout.feltRect;
    // Riel de madera: un poco más grande que el paño en todas direcciones.
    final railMargin = felt.shortestSide * 0.065;
    final rail = felt.inflate(railMargin);
    final railOval = Rect.fromCenter(
      center: rail.center,
      width: rail.width,
      height: rail.height + railMargin * 0.4,
    );

    // Sombra propia del riel contra el fondo: separa la mesa del resto de
    // la pantalla, sensación de objeto apoyado.
    canvas.drawOval(
      railOval.shift(const Offset(0, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Riel: madera oscura con veta (gradiente + sheen superior).
    canvas.drawOval(
      railOval,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            TableMaterial.railSheen,
            TableMaterial.railLight,
            TableMaterial.railDark
          ],
          stops: [0.0, 0.35, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(railOval),
    );

    // Highlight superior del riel: sugiere una luz de arriba.
    canvas.save();
    canvas.clipPath(Path()..addOval(railOval));
    canvas.drawOval(
      railOval.deflate(1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = const LinearGradient(
          colors: [Color(0x4DFFE9C2), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment(0, 0.5),
        ).createShader(railOval),
    );
    canvas.restore();

    // Paño (verde), óvalo real, con viñeta radial: centro más claro.
    canvas.drawOval(
      felt,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.05,
          colors: [
            TableMaterial.feltCenter,
            TableMaterial.feltMid,
            TableMaterial.feltEdge
          ],
          stops: [0.0, 0.65, 1.0],
        ).createShader(felt),
    );

    // Textura del paño: puntos apenas perceptibles, en grilla fija (nunca
    // aleatoria: pintado una sola vez, tiene que quedar igual siempre).
    canvas.save();
    canvas.clipPath(Path()..addOval(felt));
    final dot = Paint()..color = Colors.black.withValues(alpha: 0.06);
    const spacing = 14.0;
    var row = 0;
    for (var y = felt.top; y < felt.bottom; y += spacing) {
      final offsetX = (row.isEven ? 0.0 : spacing / 2);
      for (var x = felt.left - spacing;
          x < felt.right + spacing;
          x += spacing) {
        canvas.drawCircle(Offset(x + offsetX, y), 0.6, dot);
      }
      row++;
    }
    canvas.restore();

    // Borde interior del paño: más marcado arriba (recibe la luz).
    canvas.drawOval(
      felt.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = const LinearGradient(
          colors: [Color(0x33FFE9C2), Color(0x0DFFE9C2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(felt),
    );
  }

  @override
  bool shouldRepaint(covariant TableSurfacePainter oldDelegate) => false;
}

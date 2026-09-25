import 'package:flutter/material.dart';

import 'table_layout.dart';

/// El botón de dealer — un elemento independiente del panel de jugador,
/// posicionado sobre el paño vía `TableLayout.dealerButton`. Solo sabe
/// dibujarse a sí mismo; no sabe qué asiento lo tiene.
class DealerButton extends StatelessWidget {
  const DealerButton({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final d = 15 * scale;
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [
            TableMaterial.goldBright,
            TableMaterial.gold,
            TableMaterial.goldDim
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        'D',
        style: TextStyle(
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2C1E10),
        ),
      ),
    );
  }
}

/// Badge de ganador — pequeño, elegante: no "GANÓ" gigante, un acento
/// dorado-verde con un ícono discreto. Vive junto a [DealerButton] porque
/// las dos son placas chicas de acento sobre la mesa, sin relación de
/// dependencia entre sí.
class WinnerMark extends StatelessWidget {
  const WinnerMark({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18 * scale,
      height: 18 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TableMaterial.success.withValues(alpha: 0.18),
        border: Border.all(color: TableMaterial.success.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: TableMaterial.success.withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(Icons.check_rounded,
          size: 11 * scale, color: TableMaterial.success),
    );
  }
}

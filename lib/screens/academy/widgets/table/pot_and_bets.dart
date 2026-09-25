import 'package:flutter/material.dart';

import '../poker_chip.dart';
import 'table_layout.dart';

/// El bote — fichas apiladas + monto, integrado directo con el paño (sin
/// caja/fondo detrás).
class PotBadge extends StatelessWidget {
  const PotBadge({super.key, required this.bb, this.scale = 1});

  final double bb;
  final double scale;

  /// Sombra de texto compartida por las dos líneas — el bote no tiene una
  /// caja detrás que lo separe del paño, así que el contraste contra el
  /// verde lo da esta sombra (el mismo recurso que usa [BetChip] para su
  /// cifra suelta sobre el fieltro), no un fondo propio.
  static const List<Shadow> _textShadows = [
    Shadow(color: Colors.black87, blurRadius: 4),
    Shadow(color: Colors.black54, blurRadius: 8),
  ];

  @override
  Widget build(BuildContext context) {
    // Sin Container/decoration: el bote se integra directo con el paño —
    // nada de caja negra, borde ni blur detrás. Las fichas apiladas son el
    // elemento principal; el texto flota al lado, legible por su propia
    // sombra.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokerChipStack(totalValue: bb.round(), scale: scale),
        SizedBox(width: 6 * scale),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOTE',
              style: TextStyle(
                fontSize: 7.5 * scale,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: TableMaterial.text,
                shadows: _textShadows,
              ),
            ),
            Text(
              '${formatBb(bb)} BB',
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
                color: TableMaterial.goldBright,
                fontFeatures: tabularFigures,
                shadows: _textShadows,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Entrada de las fichas apostadas: recorren un tramo corto desde el
/// asiento hacia su posición de reposo, con un fade.
class ChipEntrance extends StatelessWidget {
  const ChipEntrance({
    super.key,
    required this.from,
    required this.child,
  });

  final Offset from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset.lerp(from * 0.55, Offset.zero, t)!,
          child: c,
        ),
      ),
      child: child,
    );
  }
}

/// Ficha física (token circular con relieve) + cifra flotando al lado —
/// sin recuadro propio: es una ficha suelta sobre el paño, no una
/// etiqueta con fondo.
class BetChip extends StatelessWidget {
  const BetChip({super.key, required this.bb, this.scale = 1});

  final double bb;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokerChipStack(totalValue: bb.round(), scale: scale, faceDiameter: 12),
        SizedBox(width: 5 * scale),
        Text(
          '${formatBb(bb)} BB',
          style: TextStyle(
            fontSize: 9.5 * scale,
            fontWeight: FontWeight.w800,
            color: TableMaterial.goldBright,
            fontFeatures: tabularFigures,
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 4),
              Shadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

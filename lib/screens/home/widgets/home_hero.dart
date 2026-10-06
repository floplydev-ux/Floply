import 'package:flutter/material.dart';

import '../../../theme/sala_verde/sala_verde_tokens.dart';

/// Hero visual del Home: imagen de fondo en la parte superior de la
/// pantalla, a su proporción natural (sin deformar). Solo imagen + degradé
/// — sin texto encima. El top bar flota sobre este widget (ver
/// `home_screen.dart`).
///
/// La imagen mantiene su aspect ratio original (`BoxFit.fitWidth`):
/// ocupa todo el ancho disponible y su altura la determina la proporción
/// del asset, nunca se estira verticalmente. El degradé cubre el tercio
/// inferior y lleva la imagen a [SalaVerdeColors.background] de forma
/// imperceptible; debajo de la imagen el fondo del Scaffold continúa con
/// el mismo color, sin costura visible.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/home/home_background.jpg',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SalaVerdeColors.background.withValues(alpha: 0.0),
                  SalaVerdeColors.background.withValues(alpha: 0.0),
                  SalaVerdeColors.background.withValues(alpha: 0.10),
                  SalaVerdeColors.background.withValues(alpha: 0.40),
                  SalaVerdeColors.background.withValues(alpha: 0.72),
                  SalaVerdeColors.background.withValues(alpha: 0.92),
                  SalaVerdeColors.background.withValues(alpha: 0.99),
                  SalaVerdeColors.background,
                ],
                stops: const [0.0, 0.58, 0.68, 0.77, 0.86, 0.93, 0.97, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

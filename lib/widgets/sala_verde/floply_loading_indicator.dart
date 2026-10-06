import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Indicador de carga global de FLOPly: la ficha oficial (assets/images/
/// loading/floply_chip.png), revelada progresivamente mediante una máscara
/// circular que barre alrededor del centro — nunca un spinner genérico, y
/// la ficha en sí nunca gira como un disco (solo se revela).
///
/// Pensado para estados de carga prominentes (splash de arranque, pantalla
/// completa de una sección mientras carga sus datos), no para indicadores
/// diminutos embebidos en botones o tarjetas compactas — a menos de ~40dp
/// el detalle de la ficha deja de leerse y un spinner simple sigue siendo
/// la opción correcta ahí.
class FloplyLoadingIndicator extends StatefulWidget {
  const FloplyLoadingIndicator({
    super.key,
    this.size = 72,
    this.duration = const Duration(milliseconds: 1600),
    this.backgroundColor,
    this.ghostOpacity = 0.16,
  });

  /// Lado del cuadrado que contiene la ficha (proporción 1:1 siempre — la
  /// imagen nunca se deforma, solo se escala con `BoxFit.contain`).
  final double size;

  /// Duración de una vuelta completa del barrido. Se puede ajustar por
  /// contexto sin duplicar el widget (p. ej. más lento en un splash largo).
  final Duration duration;

  /// Fondo opcional detrás de la ficha — por defecto transparente, pensado
  /// para integrarse con el fondo oscuro/verde de FLOPly. Pasar un color
  /// (p. ej. blanco u oscuro con alpha) cuando el indicador deba vivir
  /// sobre un fondo claro y la ficha necesite contraste propio.
  final Color? backgroundColor;

  /// Opacidad de la ficha completa, siempre visible por debajo del barrido
  /// — evita un flash vacío al iniciar y al reiniciar cada vuelta.
  final double ghostOpacity;

  static const _chipAsset = 'assets/images/loading/floply_chip.png';

  @override
  State<FloplyLoadingIndicator> createState() => _FloplyLoadingIndicatorState();
}

class _FloplyLoadingIndicatorState extends State<FloplyLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void didUpdateWidget(covariant FloplyLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chip = Image.asset(FloplyLoadingIndicator._chipAsset, fit: BoxFit.contain);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final sweep = Curves.easeInOutSine.transform(_controller.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(opacity: widget.ghostOpacity, child: chip),
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => SweepGradient(
                    transform: const GradientRotation(-math.pi / 2),
                    colors: const [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, sweep, sweep],
                    tileMode: TileMode.clamp,
                  ).createShader(bounds),
                  child: chip,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

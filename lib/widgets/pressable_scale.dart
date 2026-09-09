import 'package:flutter/material.dart';

/// Envuelve a [child] y lo achica levemente mientras se lo mantiene
/// presionado, dando feedback táctil a cualquier botón/tarjeta tocable
/// de la app sin depender de un paquete externo.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleWhenPressed = 0.96,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleWhenPressed;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleWhenPressed : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Botón-píldora de acceso para los banners del Home.
/// Pieza física integrada: fondo oscuro con tinte verde, borde dorado
/// sutil, label "ENTRAR" + flecha. Tap target independiente con
/// scale-down propio.
class HomeBannerActionButton extends StatefulWidget {
  const HomeBannerActionButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<HomeBannerActionButton> createState() =>
      _HomeBannerActionButtonState();
}

class _HomeBannerActionButtonState extends State<HomeBannerActionButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _pressed ? 0.90 : _pulseAnim.value,
          child: child,
        ),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xCC101B17),
            border: Border.all(
              color: const Color(0x99D7B56D),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_forward_rounded,
            size: 20,
            color: Color(0xFFD7B56D),
          ),
        ),
      ),
    );
  }
}

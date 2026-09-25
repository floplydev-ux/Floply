import 'package:flutter/material.dart';

import '../models/nav_destination.dart';
import '../theme/app_colors.dart';

/// Barra de navegación inferior de la app.
///
/// Widget controlado: el padre decide qué pestaña está activa
/// ([currentIndex]) y qué pasa al tocar cada una ([onTap]). Los 5 destinos
/// salen de [kNavDestinations], la misma fuente que usan las pantallas
/// placeholder, para que íconos y labels no se dupliquen.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (int i = 0; i < kNavDestinations.length; i++)
                Expanded(
                  child: _NavButton(
                    data: kNavDestinations[i],
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final NavDestination data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // textMuted no llega al contraste WCAG AA sobre backgroundSecondary
    // (hallazgo real de accessibility, Fase 1 Bloque 1) — textSecondary sí,
    // sin perder la distinción visual con el tab activo (violetBright).
    final color = isActive ? AppColors.violetBright : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(data.icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              data.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

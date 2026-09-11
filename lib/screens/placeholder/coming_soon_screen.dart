import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/nav_destination.dart';
import '../../theme/app_colors.dart';

/// Pantalla de relleno para cualquier destino que todavía no tiene
/// funcionalidad real (Academia, Laboratorio, Estadísticas, Perfil).
///
/// Reemplazar esto por la pantalla real es tan simple como intercambiar
/// este widget por la implementación definitiva en [AppShell]; el resto
/// de la app (bottom nav, botones que navegan hacia acá) no cambia.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.destination});

  final NavDestination destination;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.violetPrimary.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.4)),
                  ),
                  child: Icon(destination.icon, color: AppColors.violetSoft, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  destination.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Text(
                    AppStrings.comingSoonTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonGreenBright,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  AppStrings.comingSoonBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

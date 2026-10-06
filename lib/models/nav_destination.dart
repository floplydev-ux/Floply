import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Un destino de navegación de la app (usado por la bottom nav y por las
/// pantallas placeholder), para no duplicar íconos/labels en varios lugares.
class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Los 5 destinos de la navegación inferior, en orden.
const List<NavDestination> kNavDestinations = [
  NavDestination(icon: Icons.home_rounded, label: AppStrings.navHome),
  NavDestination(icon: Icons.school_rounded, label: AppStrings.navAcademy),
  NavDestination(icon: Icons.fitness_center_rounded, label: AppStrings.navLab),
  NavDestination(icon: Icons.sports_rounded, label: AppStrings.navCoach),
  NavDestination(icon: Icons.person_rounded, label: AppStrings.navProfile),
];

/// Destinos que no tienen pestaña propia pero sí una tarjeta en la Home
/// (Tools, Coach), igual que Bankroll. No forman parte de
/// [kNavDestinations] porque no son pestañas de la navegación inferior —
/// se llega a ellos desde una tarjeta de Home. Tools abre `ToolsScreen` y
/// Coach abre `CoachTableScreen` (Grupo 8) directamente — ninguno de los
/// dos usa ya [ComingSoonScreen] como destino real.
const NavDestination kToolsDestination =
    NavDestination(icon: Icons.insights_rounded, label: AppStrings.navTools);
const NavDestination kCoachDestination =
    NavDestination(icon: Icons.sports_rounded, label: AppStrings.navCoach);

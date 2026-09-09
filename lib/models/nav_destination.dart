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
  NavDestination(icon: Icons.science_rounded, label: AppStrings.navLab),
  NavDestination(icon: Icons.bar_chart_rounded, label: AppStrings.navStats),
  NavDestination(icon: Icons.person_rounded, label: AppStrings.navProfile),
];

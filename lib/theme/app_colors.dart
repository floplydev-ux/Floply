import 'package:flutter/material.dart';

/// Paleta de colores centralizada de la aplicación.
///
/// Ningún widget debería declarar un `Color(0x...)` "suelto": todo color
/// vive acá. Esto permite re-tematizar la app (modo claro, rebranding,
/// temporadas especiales) modificando un solo archivo.
class AppColors {
  AppColors._();

  // Fondos
  static const Color background = Color(0xFF060812);
  static const Color backgroundSecondary = Color(0xFF0B0E1D);
  static const Color surface = Color(0xFF12162A);
  static const Color surfaceElevated = Color(0xFF1A1F3A);
  static const Color surfaceBorder = Color(0xFF2A2F4A);

  // Marca — violeta (Academia / progreso)
  static const Color violetPrimary = Color(0xFF8B5CF6);
  static const Color violetBright = Color(0xFFA78BFA);
  static const Color violetDeep = Color(0xFF3B1670);
  static const Color violetSoft = Color(0xFFC4B5FD);

  // Acento secundario — verde neón (Laboratorio)
  static const Color neonGreen = Color(0xFF22E584);
  static const Color neonGreenBright = Color(0xFF5CFFA8);
  static const Color neonGreenDeep = Color(0xFF0B3B27);

  // Utilitarios / gamificación
  static const Color gold = Color(0xFFFFC94A);
  static const Color diamondBlue = Color(0xFF4FD1FF);
  static const Color danger = Color(0xFFFF5C6E);
  static const Color warning = Color(0xFFFFA84A);

  // Texto
  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFFAAB0CC);
  static const Color textMuted = Color(0xFF6E7392);

  // Gradientes reutilizables
  static const List<Color> backgroundGradient = [
    Color(0xFF13172E),
    Color(0xFF060812),
  ];

  static const List<Color> violetGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF3B1670),
  ];

  static const List<Color> greenGradient = [
    Color(0xFF1E9E63),
    Color(0xFF0B3B27),
  ];

  static const List<Color> levelShieldGradient = [
    Color(0xFFB794F6),
    Color(0xFF5B21B6),
    Color(0xFF1A1035),
  ];

  // Fondos de tarjeta oscuros (Home / Laboratorio / mapa de Academia)
  static const List<Color> greenCardDeepGradient = [
    Color(0xFF0E2A20),
    Color(0xFF081712),
  ];

  static const List<Color> violetCardDeepGradient = [
    Color(0xFF241249),
    Color(0xFF120A2A),
  ];

  static const List<Color> violetStripGradient = [
    Color(0xFF1B1140),
    Color(0xFF120C29),
  ];

  /// Rojo de palo (corazones/diamantes) para las cartas chicas del
  /// Laboratorio — no el mismo tono que `TableMaterial.cardRed` de la mesa
  /// (paleta deliberadamente distinta, ver `table/table_layout.dart`).
  static const Color cardSuitRed = Color(0xFFD1345B);
}

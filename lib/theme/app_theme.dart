import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'sala_verde/sala_verde_typography.dart';

/// Tema visual global (Material 3, modo oscuro).
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    // TextTheme base con fuentes Sala Verde, colores de AppColors aplicados.
    final svTextTheme = SalaVerdeTypography.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.violetPrimary,
        secondary: AppColors.neonGreen,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: AppColors.textPrimary,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: svTextTheme,
      splashFactory: InkRipple.splashFactory,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
    );
  }
}

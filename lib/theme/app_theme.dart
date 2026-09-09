import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema visual global (Material 3, modo oscuro).
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

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
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            headlineSmall: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
            titleMedium: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            bodyMedium: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
            labelLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
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

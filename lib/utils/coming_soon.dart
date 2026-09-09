import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// Muestra un aviso breve para cualquier acción/pantalla que todavía no
/// esté implementada en esta etapa del proyecto.
///
/// Centralizar esto en una sola función evita repetir el mismo
/// `ScaffoldMessenger.of(context).showSnackBar(...)` en cada widget que
/// todavía no tiene funcionalidad real (login, backend, navegación, etc).
void showComingSoon(BuildContext context, {String? feature}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: AppColors.violetBright, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature == null
                  ? AppStrings.comingSoonBody
                  : '$feature — ${AppStrings.comingSoonTitle.toLowerCase()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

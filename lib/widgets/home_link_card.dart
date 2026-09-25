import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable_scale.dart';

/// Banner compacto de acceso a un módulo secundario de la Home (Bankroll,
/// Tools, Coach): ícono + título + descripción + trailing, un solo color
/// de acento. Deliberadamente más chico que las tarjetas principales
/// (Academia, Practice Room) — estos módulos complementan, no compiten.
///
/// Generalizado a partir de la forma que ya tenía `BankrollCard` para no
/// repetir el mismo `BoxDecoration`/`Row` tres veces.
class HomeLinkCard extends StatelessWidget {
  const HomeLinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  /// Visualmente subordinado: opacidad reducida, sin sombra/brillo propio.
  /// Pensado para secciones "preparadas para el futuro" (Coach) que no
  /// deben competir con Academia.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accentColor.withValues(alpha: 0.08),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: accentColor, size: 22),
        ],
      ),
    );

    return PressableScale(
      onTap: onTap,
      child: muted ? Opacity(opacity: 0.6, child: content) : content,
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/user_progress.dart';
import '../theme/app_colors.dart';
import '../utils/coming_soon.dart';
import '../utils/formatters.dart';
import 'pressable_scale.dart';

/// Encabezado superior de la Home: avatar + nivel, nombre y rango,
/// barra de XP, y a la derecha monedas / diamantes / notificaciones.
class UserHeader extends StatelessWidget {
  const UserHeader({super.key, required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(level: progress.level),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        progress.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 19,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress.rankTitle,
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isNarrow) ...[
                        const SizedBox(height: 10),
                        _ActionsRow(progress: progress),
                      ],
                    ],
                  ),
                ),
                if (!isNarrow) _ActionsRow(progress: progress),
              ],
            ),
            const SizedBox(height: 14),
            _XpBar(progress: progress),
          ],
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    const double size = 62;
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2.4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.violetGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundSecondary,
              ),
              child: const Icon(
                Icons.style_rounded,
                color: AppColors.violetSoft,
                size: 26,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
              ),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.violetBright, AppColors.violetDeep],
                  ),
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Chip(
          icon: Icons.monetization_on_rounded,
          iconColor: AppColors.gold,
          label: formatThousands(progress.coins),
          onTap: () => showComingSoon(context, feature: 'Tienda de monedas'),
        ),
        _Chip(
          icon: Icons.diamond_rounded,
          iconColor: AppColors.diamondBlue,
          label: formatThousands(progress.diamonds),
          onTap: () => showComingSoon(context, feature: 'Tienda de diamantes'),
        ),
        PressableScale(
          onTap: () => showComingSoon(context, feature: 'Notificaciones'),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                ),
                if (progress.hasUnreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 10,
            color: AppColors.surfaceElevated,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.xpProgress),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [AppColors.violetBright, AppColors.violetPrimary],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${formatThousands(progress.xp)} / ${formatThousands(progress.xpRequired)} ${AppStrings.xpSuffix}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

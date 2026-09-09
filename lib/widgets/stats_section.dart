import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/user_progress.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_card.dart';

/// Fila de estadísticas rápidas (precisión, ranking, ejercicios, actividad).
///
/// En pantallas angostas, si las 4 tarjetas no entran cómodamente, la
/// sección se vuelve desplazable horizontalmente en lugar de recortarse.
class StatsSection extends StatelessWidget {
  const StatsSection({super.key, required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.track_changes_rounded,
        iconColor: AppColors.diamondBlue,
        label: AppStrings.accuracyLabel,
        value: '${progress.accuracyPercent}%',
        caption: '+${progress.accuracyWeeklyDelta}% ${AppStrings.thisWeekLabel}',
        captionColor: AppColors.neonGreenBright,
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        iconColor: AppColors.gold,
        label: AppStrings.rankingLabel,
        value: '#${formatThousands(progress.rankingPosition)}',
        caption: AppStrings.topPercent(progress.rankingTopPercent),
        captionColor: AppColors.textMuted,
      ),
      _StatItem(
        icon: Icons.bar_chart_rounded,
        iconColor: AppColors.danger,
        label: AppStrings.exercisesLabel,
        value: formatThousands(progress.exercisesCompleted),
        caption: AppStrings.completedLabel,
        captionColor: AppColors.textMuted,
      ),
      _StatItem(
        icon: Icons.event_available_rounded,
        iconColor: AppColors.violetBright,
        label: AppStrings.activityLabel,
        value: '${progress.activeDaysThisWeek} ${AppStrings.daysSuffix}',
        caption: AppStrings.thisWeekLabel,
        captionColor: AppColors.textMuted,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final naturalWidth = (constraints.maxWidth - spacing * (items.length - 1)) / items.length;
        final itemWidth = naturalWidth < 128 ? 150.0 : naturalWidth;
        final needsScroll = itemWidth * items.length + spacing * (items.length - 1) >
            constraints.maxWidth + 0.5;

        final row = Row(
          mainAxisSize: needsScroll ? MainAxisSize.min : MainAxisSize.max,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              SizedBox(width: itemWidth, child: items[i]),
            ],
          ],
        );

        if (!needsScroll) return row;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: row,
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.caption,
    required this.captionColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;
  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: captionColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/user_progress.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Tarjeta de "misión" semanal, con progreso y recompensa, con estética de
/// videojuego.
class WeeklyChallengeCard extends StatelessWidget {
  const WeeklyChallengeCard({super.key, required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.diamondBlue.withValues(alpha: 0.35),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 360;

          final iconAndText = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.diamondBlue.withValues(alpha: 0.16),
                  border: Border.all(color: AppColors.diamondBlue.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: AppColors.diamondBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.weeklyChallengeTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.diamondBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.weeklyChallengeDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ChallengeProgressBar(
                      progress: progress.weeklyChallengeProgressRatio,
                      current: progress.weeklyChallengeProgress,
                      goal: progress.weeklyChallengeGoal,
                    ),
                  ],
                ),
              ),
            ],
          );

          final reward = _RewardBadge(diamonds: progress.weeklyChallengeRewardDiamonds);

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                iconAndText,
                const SizedBox(height: 14),
                reward,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: iconAndText),
              const SizedBox(width: 14),
              reward,
            ],
          );
        },
      ),
    );
  }
}

class _ChallengeProgressBar extends StatelessWidget {
  const _ChallengeProgressBar({
    required this.progress,
    required this.current,
    required this.goal,
  });

  final double progress;
  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceElevated),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.diamondBlue, AppColors.violetBright],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$current / $goal',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.diamonds});

  final int diamonds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.diamondBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            AppStrings.rewardLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond_rounded, color: AppColors.diamondBlue, size: 16),
              const SizedBox(width: 6),
              Text(
                '$diamonds',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/user_progress.dart';
import '../theme/app_colors.dart';

/// Sección de progreso debajo del header: racha actual, racha máxima, y
/// un escudo grande y luminoso en el centro con el nivel del usuario.
class ProgressStreakSection extends StatefulWidget {
  const ProgressStreakSection({super.key, required this.progress});

  final UserProgress progress;

  @override
  State<ProgressStreakSection> createState() => _ProgressStreakSectionState();
}

class _ProgressStreakSectionState extends State<ProgressStreakSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StreakBlock(
                label: AppStrings.streakCurrentLabel,
                days: progress.currentStreakDays,
                alignEnd: false,
              ),
            ),
            SizedBox(
              width: 128,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glow = 0.55 + (_pulseController.value * 0.35);
                  return _LevelShield(level: progress.level, glowIntensity: glow);
                },
              ),
            ),
            Expanded(
              child: _StreakBlock(
                label: AppStrings.streakBestLabel,
                days: progress.bestStreakDays,
                alignEnd: true,
              ),
            ),
          ],
        ),
        if (progress.motivationalQuote.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '“${progress.motivationalQuote}”',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _StreakBlock extends StatelessWidget {
  const _StreakBlock({
    required this.label,
    required this.days,
    required this.alignEnd,
  });

  final String label;
  final int days;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignEnd) ...[
              const Text('🔥', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 4),
              const Text('🔥', style: TextStyle(fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$days ',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: AppStrings.daysSuffix,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Escudo grande y luminoso con el número de nivel superpuesto, y la
/// etiqueta "NIVEL" debajo. Es el elemento visual central de la sección
/// de progreso.
class _LevelShield extends StatelessWidget {
  const _LevelShield({required this.level, required this.glowIntensity});

  final int level;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    AppColors.violetBright,
                    AppColors.violetDeep,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violetPrimary.withOpacity(glowIntensity * 0.55),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.shield_rounded,
              size: 74,
              color: Colors.white.withOpacity(0.16),
            ),
            Text(
              '$level',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.levelLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

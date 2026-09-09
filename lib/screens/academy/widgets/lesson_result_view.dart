import 'package:flutter/material.dart';

import '../../../engine/pedagogy/curriculum.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart';

/// Fase resultado del lesson: aprobó / no aprobó, puntaje de evaluación,
/// conceptos flojos y los botones de recuperación / reintento / volver.
class LessonResultView extends StatelessWidget {
  const LessonResultView({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final outcome = controller.lastOutcome;
    if (outcome == null) return const SizedBox.shrink();

    final passed = outcome.passed;
    final lesson = controller.academy.lessonById(outcome.lessonId);
    final isAssessment = lesson?.kind == LessonKind.assessment;
    final accent = passed ? AppColors.neonGreen : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.surface,
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                passed
                    ? Icons.celebration_rounded
                    : Icons.replay_circle_filled_rounded,
                color: accent,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                passed
                    ? (isAssessment
                        ? AppStrings.academyPassed
                        : AppStrings.academyLessonDone)
                    : AppStrings.academyNotPassed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isAssessment) ...[
                const SizedBox(height: 6),
                Text(
                  AppStrings.academyScore((outcome.score * 100).round()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (!passed && outcome.weakConceptIds.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.academyPracticeMore,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outcome.weakConceptIds
                            .map(controller.conceptName)
                            .join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!passed && outcome.recovery != null)
          LessonPrimaryButton(
            label: AppStrings.academyStartRecovery,
            onTap: controller.startRecovery,
          ),
        if (!passed && outcome.recovery != null) const SizedBox(height: 10),
        if (!passed)
          LessonSecondaryButton(
            label: AppStrings.academyRetry,
            onTap: controller.retryLesson,
          ),
        if (passed)
          LessonPrimaryButton(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
        if (!passed) const SizedBox(height: 10),
        if (!passed)
          LessonSecondaryButton(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
      ],
    );
  }
}

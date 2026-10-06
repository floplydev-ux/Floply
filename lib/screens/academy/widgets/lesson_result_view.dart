import 'package:flutter/material.dart';

import '../../../engine/pedagogy/curriculum.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy_controller.dart';
import 'lesson_completion_banner.dart';

/// Fase resultado del lesson: aprobó / no aprobó, puntaje de evaluación,
/// conceptos flojos y los botones de recuperación / reintento / volver.
///
/// **Fase 5**: migrado a "Sala Verde". Mismo scoring/outcome/callbacks —
/// solo cambia la presentación.
class LessonResultView extends StatelessWidget {
  const LessonResultView({
    super.key,
    required this.controller,
    this.isPremium = false,
  });

  final AcademyController controller;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final outcome = controller.lastOutcome;
    if (outcome == null) return const SizedBox.shrink();

    final isReview = controller.isCumulativeReview;
    final passed = outcome.passed;
    final lesson = controller.academy.lessonById(outcome.lessonId);
    final isAssessment = lesson?.kind == LessonKind.assessment;
    final showScore = isAssessment || isReview;
    final accent = passed ? SalaVerdeColors.feltGreenBright : SalaVerdeColors.warning;
    final pendingReviewId = controller.pendingReviewId;
    final offerReview = !isReview && passed && pendingReviewId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SvSurfacePanel(
          borderColor: accent.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(SalaVerdeSpace.xl),
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
              const SizedBox(height: SalaVerdeSpace.sm),
              Text(
                isReview
                    ? AppStrings.academyReviewDone
                    : (passed
                        ? (isAssessment
                            ? AppStrings.academyPassed
                            : AppStrings.academyLessonDone)
                        : AppStrings.academyNotPassed),
                textAlign: TextAlign.center,
                style: SalaVerdeType.headline(),
              ),
              if (showScore) ...[
                const SizedBox(height: SalaVerdeSpace.xs),
                Text(
                  AppStrings.academyScore((outcome.score * 100).round()),
                  textAlign: TextAlign.center,
                  style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.textSecondary),
                ),
              ],
              if (!isReview && !passed && outcome.weakConceptIds.isNotEmpty) ...[
                const SizedBox(height: SalaVerdeSpace.md),
                Container(
                  padding: const EdgeInsets.all(SalaVerdeSpace.md),
                  decoration: BoxDecoration(
                    color: SalaVerdeColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.academyPracticeMore,
                        style: SalaVerdeType.label(color: SalaVerdeColors.warning),
                      ),
                      const SizedBox(height: SalaVerdeSpace.xs),
                      Text(
                        outcome.weakConceptIds
                            .map(controller.conceptName)
                            .join(', '),
                        style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Banner solo en lección completada exitosamente (no en fallo, no en review).
        if (!isReview && passed)
          LessonCompletionBanner(isPremium: isPremium),
        const SizedBox(height: SalaVerdeSpace.lg),
        if (!isReview && !passed && outcome.recovery != null) ...[
          SvButtonPrimary(
            label: AppStrings.academyStartRecovery,
            onTap: controller.startRecovery,
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
        ],
        if (!isReview && !passed)
          SvButtonSecondary(
            label: AppStrings.academyRetry,
            onTap: controller.retryLesson,
          ),
        if (offerReview) ...[
          SvButtonPrimary(
            label: AppStrings.academyStartReview,
            onTap: () => controller.startCumulativeReview(pendingReviewId),
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          SvButtonSecondary(
            label: AppStrings.academyReviewLater,
            onTap: controller.exitLesson,
          ),
        ] else if (passed || isReview)
          SvButtonPrimary(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
        if (!isReview && !passed) ...[
          const SizedBox(height: SalaVerdeSpace.sm),
          SvButtonSecondary(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
        ],
      ],
    );
  }
}

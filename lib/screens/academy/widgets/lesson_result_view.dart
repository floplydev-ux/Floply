import 'package:flutter/material.dart';

import '../../../engine/pedagogy/curriculum.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy_controller.dart';

/// Fase resultado del lesson: aprobó / no aprobó, puntaje de evaluación,
/// conceptos flojos y los botones de recuperación / reintento / volver.
///
/// **Fase 5**: migrado a "Sala Verde". Mismo scoring/outcome/callbacks —
/// solo cambia la presentación.
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
    final accent = passed ? SalaVerdeColors.feltGreenBright : SalaVerdeColors.warning;

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
                passed
                    ? (isAssessment
                        ? AppStrings.academyPassed
                        : AppStrings.academyLessonDone)
                    : AppStrings.academyNotPassed,
                textAlign: TextAlign.center,
                style: SalaVerdeType.headline(),
              ),
              if (isAssessment) ...[
                const SizedBox(height: SalaVerdeSpace.xs),
                Text(
                  AppStrings.academyScore((outcome.score * 100).round()),
                  textAlign: TextAlign.center,
                  style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.textSecondary),
                ),
              ],
              if (!passed && outcome.weakConceptIds.isNotEmpty) ...[
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
        const SizedBox(height: SalaVerdeSpace.lg),
        if (!passed && outcome.recovery != null)
          SvButtonPrimary(
            label: AppStrings.academyStartRecovery,
            onTap: controller.startRecovery,
          ),
        if (!passed && outcome.recovery != null)
          const SizedBox(height: SalaVerdeSpace.sm),
        if (!passed)
          SvButtonSecondary(
            label: AppStrings.academyRetry,
            onTap: controller.retryLesson,
          ),
        if (passed)
          SvButtonPrimary(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
        if (!passed) const SizedBox(height: SalaVerdeSpace.sm),
        if (!passed)
          SvButtonSecondary(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
      ],
    );
  }
}

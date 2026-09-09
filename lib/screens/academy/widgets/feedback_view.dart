import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../laboratory/widgets/feedback_panel.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart';

/// Fase feedback de un ítem: `FeedbackPanel` del motor o una tarjeta
/// simple con el texto, + SIGUIENTE / VER RESULTADO.
class FeedbackView extends StatelessWidget {
  const FeedbackView({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final fb = controller.lastFeedback;
    if (fb == null) return const SizedBox.shrink();
    final last = controller.itemNumber >= controller.itemTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonItemProgress(
          current: controller.itemNumber,
          total: controller.itemTotal,
        ),
        const SizedBox(height: 14),
        if (fb.evaluation != null && fb.exercise != null)
          FeedbackPanel(
            result: fb.evaluation!,
            strategy: fb.exercise!.strategy,
            showAdvanced: false,
            onToggleAdvanced: () {},
            conceptName: controller.conceptName,
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surface,
              border: Border.all(
                color: fb.correct
                    ? AppColors.neonGreen.withValues(alpha: 0.5)
                    : AppColors.danger.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              fb.text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        LessonPrimaryButton(
          label: last ? AppStrings.academySeeResult : AppStrings.academyNext,
          onTap: controller.nextItem,
        ),
      ],
    );
  }
}

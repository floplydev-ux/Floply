import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../laboratory/widgets/feedback_panel.dart';
import '../academy_controller.dart';
import 'educational_panel.dart';
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
          EducationalPanel(
            text: fb.text,
            accent: fb.correct ? AppColors.neonGreen : AppColors.danger,
            icon: fb.correct ? Icons.check_rounded : Icons.close_rounded,
            contextLabel: fb.correct ? 'BIEN' : 'REVISÁ ESTO',
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

import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart';
import 'table_explanation_view.dart';

/// La lección interactiva: una mano de póker que se desarrolla mientras el
/// "profesor" explica. Cada paso muestra la mesa y su explicación —en una
/// burbuja contextual si el texto es corto y hay lugar, o en el panel
/// educativo debajo de la mesa si no— y el usuario avanza con
/// CONTINUAR / ATRÁS.
class InteractiveTableLesson extends StatelessWidget {
  const InteractiveTableLesson({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final step = c.currentTableStep;
    if (step == null) return const SizedBox.shrink();

    final total = c.tableStepCount;
    final current = c.tableStep + 1;
    final table = c.castTable(step.table);
    final bubbleText = c.resolveText(step.bubble, table);

    return Column(
      children: [
        _StepDots(total: total, current: c.tableStep),
        const SizedBox(height: 6),
        Expanded(
          child: TableExplanationView(
            table: table,
            text: bubbleText,
            anchor: step.anchor,
            highlight: step.effectiveHighlight,
            dimOthers: step.dimOthers,
            stepNumber: current,
            transitionTag: 'lesson${c.tableStep}',
            panelIcon: Icons.school_rounded,
          ),
        ),
        const SizedBox(height: 10),
        LessonNavControls(
          canGoBack: !c.isFirstTableStep,
          // Si después del guion vienen fichas de teoría redactada, el último
          // paso todavía es "CONTINUAR": la práctica llega más tarde.
          buttonLabel: (c.isLastTableStep && !c.hasWrittenTheory)
              ? AppStrings.academyStartPractice
              : AppStrings.academyContinue,
          counter: '$current / $total',
          onBack: c.prevTableStep,
          onNext: c.nextTableStep,
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0)
            Container(
              width: 12,
              height: 1.5,
              color: i <= current
                  ? AppColors.violetPrimary
                  : AppColors.surfaceBorder,
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == current ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i <= current
                  ? AppColors.violetBright
                  : AppColors.surfaceElevated,
            ),
          ),
        ],
      ],
    );
  }
}

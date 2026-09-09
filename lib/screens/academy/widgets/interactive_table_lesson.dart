import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import '../academy_controller.dart';
import 'educational_bubble.dart';
import 'poker_table_view.dart';

/// La lección interactiva: una mano de póker que se desarrolla mientras el
/// "profesor" explica con burbujas contextuales, una por una. El usuario
/// avanza a mano con CONTINUAR / ATRÁS.
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

    return Column(
      children: [
        _StepDots(total: total, current: c.tableStep),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final layout = TableLayout(size);
            final anchorPoint = layout.anchorPoint(step.anchor);
            final highlight = step.effectiveHighlight.toSet();
            final table = c.castTable(step.table);
            final bubbleText = c.resolveText(step.bubble, table);

            // Una animación de entrada por paso (0→1), sin ticker que
            // quede corriendo: aparece y descansa.
            return TweenAnimationBuilder<double>(
              key: ValueKey('anim${c.tableStep}'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOut,
                        child: PokerTableView(
                          key: ValueKey('table${c.tableStep}'),
                          snapshot: table,
                          highlight: highlight,
                          dimOthers: step.dimOthers,
                          glow: t,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale:
                              Tween<double>(begin: 0.92, end: 1).animate(anim),
                          child: child,
                        ),
                      ),
                      child: EducationalBubble(
                        key: ValueKey('bubble${c.tableStep}'),
                        text: bubbleText,
                        anchor: anchorPoint,
                        containerSize: size,
                        stepNumber: current,
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        _Controls(
          current: current,
          total: total,
          canGoBack: !c.isFirstTableStep,
          isLast: c.isLastTableStep,
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

class _Controls extends StatelessWidget {
  const _Controls({
    required this.current,
    required this.total,
    required this.canGoBack,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  final int current;
  final int total;
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: canGoBack
              ? PressableScale(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: const Text(
                      AppStrings.academyBack,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$current / $total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PressableScale(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: AppColors.violetGradient),
              ),
              child: Text(
                isLast
                    ? AppStrings.academyStartPractice
                    : AppStrings.academyContinue,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

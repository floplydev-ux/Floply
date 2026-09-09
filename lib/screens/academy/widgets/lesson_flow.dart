import 'package:flutter/material.dart';

import '../../../engine/pedagogy/curriculum.dart';
import '../../../engine/pedagogy/lesson_content.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import '../../laboratory/widgets/exercise_card.dart';
import '../../laboratory/widgets/feedback_panel.dart';
import '../academy_controller.dart';
import 'interactive_table_exercise.dart';
import 'interactive_table_lesson.dart';

/// El recorrido de un lesson: teoría → ejercicios → feedback → resultado.
class LessonFlow extends StatelessWidget {
  const LessonFlow({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final lessonId = controller.activeLessonId;
    final lesson = lessonId == null ? null : controller.academy.lessonById(lessonId);

    final header = _FlowHeader(
      title: lesson == null ? '' : '${lesson.id}  ${lesson.title}',
      subtitle: controller.isRecovering
          ? AppStrings.academyRecoveryTitle
          : (lesson?.kind.label ?? ''),
      onBack: controller.exitLesson,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;

      // Teoría / ejercicios interactivos sobre la mesa: ocupan toda la
      // altura (no van dentro del scroll).
      if (controller.isInteractiveTheory || controller.isInteractiveExercise) {
        return Padding(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              Expanded(
                child: controller.isInteractiveTheory
                    ? InteractiveTableLesson(controller: controller)
                    : InteractiveTableExercise(
                        key: ValueKey('itex${controller.itemNumber}'),
                        controller: controller,
                      ),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 16),
            _body(context),
          ],
        ),
      );
    });
  }

  Widget _body(BuildContext context) {
    switch (controller.phase) {
      case AcademyPhase.theory:
        return _TheoryView(controller: controller);
      case AcademyPhase.exercise:
        return _ExerciseView(controller: controller);
      case AcademyPhase.feedback:
        return _FeedbackView(controller: controller);
      case AcademyPhase.result:
        return _ResultView(controller: controller);
      case AcademyPhase.map:
        return const SizedBox.shrink();
    }
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.violetSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// Teoría
// ================================================================

class _TheoryView extends StatelessWidget {
  const _TheoryView({required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final content = controller.contentFor(controller.activeLessonId!);
    if (content == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.violetPrimary.withValues(alpha: 0.1),
            border:
                Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded,
                  size: 16, color: AppColors.violetBright),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content.objective,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final block in content.theory) ...[
          _TheoryBlockView(block: block),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        _PrimaryButton(
          label: AppStrings.academyContinue,
          onTap: controller.startExercises,
        ),
      ],
    );
  }
}

class _TheoryBlockView extends StatelessWidget {
  const _TheoryBlockView({required this.block});

  final TheoryBlock block;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (block.kind) {
      TheoryBlockKind.concept => (
          Icons.lightbulb_rounded,
          AppColors.gold,
          'CONCEPTO'
        ),
      TheoryBlockKind.explanation => (
          Icons.subject_rounded,
          AppColors.textSecondary,
          'EXPLICACIÓN'
        ),
      TheoryBlockKind.example => (
          Icons.casino_rounded,
          AppColors.neonGreenBright,
          'EJEMPLO'
        ),
      TheoryBlockKind.keyPoint => (
          Icons.push_pin_rounded,
          AppColors.violetBright,
          'PARA RECORDAR'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// Ejercicio
// ================================================================

class _ExerciseView extends StatelessWidget {
  const _ExerciseView({required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final item = controller.currentItem;
    if (item == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ItemProgress(
          current: controller.itemNumber,
          total: controller.itemTotal,
        ),
        const SizedBox(height: 14),
        if (item.isEngine)
          ExerciseCard(
            exercise: item.exercise!,
            selectedOptionIds: _engineSelection(item),
            selectedReasoningIds: const {},
            onToggleOption: (id) {
              final idx = item.exercise!.options.indexWhere((o) => o.id == id);
              if (idx >= 0) controller.toggleOption(idx);
            },
            onToggleReasoning: (_) {},
            conceptName: controller.conceptName,
          )
        else
          _CheckCard(
            check: item.check!,
            selectedIndex: controller.selectedOptionIdx.isEmpty
                ? null
                : controller.selectedOptionIdx.first,
            onSelect: controller.toggleOption,
          ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: AppStrings.academyConfirm,
          onTap: controller.canConfirm ? controller.confirm : null,
        ),
      ],
    );
  }

  Set<String> _engineSelection(AcademyItem item) {
    if (controller.selectedOptionIdx.isEmpty) return const {};
    final idx = controller.selectedOptionIdx.first;
    final opts = item.exercise!.options;
    if (idx < 0 || idx >= opts.length) return const {};
    return {opts[idx].id};
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.check,
    required this.selectedIndex,
    required this.onSelect,
  });

  final ComprehensionCheck check;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            check.prompt,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < check.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                label: check.options[i],
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppColors.violetPrimary.withValues(alpha: 0.18)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: selected ? AppColors.violetBright : AppColors.surfaceBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: selected ? AppColors.violetBright : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// Feedback de un ítem
// ================================================================

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final fb = controller.lastFeedback;
    if (fb == null) return const SizedBox.shrink();
    final last = controller.itemNumber >= controller.itemTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ItemProgress(
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
        _PrimaryButton(
          label: last
              ? AppStrings.academySeeResult
              : AppStrings.academyNext,
          onTap: controller.nextItem,
        ),
      ],
    );
  }
}

// ================================================================
// Resultado del lesson
// ================================================================

class _ResultView extends StatelessWidget {
  const _ResultView({required this.controller});

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
          _PrimaryButton(
            label: AppStrings.academyStartRecovery,
            onTap: controller.startRecovery,
          ),
        if (!passed && outcome.recovery != null) const SizedBox(height: 10),
        if (!passed)
          _SecondaryButton(
            label: AppStrings.academyRetry,
            onTap: controller.retryLesson,
          ),
        if (passed)
          _PrimaryButton(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
        if (!passed) const SizedBox(height: 10),
        if (!passed)
          _SecondaryButton(
            label: AppStrings.academyBackToMap,
            onTap: controller.exitLesson,
          ),
      ],
    );
  }
}

// ================================================================
// Comunes
// ================================================================

class _ItemProgress extends StatelessWidget {
  const _ItemProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
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
                  FractionallySizedBox(
                    widthFactor: ratio.toDouble(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.violetBright,
                            AppColors.violetPrimary
                          ],
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
          '$current / $total',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: PressableScale(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: AppColors.violetGradient),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

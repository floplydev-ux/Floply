import 'package:flutter/material.dart';

import '../../../engine/pedagogy/lesson_content.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import '../../laboratory/widgets/exercise_card.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart';

/// Fase ejercicio: un ítem del motor (`ExerciseCard`) o una pregunta
/// autoral (`_CheckCard`) + CONFIRMAR.
class ExerciseView extends StatelessWidget {
  const ExerciseView({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final item = controller.currentItem;
    if (item == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonItemProgress(
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
        LessonPrimaryButton(
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

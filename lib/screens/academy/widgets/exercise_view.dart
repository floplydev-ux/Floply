import 'package:flutter/material.dart';

import '../../../engine/pedagogy/lesson_content.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../../laboratory/widgets/exercise_card.dart';
import '../academy_controller.dart';

/// Fase ejercicio: un ítem del motor (`ExerciseCard`) o una pregunta
/// autoral (`_CheckCard`) + CONFIRMAR.
///
/// **Fase 5** (`docs/design/FLOPLY_PHASE_5_ACADEMIA_EXERCISE_FEEDBACK_RESULT.md`):
/// migrado a "Sala Verde" — `ExerciseCard` (de Laboratorio) NO se toca,
/// se mantiene tal cual: es una superficie protegida igual que
/// `PokerTableView`, compartida de verdad con `laboratory_screen.dart`.
/// Solo migra lo que la rodea (progreso, `_CheckCard` local, botón).
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
        SvItemProgress(
          current: controller.itemNumber,
          total: controller.itemTotal,
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
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
        const SizedBox(height: SalaVerdeSpace.lg),
        SvButtonPrimary(
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
    return SvSurfacePanel(
      padding: const EdgeInsets.all(SalaVerdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(check.prompt, style: SalaVerdeType.bodyStrong()),
          const SizedBox(height: SalaVerdeSpace.lg),
          for (var i = 0; i < check.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: SalaVerdeSpace.sm),
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
        duration: SalaVerdeMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: SalaVerdeSpace.lg,
          vertical: SalaVerdeSpace.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          color: selected
              ? SalaVerdeColors.feltGreen.withValues(alpha: 0.18)
              : SalaVerdeColors.surfaceElevated,
          border: Border.all(
            color: selected ? SalaVerdeColors.feltGreenBright : SalaVerdeColors.borderSubtle,
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
              color: selected ? SalaVerdeColors.feltGreenBright : SalaVerdeColors.textMuted,
            ),
            const SizedBox(width: SalaVerdeSpace.md),
            Expanded(
              child: Text(
                label,
                style: selected ? SalaVerdeType.bodyStrong() : SalaVerdeType.body(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

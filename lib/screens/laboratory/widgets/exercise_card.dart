import 'package:flutter/material.dart';

import '../../../engine/exercises/exercise.dart';
import '../../../engine/exercises/poker_situation.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import 'poker_bits.dart';

/// La tarjeta con el enunciado del ejercicio, la situación y las opciones.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.selectedOptionIds,
    required this.selectedReasoningIds,
    required this.onToggleOption,
    required this.onToggleReasoning,
    required this.conceptName,
  });

  final Exercise exercise;
  final Set<String> selectedOptionIds;
  final Set<String> selectedReasoningIds;
  final ValueChanged<String> onToggleOption;
  final ValueChanged<String> onToggleReasoning;
  final String Function(String conceptId) conceptName;

  @override
  Widget build(BuildContext context) {
    final situation = exercise.situation;
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
          Row(
            children: [
              _DifficultyDots(difficulty: exercise.difficulty),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.type.label.toUpperCase(),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neonGreenBright,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.prompt,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (situation != null) ...[
            const SizedBox(height: 16),
            _SituationView(situation: situation),
          ],
          const SizedBox(height: 18),
          ...exercise.options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionTile(
                  label: option.label,
                  selected: selectedOptionIds.contains(option.id),
                  onTap: () => onToggleOption(option.id),
                ),
              )),
          if (exercise.reasoningConcepts.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              AppStrings.labYourReasoning,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.reasoningConcepts
                  .map((id) => _ReasoningChip(
                        label: conceptName(id),
                        selected: selectedReasoningIds.contains(id),
                        onTap: () => onToggleReasoning(id),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SituationView extends StatelessWidget {
  const _SituationView({required this.situation});

  final PokerSituation situation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroHandView(hand: situation.heroCards),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                label: 'POS',
                value: situation.heroPosition.abbreviation,
              ),
              InfoChip(
                label: 'STACK',
                value: '${situation.effectiveStackBb.toStringAsFixed(0)}bb',
              ),
              InfoChip(label: 'CALLE', value: situation.street.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            situation.actionHistoryDescription,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
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
              ? AppColors.neonGreen.withValues(alpha: 0.16)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: selected
                ? AppColors.neonGreenBright
                : AppColors.surfaceBorder,
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
              color: selected
                  ? AppColors.neonGreenBright
                  : AppColors.textMuted,
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

class _ReasoningChip extends StatelessWidget {
  const _ReasoningChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppColors.violetPrimary.withValues(alpha: 0.22)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: selected ? AppColors.violetBright : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.violetSoft : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= difficulty
                    ? AppColors.neonGreen
                    : AppColors.surfaceBorder,
              ),
            ),
          ),
      ],
    );
  }
}

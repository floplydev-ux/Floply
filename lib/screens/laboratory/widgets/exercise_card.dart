import 'package:flutter/material.dart';

import '../../../engine/exercises/exercise.dart';
import '../../../engine/exercises/poker_situation.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import 'poker_bits.dart';

/// La tarjeta con el enunciado del ejercicio, la situación y las opciones.
///
/// **Fase 7** (`docs/design/FLOPLY_PHASE_7_LABORATORIO.md`): migrado a
/// "Sala Verde" — compartido con `exercise_view.dart` de Academia (Fase
/// 5, camino `.engine`, sin contenido real hoy pero sí alcanzable acá en
/// Laboratorio vía el motor clásico). Migrar acá cierra también la
/// costura que la Fase 5 había documentado como límite conocido.
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
    return SvSurfacePanel(
      padding: const EdgeInsets.all(SalaVerdeSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _DifficultyDots(difficulty: exercise.difficulty),
              const SizedBox(width: SalaVerdeSpace.sm),
              Expanded(
                child: Text(
                  exercise.type.label.toUpperCase(),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalaVerdeType.label(color: SalaVerdeColors.steelBlueBright),
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(exercise.prompt, style: SalaVerdeType.bodyStrong()),
          if (situation != null) ...[
            const SizedBox(height: SalaVerdeSpace.lg),
            _SituationView(situation: situation),
          ],
          const SizedBox(height: SalaVerdeSpace.xl - 2),
          ...exercise.options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: SalaVerdeSpace.sm),
                child: _OptionTile(
                  label: option.label,
                  selected: selectedOptionIds.contains(option.id),
                  onTap: () => onToggleOption(option.id),
                ),
              )),
          if (exercise.reasoningConcepts.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.xs),
            Text(
              AppStrings.labYourReasoning,
              style: SalaVerdeType.label(color: SalaVerdeColors.textMuted),
            ),
            const SizedBox(height: SalaVerdeSpace.sm),
            Wrap(
              spacing: SalaVerdeSpace.sm,
              runSpacing: SalaVerdeSpace.sm,
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
      padding: const EdgeInsets.all(SalaVerdeSpace.md),
      decoration: BoxDecoration(
        color: SalaVerdeColors.background,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroHandView(hand: situation.heroCards),
          const SizedBox(height: SalaVerdeSpace.md),
          SvChipNumericGroup(chips: [
            SvChipNumeric(
              label: 'POS',
              value: situation.heroPosition.abbreviation,
              accent: SalaVerdeColors.steelBlueBright,
            ),
            SvChipNumeric(
              label: 'STACK',
              value: '${situation.effectiveStackBb.toStringAsFixed(0)}bb',
              accent: SalaVerdeColors.steelBlueBright,
            ),
            SvChipNumeric(
              label: 'CALLE',
              value: situation.street.label,
              accent: SalaVerdeColors.steelBlueBright,
            ),
          ]),
          const SizedBox(height: SalaVerdeSpace.sm),
          Text(
            situation.actionHistoryDescription,
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
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
              ? SalaVerdeColors.steelBlueBright.withValues(alpha: 0.16)
              : SalaVerdeColors.surfaceElevated,
          border: Border.all(
            color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.borderSubtle,
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
              color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.textMuted,
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
        padding: const EdgeInsets.symmetric(
          horizontal: SalaVerdeSpace.md,
          vertical: SalaVerdeSpace.xs + 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
          color: selected
              ? SalaVerdeColors.steelBlueBright.withValues(alpha: 0.18)
              : SalaVerdeColors.surfaceElevated,
          border: Border.all(
            color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: SalaVerdeType.bodyStrong(
            color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.textSecondary,
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
                    ? SalaVerdeColors.steelBlueBright
                    : SalaVerdeColors.borderSubtle,
              ),
            ),
          ),
      ],
    );
  }
}

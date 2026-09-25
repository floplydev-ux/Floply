import 'package:flutter/material.dart';

import '../../../engine/evaluation/evaluation_result.dart';
import '../../../engine/strategy/strategy.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Muestra el resultado de la evaluación: valoración, feedback progresivo
/// y el desglose de la estrategia (todas las acciones con su frecuencia).
///
/// **Fase 7**: migrado a "Sala Verde". [_accent] agrupa las 5
/// [StrategicRating] en 3 bandas semánticas (`success`/`warning`/
/// `errorBright`) — no hay 5 tokens semánticos distintos en el sistema, y
/// las etiquetas/emojis (sin tocar) siguen comunicando las 5 categorías
/// reales; el color solo comunica la banda general.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.result,
    required this.strategy,
    required this.showAdvanced,
    required this.onToggleAdvanced,
    required this.conceptName,
  });

  final EvaluationResult result;
  final Strategy strategy;
  final bool showAdvanced;
  final VoidCallback onToggleAdvanced;
  final String Function(String conceptId) conceptName;

  Color get _accent {
    switch (result.strategicRating) {
      case StrategicRating.optimal:
      case StrategicRating.veryGood:
        return SalaVerdeColors.success;
      case StrategicRating.viable:
        return SalaVerdeColors.warning;
      case StrategicRating.dubious:
        return SalaVerdeColors.warning;
      case StrategicRating.bad:
        return SalaVerdeColors.errorBright;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return SvSurfacePanel(
      borderColor: accent.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(SalaVerdeSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: SalaVerdeSpace.sm,
            runSpacing: SalaVerdeSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.strategicRating.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: SalaVerdeSpace.sm),
                  Text(
                    result.strategicRating.label.toUpperCase(),
                    style: SalaVerdeType.label(color: accent),
                  ),
                ],
              ),
              _ScorePill(label: AppStrings.labDecision, value: result.decisionScore),
              if (result.reasoningScore != null)
                _ScorePill(label: AppStrings.labReasoning, value: result.reasoningScore!),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(result.feedback, style: SalaVerdeType.body()),
          const SizedBox(height: SalaVerdeSpace.md + 2),
          _StrategyBreakdown(strategy: strategy, chosen: result.chosenOption),
          if (result.missingConcepts.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.md),
            _ConceptLine(
              label: 'Te faltó considerar',
              concepts: result.missingConcepts.map(conceptName).toList(),
              color: SalaVerdeColors.warning,
            ),
          ],
          if (result.matchedConcepts.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.sm),
            _ConceptLine(
              label: 'Bien identificado',
              concepts: result.matchedConcepts.map(conceptName).toList(),
              color: SalaVerdeColors.success,
            ),
          ],
          if (result.advancedFeedback != null) ...[
            const SizedBox(height: SalaVerdeSpace.md + 2),
            GestureDetector(
              onTap: onToggleAdvanced,
              child: Row(
                children: [
                  Icon(
                    showAdvanced
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: SalaVerdeColors.steelBlueBright,
                  ),
                  const SizedBox(width: SalaVerdeSpace.xs),
                  Text(
                    AppStrings.labShowAdvanced,
                    style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.steelBlueBright),
                  ),
                ],
              ),
            ),
            if (showAdvanced) ...[
              const SizedBox(height: SalaVerdeSpace.sm),
              Container(
                padding: const EdgeInsets.all(SalaVerdeSpace.md),
                decoration: BoxDecoration(
                  color: SalaVerdeColors.steelBlueBright.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                ),
                child: Text(
                  result.advancedFeedback!,
                  style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StrategyBreakdown extends StatelessWidget {
  const _StrategyBreakdown({required this.strategy, required this.chosen});

  final Strategy strategy;
  final StrategyOption? chosen;

  @override
  Widget build(BuildContext context) {
    final options = [...strategy.options]
      ..sort((a, b) => b.frequency.compareTo(a.frequency));
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: SalaVerdeSpace.xs + 2),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(option.rating.emoji, style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: Text(
                    option.action.label,
                    style: chosen?.action == option.action
                        ? SalaVerdeType.bodyStrong()
                        : SalaVerdeType.body(),
                  ),
                ),
                Text(
                  '${(option.frequency * 100).round()}%',
                  style: SalaVerdeType.numeric(size: 12.5, color: SalaVerdeColors.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SalaVerdeSpace.sm, vertical: SalaVerdeSpace.xs),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.sharp + 6),
      ),
      child: Text(
        '$label ${(value * 100).round()}',
        style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary),
      ),
    );
  }
}

class _ConceptLine extends StatelessWidget {
  const _ConceptLine({
    required this.label,
    required this.concepts,
    required this.color,
  });

  final String label;
  final List<String> concepts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: SalaVerdeType.label(color: color).copyWith(fontSize: 11.5)),
        Expanded(
          child: Text(
            concepts.join(', '),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

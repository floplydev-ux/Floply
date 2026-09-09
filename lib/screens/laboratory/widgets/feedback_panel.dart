import 'package:flutter/material.dart';

import '../../../engine/evaluation/evaluation_result.dart';
import '../../../engine/strategy/strategy.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';

/// Muestra el resultado de la evaluación: valoración, feedback progresivo
/// y el desglose de la estrategia (todas las acciones con su frecuencia).
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
        return AppColors.neonGreen;
      case StrategicRating.viable:
        return AppColors.gold;
      case StrategicRating.dubious:
        return AppColors.warning;
      case StrategicRating.bad:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        border: Border.all(color: _accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.strategicRating.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.strategicRating.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: _accent,
                    ),
                  ),
                ],
              ),
              _ScorePill(
                label: AppStrings.labDecision,
                value: result.decisionScore,
              ),
              if (result.reasoningScore != null)
                _ScorePill(
                  label: AppStrings.labReasoning,
                  value: result.reasoningScore!,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.feedback,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _StrategyBreakdown(strategy: strategy, chosen: result.chosenOption),
          if (result.missingConcepts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ConceptLine(
              label: 'Te faltó considerar',
              concepts: result.missingConcepts.map(conceptName).toList(),
              color: AppColors.warning,
            ),
          ],
          if (result.matchedConcepts.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ConceptLine(
              label: 'Bien identificado',
              concepts: result.matchedConcepts.map(conceptName).toList(),
              color: AppColors.neonGreen,
            ),
          ],
          if (result.advancedFeedback != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onToggleAdvanced,
              child: Row(
                children: [
                  Icon(
                    showAdvanced
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.violetSoft,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    AppStrings.labShowAdvanced,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.violetSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (showAdvanced) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.violetPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.advancedFeedback!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.violetSoft,
                  ),
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
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(option.rating.emoji,
                      style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: Text(
                    option.action.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: chosen?.action == option.action
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${(option.frequency * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${(value * 100).round()}',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
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
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            concepts.join(', '),
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

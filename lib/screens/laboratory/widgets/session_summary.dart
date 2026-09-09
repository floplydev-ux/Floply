import 'package:flutter/material.dart';

import '../../../engine/concepts/mastery_bucket.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import '../lab_session_controller.dart';

/// Pantalla de cierre de sesión: promedios de decisión y razonamiento,
/// dominio por concepto y sugerencia de recuperación.
class SessionSummary extends StatelessWidget {
  const SessionSummary({
    super.key,
    required this.controller,
    required this.onRestart,
  });

  final LabSessionController controller;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final decision = controller.sessionDecisionScore;
    final reasoning = controller.sessionReasoningScore;
    final recovery = controller.recovery;
    final buckets = masteryBuckets(
      controller.knowledge,
      controller.engine.generator.practiceableConcepts,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.labSessionSummary,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.neonGreenBright,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  label: AppStrings.labDecision,
                  value: '${(decision * 100).round()}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStat(
                  label: AppStrings.labReasoning,
                  value: reasoning == null
                      ? '—'
                      : '${(reasoning * 100).round()}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStat(
                  label: 'Ejercicios',
                  value: '${controller.results.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'DOMINIO POR CONCEPTO',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          for (final bucket in buckets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ConceptBar(bucket: bucket),
            ),
          if (recovery != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recovery.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          PressableScale(
            onTap: onRestart,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [AppColors.neonGreenBright, AppColors.neonGreen],
                ),
              ),
              child: const Text(
                AppStrings.labAgain,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.6,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptBar extends StatelessWidget {
  const _ConceptBar({required this.bucket});

  final MasteryBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bucket.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${(bucket.mastery * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(color: AppColors.surfaceElevated),
                FractionallySizedBox(
                  widthFactor: bucket.mastery.clamp(0.0, 1.0),
                  child: Container(
                    color: bucket.mastery >= 0.8
                        ? AppColors.neonGreen
                        : bucket.mastery >= 0.5
                            ? AppColors.gold
                            : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

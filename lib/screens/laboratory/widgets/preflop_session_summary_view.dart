import 'package:flutter/material.dart';

import '../../../engine/exercises/answer_evaluator.dart';
import '../../../engine/exercises/exercise_scenario.dart';
import '../../../engine/exercises/preflop_session_summary.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../lab_session_controller.dart';

/// Pantalla de cierre de sesión del motor nuevo (Fase 9) — reemplaza a
/// `SessionSummary` (widget viejo) únicamente para
/// `controller.isNewEngineSession == true`; ese sigue existiendo tal
/// cual para el camino viejo.
///
/// Fuente de verdad única: `controller.newEngineSummary`
/// (`PreflopSessionSummary`, Fase 8.5/9.2). No recalcula scores ni
/// escribe en `UserKnowledge` — puramente lector (Fase 9.11).
///
/// **Fase 7**: migrado a "Sala Verde" — es la pantalla de resultado que
/// ve la mayoría de los usuarios reales (el punto de entrada normal,
/// Fácil/Medio/Experto, siempre arranca el motor nuevo). `AnswerVerdict`
/// (best/acceptable/dependent/poor) usa el mismo criterio de color que
/// `ExerciseRating` en Academia (Fases 5/6): `feltGreenBright` no aplica
/// acá (Laboratorio es `steelBlueBright`), así que best/acceptable usan
/// `success`/`warning` semánticos, dependent usa `steelBlueBright`
/// (Laboratorio no tiene un color "neutral pero real" mejor que su
/// propia identidad para "depende del contexto"), poor usa `errorBright`.
class PreflopSessionSummaryView extends StatelessWidget {
  const PreflopSessionSummaryView({
    super.key,
    required this.controller,
    required this.onKeepPracticing,
    required this.onBackToLab,
  });

  final LabSessionController controller;
  final VoidCallback onKeepPracticing;
  final VoidCallback onBackToLab;

  @override
  Widget build(BuildContext context) {
    final summary = controller.newEngineSummary;
    final recent = controller.newEngineResults;

    return SvSurfacePanel(
      padding: const EdgeInsets.all(SalaVerdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.labSessionSummary,
            style: SalaVerdeType.label(color: SalaVerdeColors.steelBlueBright),
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          Row(
            children: [
              Expanded(
                child: _BigStat(label: 'Ejercicios', value: '${summary.exercisesDone}'),
              ),
              const SizedBox(width: SalaVerdeSpace.md),
              Expanded(
                child: _BigStat(
                  label: 'Calidad',
                  value: summary.exercisesDone == 0
                      ? '—'
                      : '${(summary.averageQuality * 100).round()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            _descriptiveLine(summary),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          const SizedBox(height: SalaVerdeSpace.xl - 4),
          const _SectionHeader(AppStrings.labQualityHeader),
          const SizedBox(height: SalaVerdeSpace.sm + 2),
          _VerdictRow(label: 'BEST', count: summary.bestCount, color: SalaVerdeColors.success),
          _VerdictRow(
              label: 'ACCEPTABLE', count: summary.acceptableCount, color: SalaVerdeColors.warning),
          _VerdictRow(
              label: 'DEPENDENT',
              count: summary.dependentCount,
              color: SalaVerdeColors.steelBlueBright),
          _VerdictRow(label: 'POOR', count: summary.poorCount, color: SalaVerdeColors.errorBright),
          if (summary.conceptsWorked.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.xl - 4),
            const _SectionHeader(AppStrings.labPracticedHeader),
            const SizedBox(height: SalaVerdeSpace.sm + 2),
            _ConceptChips(
              conceptIds: summary.conceptsWorked,
              conceptName: controller.conceptName,
              color: SalaVerdeColors.steelBlueBright,
            ),
          ],
          if (summary.conceptsWithWeakPerformance.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.xl - 4),
            const _SectionHeader(AppStrings.labToImproveHeader),
            const SizedBox(height: SalaVerdeSpace.sm + 2),
            _ConceptChips(
              conceptIds: summary.conceptsWithWeakPerformance,
              conceptName: controller.conceptName,
              color: SalaVerdeColors.warning,
            ),
          ],
          if (recent.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.xl - 4),
            const _SectionHeader(AppStrings.labRecentDecisionsHeader),
            const SizedBox(height: SalaVerdeSpace.sm + 2),
            for (final entry in recent.reversed.take(5).toList().reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: SalaVerdeSpace.sm),
                child: _RecentDecisionRow(kind: entry.$1, result: entry.$2),
              ),
          ],
          const SizedBox(height: SalaVerdeSpace.lg + 2),
          SvButtonPrimary(label: AppStrings.labKeepPracticing, onTap: onKeepPracticing),
          const SizedBox(height: SalaVerdeSpace.sm + 2),
          SvButtonSecondary(label: AppStrings.labBackToLab, onTap: onBackToLab),
        ],
      ),
    );
  }

  /// Interpretación descriptiva directamente derivable de los conteos —
  /// sin conclusiones que los datos no respaldan (Fase 9.6): nada de
  /// "nivel"/"dominás el póker".
  String _descriptiveLine(PreflopSessionSummary summary) {
    if (summary.exercisesDone == 0) return 'Todavía no resolviste ningún ejercicio.';
    final parts = <String>['${summary.exercisesDone} decisiones tomadas.'];
    void addIfAny(int count, String label) {
      if (count > 0) parts.add('$count $label.');
    }

    addIfAny(summary.bestCount, 'fueron Best');
    addIfAny(summary.acceptableCount, 'fueron Acceptable');
    addIfAny(summary.dependentCount, 'fueron Dependent');
    addIfAny(summary.poorCount, 'fueron Poor');
    return parts.join(' ');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: SalaVerdeType.label(color: SalaVerdeColors.textMuted));
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: SalaVerdeSpace.md + 2),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
      ),
      child: Column(
        children: [
          Text(value, style: SalaVerdeType.numeric(size: 22, color: SalaVerdeColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: SalaVerdeType.label(color: SalaVerdeColors.textMuted)),
        ],
      ),
    );
  }
}

class _VerdictRow extends StatelessWidget {
  const _VerdictRow({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SalaVerdeSpace.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: SalaVerdeSpace.sm + 2),
          Expanded(child: Text(label, style: SalaVerdeType.bodyStrong())),
          Text(
            '$count',
            style: SalaVerdeType.numeric(size: 13, color: color),
          ),
        ],
      ),
    );
  }
}

class _ConceptChips extends StatelessWidget {
  const _ConceptChips({
    required this.conceptIds,
    required this.conceptName,
    required this.color,
  });

  final Set<String> conceptIds;
  final String Function(String) conceptName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SalaVerdeSpace.sm,
      runSpacing: SalaVerdeSpace.sm,
      children: [
        for (final id in conceptIds)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SalaVerdeSpace.sm + 2,
              vertical: SalaVerdeSpace.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              conceptName(id),
              style: SalaVerdeType.bodyStrong(color: color).copyWith(fontSize: 11.5),
            ),
          ),
      ],
    );
  }
}

class _RecentDecisionRow extends StatelessWidget {
  const _RecentDecisionRow({required this.kind, required this.result});

  final PreflopScenarioKind kind;
  final AnswerResult result;

  Color get _verdictColor => switch (result.verdict) {
        AnswerVerdict.best => SalaVerdeColors.success,
        AnswerVerdict.acceptable => SalaVerdeColors.warning,
        AnswerVerdict.dependent => SalaVerdeColors.steelBlueBright,
        AnswerVerdict.poor => SalaVerdeColors.errorBright,
      };

  String get _verdictLabel => switch (result.verdict) {
        AnswerVerdict.best => 'BEST',
        AnswerVerdict.acceptable => 'ACCEPTABLE',
        AnswerVerdict.dependent => 'DEPENDENT',
        AnswerVerdict.poor => 'POOR',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SalaVerdeSpace.md, vertical: SalaVerdeSpace.sm + 2),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.label, style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)),
                const SizedBox(height: 2),
                Text(result.chosenAction.label, style: SalaVerdeType.bodyStrong()),
              ],
            ),
          ),
          Text(
            _verdictLabel,
            style: SalaVerdeType.label(color: _verdictColor),
          ),
        ],
      ),
    );
  }
}

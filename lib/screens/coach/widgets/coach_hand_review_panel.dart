import 'package:flutter/material.dart';

import '../../../engine/coach/coach_analyzer.dart';
import '../../../engine/strategy/decision_math.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// El panel de "Repasemos la mano" — reemplaza al viejo comentario del
/// Coach después de cada decisión (evolución de la Mesa Coach, secciones
/// 1/2/3): aparece una sola vez, cuando la mano YA terminó, con el
/// análisis completo de [HandReview] en tono de mentor — nunca una
/// puntuación fría, nunca un popup bloqueante a mitad de la mano.
class CoachHandReviewPanel extends StatelessWidget {
  const CoachHandReviewPanel({
    super.key,
    required this.heroWon,
    required this.winnerNames,
    required this.review,
    required this.onNewHand,
  });

  final bool heroWon;
  final List<String> winnerNames;
  final HandReview review;
  final VoidCallback onNewHand;

  @override
  Widget build(BuildContext context) {
    final summary = winnerNames.length <= 1
        ? '${winnerNames.isEmpty ? "Nadie" : winnerNames.first} se llevó la mano.'
        : '${winnerNames.join(" y ")} dividieron el bote.';

    return SvSurfacePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            heroWon ? AppStrings.coachHandOverWon : AppStrings.coachHandOverLost,
            textAlign: TextAlign.center,
            style: SalaVerdeType.title(),
          ),
          const SizedBox(height: SalaVerdeSpace.xs),
          Text(summary, textAlign: TextAlign.center, style: SalaVerdeType.body()),
          if (review.decisions.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.md),
            Text(
              AppStrings.coachReviewTitle,
              style: SalaVerdeType.label(color: SalaVerdeColors.brassBright),
            ),
            const SizedBox(height: SalaVerdeSpace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: review.decisions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: SalaVerdeSpace.sm),
                itemBuilder: (context, i) =>
                    _DecisionCard(review: review.decisions[i]),
              ),
            ),
          ],
          const SizedBox(height: SalaVerdeSpace.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SalaVerdeSpace.md),
            decoration: BoxDecoration(
              color: SalaVerdeColors.surfaceElevated,
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              border: Border.all(color: SalaVerdeColors.brassBright.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.coachClosingLabel,
                  style: SalaVerdeType.label(color: SalaVerdeColors.brassBright),
                ),
                const SizedBox(height: SalaVerdeSpace.xs),
                Text(review.closingThought, style: SalaVerdeType.body()),
              ],
            ),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          SvButtonPrimary(label: AppStrings.coachNewHand, onTap: onNewHand),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.review});

  final HandDecisionReview review;

  (String, Color) get _qualityMeta => switch (review.quality) {
        DecisionQuality.solid => ('BIEN AHÍ', SalaVerdeColors.feltGreenBright),
        DecisionQuality.improvable => ('CON UN MATIZ', SalaVerdeColors.brassBright),
        DecisionQuality.contextDependent => (
            'DEPENDE DEL SPOT',
            SalaVerdeColors.textSecondary,
          ),
        DecisionQuality.questionable => ('PARA PENSAR', SalaVerdeColors.brassBright),
        DecisionQuality.costly => ('EL PUNTO FLOJO', SalaVerdeColors.errorBright),
      };

  @override
  Widget build(BuildContext context) {
    final (tag, color) = _qualityMeta;
    return Container(
      padding: const EdgeInsets.all(SalaVerdeSpace.md),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        border: Border.all(color: SalaVerdeColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                review.street.label.toUpperCase(),
                style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary),
              ),
              const SizedBox(width: SalaVerdeSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.xs),
          Text(review.comment, style: SalaVerdeType.body()),
          if (review.math != null && review.math!.hasAny) ...[
            const SizedBox(height: SalaVerdeSpace.sm),
            _DecisionNumbers(review.math!),
          ],
        ],
      ),
    );
  }
}

/// Los números reales que ya usó [CoachAnalyzer] para calificar esta
/// decisión (equity aproximada, pot odds, bote, lo que había que pagar) —
/// nunca inventados: el mismo [DecisionMath] que ya arma el análisis,
/// mostrado en vez de descartado. Mismo criterio visual que la sección
/// "NÚMEROS" del Campo de Entrenamiento (chips chicos), adaptado al tono
/// de Coach.
class _DecisionNumbers extends StatelessWidget {
  const _DecisionNumbers(this.math);

  final DecisionMath math;

  static String _pct(double v) => '${v.toStringAsFixed(0)}%';
  static String _bb(double v) =>
      '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} BB';

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      if (math.equityPct != null) ('Equity', _pct(math.equityPct!)),
      if (math.requiredEquityPct != null)
        ('Equity necesaria', _pct(math.requiredEquityPct!)),
      if (math.potBb != null) ('Bote', _bb(math.potBb!)),
      if (math.toCallBb != null) ('Pagás', _bb(math.toCallBb!)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final (label, value) in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: SalaVerdeColors.surface,
              borderRadius: BorderRadius.circular(SalaVerdeRadius.sharp),
              border: Border.all(color: SalaVerdeColors.borderSubtle),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary)
                        .copyWith(fontSize: 10),
                  ),
                  TextSpan(
                    text: value,
                    style: SalaVerdeType.numeric(size: 12, color: SalaVerdeColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

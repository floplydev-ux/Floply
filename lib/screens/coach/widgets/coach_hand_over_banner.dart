import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Lo primero que se ve cuando la mano termina: discreto, nunca
/// bloqueante (evolución de la Mesa Coach, sección 3 — "el análisis
/// nunca debe obligar al usuario a leerlo"). El usuario elige entre dos
/// ritmos, sin que ninguno esté impuesto por sobre el otro:
///
/// * [onViewAnalysis] — abre el análisis del Coach ([CoachHandReviewPanel]).
/// * [onContinue] — arranca la siguiente mano de una, sin pasar por ahí.
class CoachHandOverBanner extends StatelessWidget {
  const CoachHandOverBanner({
    super.key,
    required this.heroWon,
    required this.winnerNames,
    required this.onViewAnalysis,
    required this.onContinue,
  });

  final bool heroWon;
  final List<String> winnerNames;
  final VoidCallback onViewAnalysis;
  final VoidCallback onContinue;

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
          const SizedBox(height: SalaVerdeSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_stories_rounded,
                  size: 15, color: SalaVerdeColors.brassBright),
              const SizedBox(width: 6),
              Text(
                AppStrings.coachAnalysisAvailable,
                style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Row(
            children: [
              Expanded(
                child: SvButtonSecondary(
                  label: AppStrings.coachContinuePlaying,
                  onTap: onContinue,
                ),
              ),
              const SizedBox(width: SalaVerdeSpace.sm),
              Expanded(
                child: SvButtonPrimary(
                  label: AppStrings.coachViewAnalysis,
                  onTap: onViewAnalysis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

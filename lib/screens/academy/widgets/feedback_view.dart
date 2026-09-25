import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../../laboratory/widgets/feedback_panel.dart';
import '../academy_controller.dart';

/// Fase feedback de un ítem: `FeedbackPanel` del motor o una tarjeta
/// simple con el texto, + SIGUIENTE / VER RESULTADO.
///
/// **Fase 5** (`docs/design/FLOPLY_PHASE_5_ACADEMIA_EXERCISE_FEEDBACK_RESULT.md`):
/// migrado a "Sala Verde" — `FeedbackPanel` (de Laboratorio) NO se toca,
/// superficie protegida igual que `PokerTableView`/`ExerciseCard`. El
/// camino de texto autoral usa `_CheckFeedbackPanel`, un componente LOCAL
/// nuevo (no `EducationalPanel`, compartido con `table_explanation_view.dart`
/// — que a su vez alimenta la mesa de `PlayableTableExerciseView` e
/// `InteractiveTableExerciseView`, fuera de alcance).
class FeedbackView extends StatelessWidget {
  const FeedbackView({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final fb = controller.lastFeedback;
    if (fb == null) return const SizedBox.shrink();
    final last = controller.itemNumber >= controller.itemTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SvItemProgress(
          current: controller.itemNumber,
          total: controller.itemTotal,
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        if (fb.evaluation != null && fb.exercise != null)
          FeedbackPanel(
            result: fb.evaluation!,
            strategy: fb.exercise!.strategy,
            showAdvanced: false,
            onToggleAdvanced: () {},
            conceptName: controller.conceptName,
          )
        else
          _CheckFeedbackPanel(text: fb.text, correct: fb.correct),
        const SizedBox(height: SalaVerdeSpace.lg),
        SvButtonPrimary(
          label: last ? AppStrings.academySeeResult : AppStrings.academyNext,
          onTap: controller.nextItem,
        ),
      ],
    );
  }
}

/// Devolución de una pregunta autoral (`ComprehensionCheck`): correcto/
/// incorrecto es un dato real y binario acá (no la escala de 4 valores de
/// `ExerciseRating`), así que un acento verde/rojo es la lectura correcta
/// — distinto del caso que la Sección 25 de la fase advierte (no reducir
/// best/acceptable/poor/dependent a solo 2 colores).
class _CheckFeedbackPanel extends StatelessWidget {
  const _CheckFeedbackPanel({required this.text, required this.correct});

  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final accent = correct ? SalaVerdeColors.success : SalaVerdeColors.errorBright;
    return SvSurfacePanel(
      borderColor: accent.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(SalaVerdeSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_rounded : Icons.close_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: SalaVerdeSpace.sm),
              Text(
                correct ? 'BIEN' : 'REVISÁ ESTO',
                style: SalaVerdeType.label(color: accent),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          Text(text, style: SalaVerdeType.body()),
        ],
      ),
    );
  }
}

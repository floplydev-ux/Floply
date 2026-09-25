import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy_controller.dart';
import 'table_explanation_view.dart';

/// La lección interactiva: una mano de póker que se desarrolla mientras el
/// "profesor" explica. Cada paso muestra la mesa y su explicación —siempre
/// en el panel educativo debajo de la mesa, nunca en una burbuja flotante—
/// y el usuario avanza con CONTINUAR / ATRÁS.
///
/// Sirve para DOS guiones distintos del mismo `AcademyController`, elegidos
/// por qué constructor se use — mismo widget, misma mesa, mismos controles,
/// solo cambia de dónde lee el paso actual:
///  - constructor por defecto: el guion legado ([AcademyController.
///    tableScript]), que se muestra ANTES de las teorías de un subnivel.
///  - [InteractiveTableLesson.closingExample]: el ejemplo de cierre del
///    piloto de 3 bloques ([AcademyController.closingExampleScript]), que
///    se muestra DESPUÉS de la teoría escrita y ANTES de los ejercicios
///    (por ahora, solo el subnivel 1.1 lo tiene).
///
/// **Fase 6** (`docs/design/FLOPLY_PHASE_6_INTERACTIVE_TABLE.md`): migrado
/// a "Sala Verde". `TableExplanationView`/`PokerTableView` NO se tocan
/// (superficies protegidas, compartidas con `InteractiveTableExerciseView`
/// y `PlayableTableExerciseView`) — el acento `feltGreen` se les pasa
/// como parámetro, igual que ya hacía `PlayableTableExerciseView` desde
/// la Fase 5.
class InteractiveTableLesson extends StatelessWidget {
  const InteractiveTableLesson({super.key, required this.controller})
      : _closingExample = false;

  const InteractiveTableLesson.closingExample({super.key, required this.controller})
      : _closingExample = true;

  final AcademyController controller;
  final bool _closingExample;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final step = _closingExample ? c.currentClosingExampleStep : c.currentTableStep;
    if (step == null) return const SizedBox.shrink();

    final total = _closingExample ? c.closingExampleStepCount : c.tableStepCount;
    final current = (_closingExample ? c.closingExampleStep : c.tableStep) + 1;
    final table = c.castTable(step.table);
    final bubbleText = c.resolveText(step.bubble, table);

    final String buttonLabel;
    final bool canGoBack;
    final VoidCallback onBack;
    final VoidCallback onNext;
    if (_closingExample) {
      buttonLabel = c.closingExampleButtonLabel;
      canGoBack = !c.isFirstClosingExampleStep;
      onBack = c.prevClosingExampleStep;
      onNext = c.nextClosingExampleStep;
    } else {
      buttonLabel = (c.isLastTableStep && !c.hasWrittenTheory)
          // Si después del guion vienen fichas de teoría redactada, el
          // último paso todavía es "CONTINUAR": la práctica llega más tarde.
          ? AppStrings.academyStartPractice
          : AppStrings.academyContinue;
      canGoBack = !c.isFirstTableStep;
      onBack = c.prevTableStep;
      onNext = c.nextTableStep;
    }

    return Column(
      children: [
        _StepDots(total: total, current: current - 1),
        const SizedBox(height: SalaVerdeSpace.sm),
        Expanded(
          child: TableExplanationView(
            table: table,
            text: bubbleText,
            anchor: step.anchor,
            highlight: step.effectiveHighlight,
            dimOthers: step.dimOthers,
            cardGlow: step.cardGlow,
            stepNumber: current,
            transitionTag: '${_closingExample ? 'closing' : 'lesson'}${current - 1}',
            panelIcon: Icons.school_rounded,
            accent: SalaVerdeColors.feltGreen,
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        SvLessonNavControls(
          canGoBack: canGoBack,
          buttonLabel: buttonLabel,
          counter: '$current / $total',
          onBack: onBack,
          onNext: onNext,
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0)
            Container(
              width: 12,
              height: 1.5,
              color: i <= current
                  ? SalaVerdeColors.feltGreen
                  : SalaVerdeColors.borderSubtle,
            ),
          AnimatedContainer(
            duration: SalaVerdeMotion.normal,
            width: i == current ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i <= current
                  ? SalaVerdeColors.feltGreenBright
                  : SalaVerdeColors.surfaceElevated,
            ),
          ),
        ],
      ],
    );
  }
}

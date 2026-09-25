import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart';
import 'table_bubble.dart';
import 'table_explanation_view.dart';

/// **Piloto visual**: una teoría contada como una secuencia de situaciones
/// sobre la mesa, con una burbuja corta que señala qué mirar en cada paso.
///
/// Sub-fase de [AcademyPhase.theory] (ver `AcademyController.isVisualTheory`):
/// viene después del guion heredado (si lo hay) y antes de la ficha de
/// teoría escrita de esa misma teoría. Es deliberadamente distinta de
/// [TableExplanationView] (guion interactivo / ejercicios): ahí el texto vive
/// siempre en el panel, nunca flota sobre la mesa — acá, en cambio, la
/// burbuja flotante *es* la experiencia que se está probando.
///
/// No repite la teoría escrita: sus textos son una frase (burbuja) y, como
/// mucho, una oración más (`caption`). La explicación completa la da la
/// ficha de teoría que se muestra justo después.
class VisualTheoryStageView extends StatefulWidget {
  const VisualTheoryStageView({super.key, required this.controller});

  final AcademyController controller;

  @override
  State<VisualTheoryStageView> createState() => _VisualTheoryStageViewState();
}

class _VisualTheoryStageViewState extends State<VisualTheoryStageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  int _lastStep = -1;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final step = c.currentVisualStep;
    if (step == null) return const SizedBox.shrink();

    if (c.visualStep != _lastStep) {
      _lastStep = c.visualStep;
      _focus.forward(from: 0);
    }

    final total = c.visualStepCount;
    final current = c.visualStep + 1;
    final table = c.castTable(step.table);
    final bubbleText = c.resolveText(step.bubble, table);
    final captionText =
        step.caption == null ? null : c.resolveText(step.caption!, table);
    final theoryTitle = c.currentWrittenTheory?.titulo;

    return LayoutBuilder(builder: (context, constraints) {
      // Mismo criterio de reparto que el guion interactivo: la mesa toma
      // una fracción estable del alto de PANTALLA (no del hueco disponible,
      // para no "saltar" entre pasos), pero cede antes que aplastar la
      // burbuja/caption/controles si el hueco es corto.
      final screen = MediaQuery.of(context).size;
      final wantTable = TableExplanationView.tableHeightFor(screen);
      // Todo lo que NO es la mesa: etiqueta de teoría + progreso + caption
      // (hasta 2-3 líneas en pantallas angostas) + controles + separaciones.
      // Con margen generoso: si el hueco no alcanza, la mesa cede (hasta el
      // piso de 150) antes que aplastar la burbuja o tapar el botón.
      const belowTable = 220.0;
      final tableHeight = math.max(
        150.0,
        math.min(wantTable, constraints.maxHeight - belowTable),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (theoryTitle != null) ...[
            _TheoryLabel(text: theoryTitle),
            const SizedBox(height: 6),
          ],
          LessonItemProgress(current: current, total: total),
          const SizedBox(height: 10),
          SizedBox(
            height: tableHeight,
            child: AnimatedBuilder(
              animation: _focus,
              builder: (context, _) => TableWithBubble(
                table: table,
                anchor: step.anchor,
                highlight: step.effectiveHighlight.toSet(),
                cardGlow: step.cardGlow,
                glow: Curves.easeOutCubic.transform(_focus.value),
                bubbleText: bubbleText,
              ),
            ),
          ),
          if (captionText != null) ...[
            const SizedBox(height: 10),
            _Caption(text: captionText),
          ],
          const Spacer(),
          LessonNavControls(
            canGoBack: !c.isFirstVisualStep,
            buttonLabel: step.buttonLabel ?? AppStrings.academyContinue,
            onBack: c.prevVisualStep,
            onNext: c.nextVisualStep,
          ),
        ],
      );
    });
  }
}

/// Nombre de la teoría que se está mostrando ("SET", "LOS NUTS"...) — deja
/// claro que, aunque el paso cambie, se sigue dentro de la misma teoría.
class _TheoryLabel extends StatelessWidget {
  const _TheoryLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: AppColors.violetBright,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

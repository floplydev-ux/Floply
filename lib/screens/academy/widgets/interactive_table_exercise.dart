import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_exercise.dart';
import '../../../engine/pedagogy/table_lesson.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import '../academy_controller.dart';
import 'table_explanation_view.dart';

/// Un ejercicio interactivo sobre la mesa: situación → decisión del
/// usuario → resultado → explicación → siguiente.
///
/// Reutiliza [TableExplanationView] (mesa + burbuja/panel) para toda la
/// parte visual; la lógica de evaluación y avance vive en [AcademyController].
class InteractiveTableExercise extends StatefulWidget {
  const InteractiveTableExercise({super.key, required this.controller});

  final AcademyController controller;

  @override
  State<InteractiveTableExercise> createState() =>
      _InteractiveTableExerciseState();
}

class _InteractiveTableExerciseState extends State<InteractiveTableExercise> {
  /// 0 = feedback de la opción elegida; 1..N = paso de explicación N-1.
  int _explainIndex = 0;

  AcademyController get c => widget.controller;

  bool get _answered => c.interactiveChoice != null;

  void _choose(int i) {
    if (_answered) return;
    c.answerInteractive(i);
    setState(() => _explainIndex = 0);
  }

  void _next() {
    final ex = c.currentInteractive;
    if (ex == null) return;
    if (_explainIndex < ex.explanation.length) {
      setState(() => _explainIndex++);
    } else {
      c.advanceInteractive();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = c.currentInteractive;
    if (ex == null) return const SizedBox.shrink();

    final choiceIdx = c.interactiveChoice;
    final chosen = choiceIdx == null ? null : ex.choices[choiceIdx];

    // Estado de la mesa + texto según en qué punto del ejercicio estamos.
    final TableSnapshot rawTable;
    final String rawText;
    final TableAnchor anchor;
    final List<TableAnchor> highlight;
    final bool dimOthers;

    if (!_answered) {
      rawTable = ex.situation;
      rawText = ex.question;
      anchor = ex.questionAnchor;
      highlight = ex.situationHighlight;
      dimOthers = ex.situationHighlight.isNotEmpty;
    } else if (_explainIndex == 0) {
      rawTable = ex.afterDecision ?? ex.situation;
      rawText = chosen!.feedback;
      anchor = ex.questionAnchor;
      highlight = const [];
      dimOthers = false;
    } else {
      final step = ex.explanation[_explainIndex - 1];
      rawTable = step.table ?? ex.afterDecision ?? ex.situation;
      rawText = step.text;
      anchor = step.anchor;
      highlight = step.highlight;
      dimOthers = step.dimOthers;
    }

    final table = c.castTable(rawTable);
    final bubbleText = c.resolveText(rawText, table);

    final isLastItem = c.itemNumber >= c.itemTotal;
    final onLastExplain = _explainIndex >= ex.explanation.length;

    final (accent, panelIcon) = _explanationStyle(chosen);

    return Column(
      children: [
        _TopBar(
          current: c.itemNumber,
          total: c.itemTotal,
          rating: chosen?.rating,
          strategyDependent: ex.strategyDependent,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: TableExplanationView(
            table: table,
            text: bubbleText,
            anchor: anchor,
            highlight: highlight,
            dimOthers: dimOthers,
            stepNumber: c.itemNumber,
            accent: accent,
            panelIcon: panelIcon,
            transitionTag:
                'ex${c.itemNumber}_${_answered ? 1 : 0}_$_explainIndex',
          ),
        ),
        const SizedBox(height: 10),
        if (!_answered)
          _ChoiceButtons(
            labels: [
              for (final ch in ex.choices) c.resolveText(ch.label, table),
            ],
            onChoose: _choose,
          )
        else
          _AnsweredBar(
            choiceLabel: c.resolveText(chosen!.label, table),
            nextLabel: onLastExplain
                ? (isLastItem
                    ? AppStrings.academySeeResult
                    : AppStrings.academyNext)
                : AppStrings.academyContinue,
            onNext: _next,
          ),
      ],
    );
  }

  /// Color e icono del panel según el estado: violeta para la pregunta y
  /// las explicaciones; verde / dorado / rojo para el feedback inmediato de
  /// la opción elegida.
  (Color, IconData) _explanationStyle(ExerciseChoice? chosen) {
    if (!_answered || _explainIndex != 0 || chosen == null) {
      return (AppColors.violetPrimary, Icons.school_rounded);
    }
    return switch (chosen.rating) {
      ExerciseRating.best => (AppColors.neonGreen, Icons.check_rounded),
      ExerciseRating.acceptable => (AppColors.gold, Icons.check_rounded),
      ExerciseRating.poor => (AppColors.danger, Icons.close_rounded),
    };
  }
}

// ================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.current,
    required this.total,
    required this.rating,
    required this.strategyDependent,
  });

  final int current;
  final int total;
  final ExerciseRating? rating;
  final bool strategyDependent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: total == 0 ? 0 : current / total,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.violetBright,
                          AppColors.violetPrimary,
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (rating == null)
          Text(
            '$current / $total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          )
        else
          _ResultChip(rating: rating!, strategyDependent: strategyDependent),
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.rating, required this.strategyDependent});

  final ExerciseRating rating;
  final bool strategyDependent;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rating) {
      ExerciseRating.best => (
          strategyDependent ? '✓ BUENA ELECCIÓN' : '✓ CORRECTO',
          AppColors.neonGreenBright,
        ),
      ExerciseRating.acceptable => (
          strategyDependent ? '≈ TAMBIÉN VÁLIDO' : '≈ ACEPTABLE',
          AppColors.gold,
        ),
      ExerciseRating.poor => (
          strategyDependent ? '✕ HAY ALGO MEJOR' : '✕ NO ES LA MEJOR',
          AppColors.danger,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

/// Las opciones del ejercicio, una por fila y a lo alto necesario: una
/// opción larga se ve entera, sin `...` ni fuente diminuta.
class _ChoiceButtons extends StatelessWidget {
  const _ChoiceButtons({required this.labels, required this.onChoose});

  final List<String> labels;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PressableScale(
            onTap: () => onChoose(i),
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient:
                    const LinearGradient(colors: AppColors.violetGradient),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  height: 1.25,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnsweredBar extends StatelessWidget {
  const _AnsweredBar({
    required this.choiceLabel,
    required this.nextLabel,
    required this.onNext,
  });

  final String choiceLabel;
  final String nextLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded,
                    size: 14, color: AppColors.violetBright),
                const SizedBox(width: 5),
                // Eco de la opción elegida: confirmación, no contenido
                // pedagógico (la opción completa está en el botón que
                // tocó y el porqué en el panel). Se acota a 2 líneas.
                Flexible(
                  child: Text(
                    choiceLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: PressableScale(
            onTap: onNext,
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: AppColors.violetGradient),
              ),
              child: Text(
                nextLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_exercise.dart';
import '../../../engine/pedagogy/table_lesson.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import '../academy_controller.dart';
import 'educational_bubble.dart';
import 'poker_table_view.dart';

/// Un ejercicio interactivo sobre la mesa: situación → decisión del
/// usuario → resultado → explicación (burbujas, una por una) → siguiente.
///
/// Reutiliza [PokerTableView] y [EducationalBubble]; la lógica de
/// evaluación y avance vive en [AcademyController].
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

    // Estado de la mesa + burbuja según en qué punto del ejercicio estamos.
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

    final subKey = '${_answered ? 1 : 0}_$_explainIndex';
    final isLastItem = c.itemNumber >= c.itemTotal;
    final onLastExplain = _explainIndex >= ex.explanation.length;

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
          child: LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final layout = TableLayout(size);
            final anchorPoint = layout.anchorPoint(anchor);
            final hi = (highlight.isEmpty ? [anchor] : highlight).toSet();

            return TweenAnimationBuilder<double>(
              key: ValueKey('anim$subKey'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: PokerTableView(
                          key: ValueKey('table$subKey'),
                          snapshot: table,
                          highlight: hi,
                          dimOthers: dimOthers,
                          glow: t,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.93, end: 1).animate(a),
                          child: child,
                        ),
                      ),
                      child: EducationalBubble(
                        key: ValueKey('bubble$subKey'),
                        text: bubbleText,
                        anchor: anchorPoint,
                        containerSize: size,
                        stepNumber: c.itemNumber,
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
        const SizedBox(height: 8),
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

class _ChoiceButtons extends StatelessWidget {
  const _ChoiceButtons({required this.labels, required this.onChoose});

  final List<String> labels;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: PressableScale(
              onTap: () => onChoose(i),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient:
                      const LinearGradient(colors: AppColors.violetGradient),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                Flexible(
                  child: Text(
                    choiceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: AppColors.violetGradient),
              ),
              child: Text(
                nextLabel,
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

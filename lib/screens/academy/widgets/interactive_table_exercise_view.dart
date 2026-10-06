import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_exercise.dart';
import '../../../engine/pedagogy/table_lesson.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart' show ratingBadge;
import 'table_explanation_view.dart';

/// Un ejercicio interactivo sobre la mesa: situación → decisión del
/// usuario → resultado → explicación → siguiente.
///
/// Reutiliza [TableExplanationView] (mesa + burbuja/panel) para toda la
/// parte visual; la lógica de evaluación y avance vive en [AcademyController].
///
/// Se llama `...View` porque el nombre `InteractiveTableExercise` ya lo usa
/// el modelo de dominio ([InteractiveTableExercise] en
/// `engine/pedagogy/table_exercise.dart`, con 15+ referencias en el
/// contenido del curriculum) — este widget es el único de los dos con pocas
/// referencias, así que es el que cambió de nombre.
class InteractiveTableExerciseView extends StatefulWidget {
  const InteractiveTableExerciseView({super.key, required this.controller});

  final AcademyController controller;

  @override
  State<InteractiveTableExerciseView> createState() =>
      _InteractiveTableExerciseViewState();
}

class _InteractiveTableExerciseViewState
    extends State<InteractiveTableExerciseView> {
  /// 0 = feedback de la opción elegida; 1..N = paso de explicación N-1.
  int _explainIndex = 0;

  /// Orden de PRESENTACIÓN de `ex.choices`: `_order[posiciónEnPantalla] =
  /// índiceOriginalEnEx.choices`. Se sortea una sola vez por ejercicio (acá
  /// en `initState`, porque este widget recibe una key nueva —
  /// `ValueKey('itex$itemNumber')` en `lesson_flow.dart`— por cada ítem, así
  /// que el estado se recrea solo en cada pregunta nueva). La respuesta
  /// correcta y el resto de la lógica de evaluación no cambian: siguen
  /// viviendo en `ExerciseChoice.rating`/`AcademyController.answerInteractive`
  /// indexados por la posición ORIGINAL — esto solo reordena qué se dibuja.
  late List<int> _order;

  AcademyController get c => widget.controller;

  bool get _answered => c.interactiveChoice != null;

  @override
  void initState() {
    super.initState();
    final n = c.currentInteractive?.choices.length ?? 0;
    _order = List<int>.generate(n, (i) => i)..shuffle();
  }

  void _choose(int displayIndex) {
    if (_answered) return;
    c.answerInteractive(_order[displayIndex]);
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
              for (final origIdx in _order)
                c.resolveText(ex.choices[origIdx].label, table),
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

  /// Color e icono del panel según el estado: `feltGreen` para la pregunta
  /// y las explicaciones; verde/ámbar/rojo Sala Verde para el feedback
  /// inmediato de la opción elegida (mismo criterio que
  /// `PlayableTableExerciseView._explanationStyle`, Fase 5).
  (Color, IconData) _explanationStyle(ExerciseChoice? chosen) {
    if (!_answered || _explainIndex != 0 || chosen == null) {
      return (SalaVerdeColors.feltGreen, Icons.school_rounded);
    }
    return switch (chosen.rating) {
      ExerciseRating.best => (SalaVerdeColors.feltGreenBright, Icons.check_rounded),
      ExerciseRating.acceptable => (SalaVerdeColors.warning, Icons.check_rounded),
      ExerciseRating.poor => (SalaVerdeColors.errorBright, Icons.close_rounded),
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
    final ratio = total == 0 ? 0.0 : current / total;
    return Row(
      children: [
        Expanded(child: SvProgressLinear(value: ratio, color: SalaVerdeColors.feltGreenBright, height: 7)),
        const SizedBox(width: SalaVerdeSpace.md),
        if (rating == null)
          Text(
            '$current / $total',
            style: SalaVerdeType.numeric(size: 12, color: SalaVerdeColors.textMuted),
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

  /// `ratingBadge()` (`lesson_widgets.dart`) da el texto — su semántica no
  /// cambia acá. El COLOR se recalcula localmente a tokens Sala Verde: esa
  /// función también la usa `mentor_lesson_stage_view.dart`, fuera de
  /// alcance de esta fase (ver auditoría, `FLOPLY_PHASE_6_INTERACTIVE_TABLE.md`).
  Color _svColor() => switch (rating) {
        ExerciseRating.best => SalaVerdeColors.feltGreenBright,
        ExerciseRating.acceptable => SalaVerdeColors.warning,
        ExerciseRating.poor => SalaVerdeColors.errorBright,
      };

  @override
  Widget build(BuildContext context) {
    final (label, _) = ratingBadge(rating, strategyDependent: strategyDependent);
    final color = _svColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(SalaVerdeRadius.sharp),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: SalaVerdeType.label(color: color).copyWith(fontSize: 10.5),
      ),
    );
  }
}

/// Las opciones del ejercicio, una por fila y a lo alto necesario: una
/// opción larga se ve entera, sin `...` ni fuente diminuta. Reutiliza
/// `SvButtonPrimary` (no un `Container` a medida): las opciones de un
/// ejercicio interactivo son visualmente equivalentes entre sí (a
/// diferencia de las acciones de póker de `PlayableTableExerciseView`,
/// que sí distinguen fold/check/bet), así que el mismo botón primario
/// repetido, con la temperatura de Academia (`feltGreen`, no `brass`), es
/// la forma correcta.
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
          if (i > 0) const SizedBox(height: SalaVerdeSpace.sm),
          SvButtonPrimary(
            label: labels[i],
            onTap: () => onChoose(i),
            accent: SalaVerdeColors.feltGreen,
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
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              color: SalaVerdeColors.surfaceElevated,
              border: Border.all(color: SalaVerdeColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded,
                    size: 14, color: SalaVerdeColors.feltGreenBright),
                const SizedBox(width: 5),
                // Eco de la opción elegida: confirmación, no contenido
                // pedagógico (la opción completa está en el botón que
                // tocó y el porqué en el panel). Se acota a 2 líneas.
                Flexible(
                  child: Text(
                    choiceLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SalaVerdeType.bodyStrong().copyWith(fontSize: 12, height: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: SalaVerdeSpace.sm),
        Expanded(
          flex: 6,
          child: SvButtonPrimary(label: nextLabel, onTap: onNext),
        ),
      ],
    );
  }
}

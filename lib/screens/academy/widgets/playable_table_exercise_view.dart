import 'package:flutter/material.dart';

import '../../../engine/pedagogy/playable_exercise.dart';
import '../../../engine/pedagogy/playable_exercise_controller.dart';
import '../../../engine/pedagogy/table_lesson.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import 'lesson_widgets.dart' show ratingBadge;
import 'table_explanation_view.dart';

/// Un ejercicio **jugable**: en vez de responder una pregunta con
/// opciones de texto, el alumno decide una acción real de póker
/// directamente sobre la mesa — FOLD/CHECK/BET/RAISE… (lo que la
/// situación tenga legal), tamaño si corresponde, y (si el ejercicio lo
/// pide) por qué.
///
/// Reutiliza [TableExplanationView] (mesa + burbuja/panel) igual que
/// [InteractiveTableExerciseView] — es la misma mesa de la teoría, no una
/// segunda. La lógica de evaluación y avance vive en
/// [PlayableExerciseController] — cualquier host (Academia, Laboratorio)
/// que la implemente sirve acá, este widget no sabe cuál es.
///
/// Flujo (estado derivado del controller, no propio del widget): elegir
/// acción → elegir tamaño (si la acción lo pide) → elegir por qué (si el
/// ejercicio tiene ese paso) → devolución → explicación.
class PlayableTableExerciseView extends StatefulWidget {
  const PlayableTableExerciseView({
    super.key,
    required this.controller,
    this.progressAccent = SalaVerdeColors.feltGreenBright,
    this.pendingAccent = SalaVerdeColors.feltGreen,
  });

  final PlayableExerciseController controller;

  /// Temperatura de la sección que aloja este widget — barra de progreso
  /// y el ícono de "ya respondiste" del eco de la acción. Default
  /// `feltGreenBright` (Academia); Laboratorio (Fase 7) pasa
  /// `steelBlueBright` desde `laboratory_screen.dart`. Sin esto, la
  /// barra de progreso de Laboratorio quedaba verde-Academia dentro de
  /// una pantalla azul-Laboratorio — hallazgo real de QA visual, no
  /// anticipado en el diseño original de la Fase 5.
  final Color progressAccent;

  /// Acento de la burbuja mientras el alumno todavía no respondió —
  /// mismo criterio que [progressAccent] pero para el tono "neutro/
  /// decidiendo" (no es una superficie de relleno, así que puede seguir
  /// siendo la variante base de la sección en vez de la `Bright`).
  final Color pendingAccent;

  @override
  State<PlayableTableExerciseView> createState() =>
      _PlayableTableExerciseViewState();
}

class _PlayableTableExerciseViewState extends State<PlayableTableExerciseView> {
  /// 0 = devolución completa; 1..N = paso de explicación N-1.
  int _explainIndex = 0;

  PlayableExerciseController get c => widget.controller;

  bool get _answered => c.lastPlayableFeedback != null;

  void _chooseAction(int i) {
    if (c.playableActionIndex != null) return;
    c.choosePlayableAction(i);
  }

  void _chooseSize(int i) {
    c.choosePlayableSize(i);
  }

  void _chooseReasoning(int i) {
    if (_answered) return;
    setState(() => _explainIndex = 0);
    c.confirmPlayableReasoning(i);
  }

  void _next() {
    final ex = c.currentPlayable;
    if (ex == null) return;
    if (_explainIndex < ex.explanation.length) {
      setState(() => _explainIndex++);
    } else {
      c.advancePlayable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = c.currentPlayable;
    if (ex == null) return const SizedBox.shrink();

    final actionIdx = c.playableActionIndex;
    final action = actionIdx == null ? null : ex.actions[actionIdx];
    final sizeIdx = c.playableSizeIndex;
    final size = (action != null && sizeIdx != null)
        ? action.sizeOptions[sizeIdx]
        : null;
    final feedback = c.lastPlayableFeedback;

    // Mesa: la situación mientras se decide; una vez que la acción (y el
    // tamaño, si aplica) están confirmados, la mesa refleja lo sucedido.
    final TableSnapshot table;
    final String bubbleText;
    final TableAnchor anchor;
    final List<TableAnchor> highlight;
    final bool dimOthers;

    if (!c.needsPlayableSizing && action != null) {
      table = size?.afterDecision ??
          action.afterDecision ??
          ex.afterDecision ??
          ex.situation;
    } else {
      table = ex.situation;
    }

    if (action == null) {
      bubbleText = ex.prompt;
      anchor = ex.questionAnchor;
      highlight = ex.situationHighlight;
      dimOthers = ex.situationHighlight.isNotEmpty;
    } else if (c.needsPlayableSizing) {
      bubbleText = AppStrings.playableChooseSizeBody(action.label);
      anchor = ex.questionAnchor;
      highlight = ex.situationHighlight;
      dimOthers = ex.situationHighlight.isNotEmpty;
    } else if (!_answered) {
      final actionAndSize =
          size == null ? action.label : '${action.label} (${size.label})';
      bubbleText = AppStrings.playableWhyBody(actionAndSize);
      anchor = ex.questionAnchor;
      highlight = const [];
      dimOthers = false;
    } else if (_explainIndex == 0) {
      bubbleText = _fullFeedbackText(ex, feedback!);
      anchor = ex.questionAnchor;
      highlight = const [];
      dimOthers = false;
    } else {
      final step = ex.explanation[_explainIndex - 1];
      bubbleText = step.text;
      anchor = step.anchor;
      highlight = step.highlight;
      dimOthers = step.dimOthers;
    }

    final isLastItem = c.itemNumber >= c.itemTotal;
    final onLastExplain = _answered && _explainIndex >= ex.explanation.length;

    final (accent, panelIcon) = feedback == null
        ? (widget.pendingAccent, Icons.style_rounded)
        : _explanationStyle(feedback.combined);

    final Widget bottomBar;
    if (action == null) {
      bottomBar = _ActionButtons(actions: ex.actions, onChoose: _chooseAction);
    } else if (c.needsPlayableSizing) {
      bottomBar = _SizeButtons(sizes: action.sizeOptions, onChoose: _chooseSize);
    } else if (!_answered) {
      bottomBar = _ReasoningButtons(
        reasoning: action.reasoning,
        onChoose: _chooseReasoning,
      );
    } else {
      bottomBar = _AnsweredBar(
        actionLabel:
            size == null ? action.label : '${action.label} · ${size.label}',
        nextLabel: onLastExplain
            ? (isLastItem ? AppStrings.academySeeResult : AppStrings.academyNext)
            : AppStrings.academyContinue,
        onNext: _next,
        echoAccent: widget.progressAccent,
      );
    }

    return Column(
      children: [
        _TopBar(
          current: c.itemNumber,
          total: c.itemTotal,
          rating: feedback?.combined,
          strategyDependent: ex.strategyDependent,
          progressAccent: widget.progressAccent,
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
            transitionTag: 'pl${c.itemNumber}_${actionIdx ?? -1}_'
                '${sizeIdx ?? -1}_${_answered ? 1 : 0}_$_explainIndex',
          ),
        ),
        const SizedBox(height: 10),
        bottomBar,
      ],
    );
  }

  /// La devolución completa: qué acción eligió, qué tan buena fue, por
  /// qué, y una evaluación separada de su razonamiento — nunca un simple
  /// "elegiste X".
  String _fullFeedbackText(
      PlayableTableExercise ex, PlayableFeedback feedback) {
    final action = feedback.action;
    final size = feedback.size;
    final reasoning = feedback.reasoning;

    final (actionVerdict, _) =
        ratingBadge(action.rating, strategyDependent: ex.strategyDependent);

    final buffer = StringBuffer()
      ..writeln('${AppStrings.playableActionResultLabel} ${action.label}'
          '${size == null ? '' : ' (${size.label})'}. $actionVerdict.')
      ..writeln()
      ..writeln(action.feedback);

    if (size != null && size.rating != action.rating) {
      buffer
        ..writeln()
        ..writeln(size.feedback);
    }

    // El paso de razonamiento es opcional (Laboratorio no lo tiene, ver
    // ActionChoice.reasoning) — sin él, la devolución se corta acá.
    if (reasoning != null) {
      final (reasoningVerdict, _) = ratingBadge(reasoning.rating);
      buffer
        ..writeln()
        ..writeln('${AppStrings.playableReasoningLabel}: $reasoningVerdict.')
        ..writeln(reasoning.feedback);
    }

    if (ex.concept != null) {
      buffer
        ..writeln()
        ..write('${AppStrings.playableConceptLabel}: '
            '${widget.controller.conceptName(ex.concept!)}.');
    }

    // Evita un buffer terminando en salto de línea colgante.
    return buffer.toString().trim();
  }

  // `success` (no la temperatura de sección): el veredicto "best" es un
  // semántico universal (Fase 7, hallazgo real al sumar Laboratorio como
  // segundo consumidor — usar `feltGreenBright` acá conflaba "mejor
  // respuesta" con "identidad de Academia", invisible mientras solo
  // existía un consumidor).
  (Color, IconData) _explanationStyle(ExerciseRating combined) =>
      switch (combined) {
        ExerciseRating.best => (SalaVerdeColors.success, Icons.check_rounded),
        ExerciseRating.acceptable => (SalaVerdeColors.warning, Icons.check_rounded),
        ExerciseRating.poor => (SalaVerdeColors.errorBright, Icons.close_rounded),
      };
}

// ================================================================
// Barra de acciones: FOLD/CHECK/BET/RAISE… — solo las que la situación
// trae, ninguna está hardcodeada acá.
// ================================================================

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.actions, required this.onChoose});

  final List<ActionChoice> actions;
  final ValueChanged<int> onChoose;

  static ({Color fg, Color bg, Color border, bool filled}) _styleFor(
      PokerAction action) {
    switch (action) {
      case PokerAction.fold:
        return (
          fg: SalaVerdeColors.errorBright,
          bg: SalaVerdeColors.error.withValues(alpha: 0.08),
          border: SalaVerdeColors.errorBright.withValues(alpha: 0.45),
          filled: false,
        );
      case PokerAction.check:
      case PokerAction.call:
      case PokerAction.limp:
        return (
          fg: SalaVerdeColors.textSecondary,
          bg: SalaVerdeColors.surfaceElevated,
          border: SalaVerdeColors.borderSubtle,
          filled: false,
        );
      case PokerAction.bet:
      case PokerAction.raise:
      case PokerAction.allIn:
        // feltGreen (relleno) + textPrimary: 5.26:1 — feltGreenBright es
        // la variante para texto/ícono, no para relleno (ver
        // sala_verde_tokens.dart); background como texto acá mide solo
        // 3.13:1, insuficiente para este tamaño de fuente.
        return (
          fg: SalaVerdeColors.textPrimary,
          bg: SalaVerdeColors.feltGreen,
          border: Colors.transparent,
          filled: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
              child: _ActionButton(
            action: actions[i],
            style: _styleFor(actions[i].action),
            onTap: () => onChoose(i),
          )),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.style,
    required this.onTap,
  });

  final ActionChoice action;
  final ({Color fg, Color bg, Color border, bool filled}) style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: style.bg,
          border: Border.all(color: style.border, width: 1.4),
          boxShadow: style.filled
              ? [
                  BoxShadow(
                    color: style.bg.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          action.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
            letterSpacing: 0.4,
            color: style.fg,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// Tamaño (BET/RAISE) — solo aparece si la acción elegida lo pide.
// ================================================================

class _SizeButtons extends StatelessWidget {
  const _SizeButtons({required this.sizes, required this.onChoose});

  final List<BetSizeOption> sizes;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < sizes.length; i++)
          PressableScale(
            onTap: () => onChoose(i),
            child: Container(
              constraints: const BoxConstraints(minHeight: 46, minWidth: 84),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: SalaVerdeColors.surfaceElevated,
                border: Border.all(color: SalaVerdeColors.borderSubtle),
              ),
              child: Text(
                sizes[i].label,
                style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.textPrimary),
              ),
            ),
          ),
      ],
    );
  }
}

// ================================================================
// Razonamiento: "¿por qué?" — lista de opciones tipo radio, un eje de
// evaluación totalmente aparte de la acción.
// ================================================================

class _ReasoningButtons extends StatelessWidget {
  const _ReasoningButtons({required this.reasoning, required this.onChoose});

  final List<ReasoningOption> reasoning;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.playableWhyTitle,
          style: SalaVerdeType.label(color: SalaVerdeColors.textMuted),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        for (var i = 0; i < reasoning.length; i++) ...[
          if (i > 0) const SizedBox(height: SalaVerdeSpace.sm),
          PressableScale(
            onTap: () => onChoose(i),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: SalaVerdeSpace.lg,
                vertical: SalaVerdeSpace.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                color: SalaVerdeColors.surfaceElevated,
                border: Border.all(color: SalaVerdeColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle_outlined,
                      size: 16, color: SalaVerdeColors.textMuted),
                  const SizedBox(width: SalaVerdeSpace.sm),
                  Expanded(
                    child: Text(reasoning[i].label, style: SalaVerdeType.bodyStrong()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ================================================================
// Compartidos con InteractiveTableExerciseView (misma forma, mismo
// comportamiento) — deliberadamente locales: son 2 usos, no vale la pena
// una tercera capa de indirección para evitar este pequeño duplicado.
// ================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.current,
    required this.total,
    required this.rating,
    required this.strategyDependent,
    required this.progressAccent,
  });

  final int current;
  final int total;
  final ExerciseRating? rating;
  final bool strategyDependent;
  final Color progressAccent;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : current / total;
    return Row(
      children: [
        Expanded(child: SvProgressLinear(value: ratio, color: progressAccent, height: 7)),
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
  /// cambia acá. El COLOR sí se recalcula localmente a tokens Sala Verde:
  /// esa función también la usan `InteractiveTableExerciseView` y
  /// `mentor_lesson_stage_view.dart`, fuera de alcance de esta fase — no
  /// se puede tocar su color sin afectarlas (ver auditoría, Fase 5 §D).
  /// `success` para "best" (no una temperatura de sección, ver Fase 7).
  Color _svColor() => switch (rating) {
        ExerciseRating.best => SalaVerdeColors.success,
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

class _AnsweredBar extends StatelessWidget {
  const _AnsweredBar({
    required this.actionLabel,
    required this.nextLabel,
    required this.onNext,
    required this.echoAccent,
  });

  final String actionLabel;
  final String nextLabel;
  final VoidCallback onNext;
  final Color echoAccent;

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
                Icon(Icons.check_rounded, size: 14, color: echoAccent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    actionLabel,
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

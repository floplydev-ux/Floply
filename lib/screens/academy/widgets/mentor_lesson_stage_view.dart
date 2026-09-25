import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../engine/pedagogy/mentor_lesson.dart';
import '../../../engine/pedagogy/table_exercise.dart'
    show ExerciseChoice, ExerciseRating;
import '../../../engine/pedagogy/table_lesson.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart' show LessonItemProgress, LessonNavControls, ratingBadge;
import 'table_bubble.dart';
import 'table_explanation_view.dart';

/// **Clase de mentor** (Fase 3): reemplaza a `WrittenTheoryView` para las
/// teorías migradas al nuevo paradigma pedagógico. Recorre los turnos
/// (`MentorBeat`) de un `MentorLesson`: el mentor habla (con o sin apoyo de
/// mesa) o pregunta y espera una respuesta antes de seguir.
///
/// Mismo patrón estructural que `VisualTheoryStageView` (título de la
/// teoría + progreso + cuerpo + navegación) y reutiliza literalmente su
/// geometría de mesa+burbuja vía [TableWithBubble] — no es un sistema visual
/// nuevo, es el mismo lenguaje aplicado a una estructura de contenido más
/// rica (turnos de habla Y de pregunta, no solo narración).
class MentorLessonStageView extends StatefulWidget {
  const MentorLessonStageView({super.key, required this.controller});

  final AcademyController controller;

  @override
  State<MentorLessonStageView> createState() => _MentorLessonStageViewState();
}

class _MentorLessonStageViewState extends State<MentorLessonStageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  int _lastBeat = -1;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final beat = c.currentMentorBeat;
    if (beat == null) return const SizedBox.shrink();

    if (c.mentorBeatIndex != _lastBeat) {
      _lastBeat = c.mentorBeatIndex;
      _focus.forward(from: 0);
    }

    final theoryTitle = c.currentWrittenTheory?.titulo;
    final total = c.mentorBeatCount;
    final current = c.mentorBeatIndex + 1;

    final TableSnapshot? rawTable = switch (beat) {
      MentorSayBeat s => s.say.table,
      MentorCheckBeat ch => ch.check.table,
    };
    final hasTable = rawTable != null;
    final table = hasTable ? c.castTable(rawTable) : null;

    return LayoutBuilder(builder: (context, constraints) {
      final screen = MediaQuery.of(context).size;
      final wantTable = TableExplanationView.tableHeightFor(screen);
      // Un turno de comprobación necesita más lugar abajo (opciones +
      // feedback) que uno de habla (solo CONTINUAR).
      final belowBody = beat is MentorCheckBeat ? 250.0 : 200.0;
      final tableHeight = math.max(
        150.0,
        math.min(wantTable, constraints.maxHeight - belowBody),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (theoryTitle != null) ...[
            _MentorLabel(text: theoryTitle),
            const SizedBox(height: 6),
          ],
          LessonItemProgress(current: current, total: total),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: _BeatHead(
                controller: c,
                beat: beat,
                table: table,
                tableHeight: tableHeight,
                focus: _focus,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _BeatFoot(controller: c, beat: beat, table: table),
        ],
      );
    });
  }
}

/// Nombre de la teoría que se está mostrando — igual criterio que
/// `_TheoryLabel` del piloto visual (queda claro que, aunque el turno
/// cambie, se sigue dentro de la misma teoría).
class _MentorLabel extends StatelessWidget {
  const _MentorLabel({required this.text});

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

/// La parte de arriba del turno: mesa+burbuja si el turno tiene mesa, si no
/// una tarjeta del mentor hablando directo.
class _BeatHead extends StatelessWidget {
  const _BeatHead({
    required this.controller,
    required this.beat,
    required this.table,
    required this.tableHeight,
    required this.focus,
  });

  final AcademyController controller;
  final MentorBeat beat;
  final TableSnapshot? table;
  final double tableHeight;
  final AnimationController focus;

  @override
  Widget build(BuildContext context) {
    final t = table;
    final (text, anchor, highlight, cardGlow, role) = switch (beat) {
      MentorSayBeat s => (
          s.say.text,
          s.say.anchor,
          s.say.effectiveHighlight.toSet(),
          s.say.cardGlow,
          s.say.role,
        ),
      MentorCheckBeat ch => (
          ch.check.prompt,
          ch.check.anchor,
          ch.check.effectiveHighlight.toSet(),
          const <CardRef>{},
          MentorSayRole.explain,
        ),
    };

    if (t == null) {
      return _MentorTalkCard(text: text, role: role);
    }

    final bubbleText = controller.resolveText(text, t);
    return SizedBox(
      height: tableHeight,
      child: AnimatedBuilder(
        animation: focus,
        builder: (context, _) => TableWithBubble(
          table: t,
          anchor: anchor!,
          highlight: highlight,
          cardGlow: cardGlow,
          glow: Curves.easeOutCubic.transform(focus.value),
          bubbleText: bubbleText,
        ),
      ),
    );
  }
}

/// Una tarjeta del mentor hablando sin apoyo de mesa: para definiciones
/// cortas, puentes con lo ya visto, o la idea clave de cierre. El acento
/// visual (ícono + color) cambia según [MentorSayRole] — la idea clave usa
/// el mismo tratamiento dorado/violeta que ya tenía `WrittenTheoryView`,
/// para que el alumno la reconozca como "esto es lo que me llevo" en
/// cualquiera de las dos experiencias.
class _MentorTalkCard extends StatelessWidget {
  const _MentorTalkCard({required this.text, required this.role});

  final String text;
  final MentorSayRole role;

  @override
  Widget build(BuildContext context) {
    if (role == MentorSayRole.keyIdea) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.violetPrimary.withValues(alpha: 0.22),
              AppColors.violetDeep.withValues(alpha: 0.22),
            ],
          ),
          border:
              Border.all(color: AppColors.violetBright.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.push_pin_rounded, size: 15, color: AppColors.violetBright),
                SizedBox(width: 7),
                Text(
                  'IDEA CLAVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.violetBright,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final (icon, accent) = switch (role) {
      MentorSayRole.intro => (Icons.chat_bubble_rounded, const Color(0xFFE0B860)),
      MentorSayRole.observe => (Icons.visibility_rounded, AppColors.diamondBlue),
      MentorSayRole.explain => (Icons.school_rounded, AppColors.violetBright),
      MentorSayRole.example => (Icons.casino_rounded, AppColors.neonGreenBright),
      MentorSayRole.error => (Icons.warning_amber_rounded, AppColors.danger),
      MentorSayRole.bridge => (Icons.link_rounded, AppColors.textSecondary),
      MentorSayRole.keyIdea => (Icons.push_pin_rounded, AppColors.gold), // unreachable
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF14100A),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La parte de abajo del turno: opciones (si es una pregunta sin
/// responder), feedback + navegación (si ya se respondió, o si el turno es
/// solo de habla).
class _BeatFoot extends StatelessWidget {
  const _BeatFoot({
    required this.controller,
    required this.beat,
    required this.table,
  });

  final AcademyController controller;
  final MentorBeat beat;
  final TableSnapshot? table;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    if (beat is MentorCheckBeat) {
      final check = (beat as MentorCheckBeat).check;
      final answer = c.mentorCheckAnswer;
      final t = table;
      String label(ExerciseChoice o) =>
          t == null ? o.label : c.resolveText(o.label, t);

      if (answer == null) {
        return _MentorChoiceButtons(
          options: check.options,
          labelFor: label,
          onChoose: c.answerMentorCheck,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MentorAnswerFeedback(
            chosen: check.options[answer],
            wrapUp: check.wrapUp,
          ),
          const SizedBox(height: 12),
          LessonNavControls(
            canGoBack: !c.isFirstMentorBeat,
            buttonLabel: c.mentorContinueLabel,
            onBack: c.prevMentorBeat,
            onNext: c.nextMentorBeat,
          ),
        ],
      );
    }

    return LessonNavControls(
      canGoBack: !c.isFirstMentorBeat,
      buttonLabel: c.mentorContinueLabel,
      onBack: c.prevMentorBeat,
      onNext: c.nextMentorBeat,
    );
  }
}

/// Las opciones de una comprobación, antes de responder. Deliberadamente
/// distinta de `_ChoiceButtons` de los ejercicios reales (violeta, cuenta
/// para el puntaje): acá el tono es el mismo dorado/oscuro de la burbuja
/// del mentor, para que se sienta "el profesor me está preguntando", no
/// "ejercicio 3 de 8".
class _MentorChoiceButtons extends StatelessWidget {
  const _MentorChoiceButtons({
    required this.options,
    required this.labelFor,
    required this.onChoose,
  });

  final List<ExerciseChoice> options;
  final String Function(ExerciseChoice) labelFor;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PressableScale(
            onTap: () => onChoose(i),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF14100A),
                border: Border.all(
                    color: const Color(0xFFE0B860).withValues(alpha: 0.55)),
              ),
              child: Text(
                labelFor(options[i]),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: Color(0xFFE0B860),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// El feedback tras responder una comprobación: color/ícono por
/// `ExerciseRating` (misma paleta que ya usan los ejercicios reales, vía
/// `ratingBadge`, para que "correcto/aceptable/mejor otra cosa" se lea
/// igual en toda la app) + el texto de esa opción + el cierre del mentor.
class _MentorAnswerFeedback extends StatelessWidget {
  const _MentorAnswerFeedback({required this.chosen, this.wrapUp});

  final ExerciseChoice chosen;
  final String? wrapUp;

  @override
  Widget build(BuildContext context) {
    final (label, color) = ratingBadge(chosen.rating);
    final icon = chosen.rating == ExerciseRating.poor
        ? Icons.close_rounded
        : Icons.check_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            chosen.feedback,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          if (wrapUp != null) ...[
            const SizedBox(height: 10),
            Text(
              wrapUp!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

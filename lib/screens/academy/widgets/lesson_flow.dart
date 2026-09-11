import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../academy_controller.dart';
import 'exercise_view.dart';
import 'feedback_view.dart';
import 'interactive_table_exercise.dart';
import 'interactive_table_lesson.dart';
import 'lesson_result_view.dart';
import 'lesson_widgets.dart';
import 'theory_view.dart';
import 'visual_theory_stage.dart';
import 'written_theory_view.dart';

/// El recorrido de un lesson: teoría → ejercicios → feedback → resultado.
///
/// Router fino: arma el encabezado y, según `controller.phase` (y si el
/// lesson es interactivo sobre la mesa), delega en la vista de fase
/// correspondiente (`theory_view` / `exercise_view` / `feedback_view` /
/// `lesson_result_view` / `interactive_table_*`).
class LessonFlow extends StatelessWidget {
  const LessonFlow({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final lessonId = controller.activeLessonId;
    final lesson =
        lessonId == null ? null : controller.academy.lessonById(lessonId);

    final header = LessonFlowHeader(
      title: lesson == null ? '' : '${lesson.id}  ${lesson.title}',
      subtitle: controller.isRecovering
          ? AppStrings.academyRecoveryTitle
          : (lesson?.kind.label ?? ''),
      onBack: controller.exitLesson,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
      // Deja aire real bajo los controles: el inset inferior del dispositivo
      // (barra de gestos) más un colchón. Cuando la pantalla ya reserva ese
      // inset (dentro del shell con barra de navegación) esto queda en el
      // colchón mínimo.
      final bottomInset =
          MediaQuery.of(context).padding.bottom.clamp(0.0, 16.0);

      // Teoría interactiva / experiencia visual piloto / fichas de teoría
      // redactada / ejercicios interactivos: ocupan toda la altura (no van
      // dentro del scroll).
      if (controller.isInteractiveTheory ||
          controller.isVisualTheory ||
          controller.isWrittenTheory ||
          controller.isInteractiveExercise) {
        return Padding(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              Expanded(child: _fullHeightBody()),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 16),
            _body(),
          ],
        ),
      );
    });
  }

  Widget _fullHeightBody() {
    if (controller.isInteractiveTheory) {
      return InteractiveTableLesson(controller: controller);
    }
    if (controller.isVisualTheory) {
      return VisualTheoryStageView(controller: controller);
    }
    if (controller.isWrittenTheory) {
      return WrittenTheoryView(controller: controller);
    }
    return InteractiveTableExercise(
      key: ValueKey('itex${controller.itemNumber}'),
      controller: controller,
    );
  }

  Widget _body() {
    switch (controller.phase) {
      case AcademyPhase.theory:
        return TheoryView(controller: controller);
      case AcademyPhase.exercise:
        return ExerciseView(controller: controller);
      case AcademyPhase.feedback:
        return FeedbackView(controller: controller);
      case AcademyPhase.result:
        return LessonResultView(controller: controller);
      case AcademyPhase.map:
        return const SizedBox.shrink();
    }
  }
}

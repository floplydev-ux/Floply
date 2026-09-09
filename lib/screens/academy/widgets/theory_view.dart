import 'package:flutter/material.dart';

import '../../../engine/pedagogy/lesson_content.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart';

/// Fase teoría (no interactiva): objetivo + bloques de teoría + CONTINUAR.
class TheoryView extends StatelessWidget {
  const TheoryView({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final content = controller.contentFor(controller.activeLessonId!);
    if (content == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.violetPrimary.withValues(alpha: 0.1),
            border:
                Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded,
                  size: 16, color: AppColors.violetBright),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content.objective,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final block in content.theory) ...[
          _TheoryBlockView(block: block),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        LessonPrimaryButton(
          label: AppStrings.academyContinue,
          onTap: controller.startExercises,
        ),
      ],
    );
  }
}

class _TheoryBlockView extends StatelessWidget {
  const _TheoryBlockView({required this.block});

  final TheoryBlock block;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (block.kind) {
      TheoryBlockKind.concept => (
          Icons.lightbulb_rounded,
          AppColors.gold,
          'CONCEPTO'
        ),
      TheoryBlockKind.explanation => (
          Icons.subject_rounded,
          AppColors.textSecondary,
          'EXPLICACIÓN'
        ),
      TheoryBlockKind.example => (
          Icons.casino_rounded,
          AppColors.neonGreenBright,
          'EJEMPLO'
        ),
      TheoryBlockKind.keyPoint => (
          Icons.push_pin_rounded,
          AppColors.violetBright,
          'PARA RECORDAR'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
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
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

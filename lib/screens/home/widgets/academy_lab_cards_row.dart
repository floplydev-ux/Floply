import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../academy/academy_controller.dart';
import 'home_banner_action_button.dart';

/// Academia y Laboratorio, una al lado de la otra — la fila principal del
/// Home rediseñado (pedido explícito: nunca en vertical, misma altura).
class AcademyLabCardsRow extends StatelessWidget {
  const AcademyLabCardsRow({
    super.key,
    required this.controller,
    required this.onGoToAcademy,
    required this.onGoToLaboratory,
  });

  final AcademyController controller;
  final VoidCallback onGoToAcademy;
  final VoidCallback onGoToLaboratory;

  void _continueAcademy() {
    final id = controller.currentLessonId;
    if (id != null) controller.openLesson(id);
    onGoToAcademy();
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => _AcademyCard(
                controller: controller,
                onContinue: _continueAcademy,
                onPracticeInstead: onGoToLaboratory,
              ),
            ),
          ),
          const SizedBox(width: SalaVerdeSpace.sm),
          Expanded(child: _LaboratoryCard(onPracticeNow: onGoToLaboratory)),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.accent,
    required this.onTap,
    required this.child,
    this.backgroundImage,
  });

  final Color accent;
  final VoidCallback onTap;
  final Widget child;
  final String? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final image = backgroundImage;
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SalaVerdeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.24),
              blurRadius: 36,
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (image != null) ...[
              Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(SalaVerdeSpace.md),
              child: child,
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: HomeBannerActionButton(onPressed: onTap),
            ),
          ],
        ),
      );
  }
}

class _AcademyCard extends StatelessWidget {
  const _AcademyCard({
    required this.controller,
    required this.onContinue,
    required this.onPracticeInstead,
  });

  final AcademyController controller;
  final VoidCallback onContinue;
  final VoidCallback onPracticeInstead;

  static const _backgroundImage = 'assets/images/home/academy_card_bg.jpg';

  @override
  Widget build(BuildContext context) {
    const accent = SalaVerdeColors.violetBright;

    if (controller.loading) {
      return _CardShell(
        accent: accent,
        backgroundImage: _backgroundImage,
        onTap: onContinue,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: accent),
          ),
        ),
      );
    }

    final currentLesson = controller.currentLessonView;
    final isCompleted = currentLesson == null;

    return _CardShell(
      accent: accent,
      backgroundImage: _backgroundImage,
      onTap: isCompleted ? onPracticeInstead : onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.academyTitle,
              style: SalaVerdeType.bodyStrong().copyWith(fontSize: 13.5, letterSpacing: .3)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              isCompleted
                  ? AppStrings.continueLearningCompletedBody
                  : AppStrings.academyDescription,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaboratoryCard extends StatelessWidget {
  const _LaboratoryCard({required this.onPracticeNow});

  final VoidCallback onPracticeNow;

  static const _backgroundImage = 'assets/images/home/laboratory_card_bg.jpg';

  @override
  Widget build(BuildContext context) {
    const accent = SalaVerdeColors.feltGreenBright;
    return _CardShell(
      accent: accent,
      backgroundImage: _backgroundImage,
      onTap: onPracticeNow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.laboratoryTitle,
              style: SalaVerdeType.bodyStrong().copyWith(fontSize: 13.5, letterSpacing: .3)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              AppStrings.laboratoryDescription,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

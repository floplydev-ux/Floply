import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../../academy/academy_controller.dart';

/// El elemento más importante de la Home: responde "¿dónde estoy?" y "¿qué
/// debería hacer ahora?" a partir del estado real de [AcademyController]
/// (la misma instancia que usa la pantalla de Academia) — nunca calcula ni
/// inventa nada por su cuenta.
///
/// Cubre los estados reales posibles: cargando, usuario nuevo, con
/// progreso, y Academia completa. "Continuar" abre de verdad la lección
/// (`controller.openLesson`) antes de cambiar a la pestaña de Academia, así
/// que el usuario aparece exactamente donde el CTA prometía, no en el mapa.
///
/// **Fase 2 — migración visual a "Sala Verde"** (ver
/// `docs/design/FLOPLY_PHASE_2_HOME.md`): mismo estado, misma lógica,
/// mismos 4 branches (cargando/nuevo/progreso/completo) y las mismas 4
/// strings/callbacks que ya probaba `test/ui/home_screen_test.dart` — solo
/// cambia la capa visual (violeta → temperatura cálida de Academia
/// `feltGreen`, CTA en `brass`, tipografía Fraunces/Public Sans/IBM Plex
/// Mono). El gradiente decorativo de fondo se retira (regla 5 de
/// `FLOPLY_ANTI_GENERIC.md`: sin gradientes sin función física) en favor
/// de una superficie plana — el mismo lenguaje que ya usan las cards
/// tocables de esta pantalla.
class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.controller,
    required this.onGoToAcademy,
    required this.onGoToPractice,
  });

  final AcademyController controller;
  final VoidCallback onGoToAcademy;
  final VoidCallback onGoToPractice;

  void _continue() {
    final id = controller.currentLessonId;
    if (id != null) controller.openLesson(id);
    onGoToAcademy();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const _HeroShell(child: _LoadingBody());
        }

        final snapshot = controller.snapshot;
        final currentLesson = controller.currentLessonView;

        if (currentLesson == null) {
          return _HeroShell(
            child: _CompletedBody(
              onGoToPractice: onGoToPractice,
              completedLessons: snapshot.completedLessons,
              totalLessons: snapshot.totalLessons,
              masteredConcepts: snapshot.masteredConcepts,
            ),
          );
        }

        return _HeroShell(
          child: _ProgressBody(
            isNew: snapshot.completedLessons == 0,
            levelNumber: snapshot.currentLevelNumber,
            levelTitle: snapshot.currentLevelTitle,
            lessonTitle: currentLesson.lesson.title,
            lessonKindLabel: currentLesson.lesson.kind.label,
            percent: snapshot.percent,
            completedLessons: snapshot.completedLessons,
            totalLessons: snapshot.totalLessons,
            masteredConcepts: snapshot.masteredConcepts,
            onContinue: _continue,
          ),
        );
      },
    );
  }
}

/// Envoltorio visual común a los 4 estados: mismo alto mínimo (para que la
/// Home no salte al pasar de "cargando" a un estado con contenido).
/// Superficie plana `surfaceElevated` + sombra de contacto (elevación
/// nivel 1) — ya no un degradé de marca: es la misma card tocable que usan
/// las demás secciones de Home, reforzando "mismo sistema" en vez de un
/// tratamiento especial para esta única card.
class _HeroShell extends StatelessWidget {
  const _HeroShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      width: double.infinity,
      padding: const EdgeInsets.all(SalaVerdeSpace.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        color: SalaVerdeColors.surfaceElevated,
        border: Border.all(color: SalaVerdeColors.borderSubtle),
        boxShadow: SalaVerdeElevation.level1,
      ),
      child: child,
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: SalaVerdeColors.feltGreenBright,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.continueLearningLoadingBody,
            style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CompletedBody extends StatelessWidget {
  const _CompletedBody({
    required this.onGoToPractice,
    required this.completedLessons,
    required this.totalLessons,
    required this.masteredConcepts,
  });

  final VoidCallback onGoToPractice;
  final int completedLessons;
  final int totalLessons;
  final List<String> masteredConcepts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SalaVerdeColors.success.withValues(alpha: 0.18),
          ),
          child: const Icon(Icons.emoji_events_rounded,
              color: SalaVerdeColors.success, size: 24),
        ),
        const SizedBox(height: 14),
        Text(
          AppStrings.continueLearningCompletedTitle,
          style: SalaVerdeType.headline(),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.continueLearningCompletedBody,
          style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
        ),
        const SizedBox(height: 18),
        SvButtonPrimary(label: AppStrings.practiceNowLabel, onTap: onGoToPractice),
        _ProgressSummaryLine(
          completedLessons: completedLessons,
          totalLessons: totalLessons,
          masteredConcepts: masteredConcepts,
        ),
      ],
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.isNew,
    required this.levelNumber,
    required this.levelTitle,
    required this.lessonTitle,
    required this.lessonKindLabel,
    required this.percent,
    required this.completedLessons,
    required this.totalLessons,
    required this.masteredConcepts,
    required this.onContinue,
  });

  final bool isNew;
  final int levelNumber;
  final String levelTitle;
  final String lessonTitle;
  final String lessonKindLabel;
  final double percent;
  final int completedLessons;
  final int totalLessons;
  final List<String> masteredConcepts;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isNew
              ? AppStrings.continueLearningNewTitle
              : AppStrings.continueLearningEyebrow,
          style: SalaVerdeType.label(color: SalaVerdeColors.feltGreenBright),
        ),
        const SizedBox(height: 10),
        Text(
          AppStrings.academyLevelLabel(levelNumber, levelTitle),
          style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          lessonTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SalaVerdeType.headline(),
        ),
        const SizedBox(height: 4),
        Text(
          lessonKindLabel,
          style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SvProgressLinear(
                value: percent,
                color: SalaVerdeColors.feltGreenBright,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(percent * 100).round()}%',
              style: SalaVerdeType.numeric(color: SalaVerdeColors.feltGreenBright),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SvButtonPrimary(
          label: isNew
              ? AppStrings.continueLearningStartCta
              : AppStrings.continueLabel,
          onTap: onContinue,
        ),
        if (!isNew)
          _ProgressSummaryLine(
            completedLessons: completedLessons,
            totalLessons: totalLessons,
            masteredConcepts: masteredConcepts,
          ),
      ],
    );
  }
}

/// La información que antes vivía en `AcademyProgressCard` (retirada,
/// Fase 1 Bloque 1 P1-B): lecciones completadas/total y conceptos
/// dominados, como cierre de bajo énfasis del hero — nunca una segunda
/// barra de progreso ni un segundo bloque tappable, el % ya se mostró
/// arriba una sola vez.
class _ProgressSummaryLine extends StatelessWidget {
  const _ProgressSummaryLine({
    required this.completedLessons,
    required this.totalLessons,
    required this.masteredConcepts,
  });

  final int completedLessons;
  final int totalLessons;
  final List<String> masteredConcepts;

  @override
  Widget build(BuildContext context) {
    final mastered = masteredConcepts.isEmpty
        ? null
        : '${AppStrings.academyMasteredLabel}: ${masteredConcepts.join(", ")}';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.academyLessonsDone(completedLessons, totalLessons),
            style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.feltGreenBright)
                .copyWith(fontSize: 11.5),
          ),
          if (mastered != null) ...[
            const SizedBox(height: 2),
            Text(
              mastered,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)
                  .copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../engine/academy/academy_engine.dart';
import '../../../engine/academy/academy_progress.dart';
import '../../../engine/pedagogy/curriculum.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy_controller.dart';

/// Mapa de niveles de la Academia (fase `map`): encabezado + tira de
/// progreso + una tarjeta por nivel con sus lecciones.
///
/// **Fase 3 — migración visual a "Sala Verde"** (ver
/// `docs/design/FLOPLY_PHASE_3_ACADEMIA.md`): misma estructura, mismos
/// datos (`AcademyController.levels`/`snapshot`), mismos callbacks
/// (`onOpenLesson`), mismos labels de accesibilidad — solo cambia la capa
/// visual (violeta → temperatura de Academia `feltGreen`, `GlassCard` →
/// `SvSurfacePanel`/`SvTappableCard`, tipografía Fraunces/Public Sans/IBM
/// Plex Mono). `GlassCard` (`lib/widgets/glass_card.dart`) no se tocó —
/// era el único consumidor real fuera de su propia definición, así que
/// simplemente se dejó de usar acá en vez de migrarlo (queda disponible
/// para quien lo necesite después).
class LevelMap extends StatelessWidget {
  const LevelMap({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final levels = controller.levels;
    final snap = controller.snapshot;

    return LayoutBuilder(builder: (context, constraints) {
      final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AcademyHeader(),
            const SizedBox(height: 16),
            _ProgressStrip(snapshot: snap),
            if (controller.pendingReviewId != null) ...[
              const SizedBox(height: 14),
              _PendingReviewBanner(controller: controller),
            ],
            const SizedBox(height: 20),
            for (final level in levels) ...[
              _LevelCard(
                level: level,
                onOpenLesson: controller.openLesson,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      );
    });
  }
}

class _AcademyHeader extends StatelessWidget {
  const _AcademyHeader();

  @override
  Widget build(BuildContext context) {
    return const SvSectionHeader(
      icon: Icons.school_outlined,
      title: AppStrings.academyTitle,
      subtitle: AppStrings.academyHeaderSubtitle,
      variant: SvSectionHeaderVariant.academy,
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.snapshot});

  final AcademyProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return SvSurfacePanel(
      borderColor: SalaVerdeColors.feltGreenBright.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.academyLevelLabel(
                snapshot.currentLevelNumber, snapshot.currentLevelTitle),
            style: SalaVerdeType.bodyStrong(),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          SvProgressLinear(
            value: snapshot.percent,
            color: SalaVerdeColors.feltGreenBright,
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          Text(
            AppStrings.academyLessonsDone(
                snapshot.completedLessons, snapshot.totalLessons),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          if (snapshot.masteredConcepts.isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.xs),
            Text(
              '${AppStrings.academyMasteredLabel}: '
              '${snapshot.masteredConcepts.join(", ")}',
              style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner del mapa cuando hay un repaso acumulativo aprobado-pero-pendiente
/// (`AcademyController.pendingReviewId`): el checkpoint que lo habilita ya
/// se aprobó, pero el usuario todavía no hizo el repaso — típicamente
/// porque, al terminarlo, tocó "MÁS TARDE" en vez de hacerlo ahí mismo. Es
/// el único otro lugar (además del resultado del checkpoint) donde se
/// puede arrancar; sin esto, un repaso pospuesto quedaría inalcanzable.
class _PendingReviewBanner extends StatelessWidget {
  const _PendingReviewBanner({required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final reviewId = controller.pendingReviewId;
    if (reviewId == null) return const SizedBox.shrink();

    return SvSurfacePanel(
      borderColor: SalaVerdeColors.brassBright.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvCalloutAccent(
            eyebrow: controller.reviewTitle(reviewId),
            body: AppStrings.academyReviewBannerBody,
            color: SalaVerdeColors.brassBright,
            icon: Icons.history_edu_rounded,
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          SvButtonPrimary(
            label: AppStrings.academyStartReview,
            onTap: () => controller.startCumulativeReview(reviewId),
          ),
        ],
      ),
    );
  }
}

/// Label de accesibilidad (Fase 1, Bloque 2, P1-3) para un [LevelState] —
/// antes solo se comunicaba con color/ícono, invisible para un screen
/// reader. Sin cambios en Fase 3.
String _levelStateLabel(LevelState state) => switch (state) {
      LevelState.locked => AppStrings.academyStateLocked,
      LevelState.available => AppStrings.academyStateAvailable,
      LevelState.inProgress => AppStrings.academyStateInProgress,
      LevelState.completed => AppStrings.academyStateCompleted,
    };

/// Mismo propósito que [_levelStateLabel], para [LessonState].
String _lessonStateLabel(LessonState state) => switch (state) {
      LessonState.locked => AppStrings.academyStateLocked,
      LessonState.available => AppStrings.academyStateAvailable,
      LessonState.completed => AppStrings.academyStateCompleted,
    };

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.onOpenLesson});

  final AcademyLevelView level;
  final void Function(String lessonId) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final locked = level.state == LevelState.locked;
    final inProgress = level.state == LevelState.inProgress;

    return SvSurfacePanel(
      borderColor: locked
          ? SalaVerdeColors.borderSubtle
          : SalaVerdeColors.feltGreenBright.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fase 1, Bloque 2, P1-3: antes el estado del nivel (bloqueado/
          // disponible/en curso/completado) solo se comunicaba con color +
          // ícono — invisible para un screen reader. Un solo label
          // controlado (excludeSemantics) evita que además se anuncien
          // por separado los textos internos en un orden confuso. Sin
          // cambios de comportamiento en Fase 3.
          Semantics(
            label:
                '${AppStrings.academyLevelLabel(level.level.number, level.level.title)}. '
                '${_levelStateLabel(level.state)}.',
            excludeSemantics: true,
            child: Row(
              children: [
                _LevelBadge(number: level.level.number, state: level.state),
                const SizedBox(width: SalaVerdeSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.level.title.toUpperCase(),
                        style: SalaVerdeType.bodyStrong(
                          color: locked
                              ? SalaVerdeColors.textMuted
                              : SalaVerdeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.level.theme,
                        style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                      ),
                      // available e inProgress se veían idénticos (Fase 1,
                      // Bloque 2, P1-1) — el engine ya distinguía "nunca
                      // empezado" de "algo completado, no todo". Fase 3:
                      // el acento pasa de neonGreenBright (temperatura de
                      // Laboratorio, un mismatch semántico preexistente) a
                      // feltGreenBright (temperatura real de Academia).
                      if (inProgress) ...[
                        const SizedBox(height: SalaVerdeSpace.xs),
                        Text(
                          AppStrings.academyLevelInProgress(
                            level.lessons
                                .where(
                                    (l) => l.state == LessonState.completed)
                                .length,
                            level.lessons.length,
                          ),
                          style: SalaVerdeType.label(color: SalaVerdeColors.feltGreenBright)
                              .copyWith(fontSize: 10.5),
                        ),
                      ],
                    ],
                  ),
                ),
                if (level.state == LevelState.completed)
                  const Icon(Icons.verified_rounded,
                      color: SalaVerdeColors.success, size: 20),
              ],
            ),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          for (final lesson in level.lessons)
            _LessonRow(
              lesson: lesson,
              onTap: lesson.state == LessonState.locked
                  ? null
                  : () => onOpenLesson(lesson.lesson.id),
            ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.number, required this.state});

  final int number;
  final LevelState state;

  @override
  Widget build(BuildContext context) {
    final active = state != LevelState.locked;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Relleno plano, no degradé — FLOPLY_ANTI_GENERIC.md regla 5. Como
        // relleno de superficie, feltGreen base es correcto (no Bright,
        // que es para texto/ícono — ver "Principio de contraste por
        // contexto de uso").
        color: active ? SalaVerdeColors.feltGreen : SalaVerdeColors.surfaceElevated,
      ),
      child: state == LevelState.locked
          ? const Icon(Icons.lock_rounded, size: 16, color: SalaVerdeColors.textMuted)
          : Text(
              '$number',
              style: SalaVerdeType.numeric(size: 16, color: SalaVerdeColors.textPrimary),
            ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.onTap});

  final AcademyLessonView lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = lesson.lesson;
    final completed = lesson.state == LessonState.completed;
    final locked = lesson.state == LessonState.locked;

    final IconData icon;
    final Color iconColor;
    if (completed) {
      icon = Icons.check_circle_rounded;
      iconColor = SalaVerdeColors.success;
    } else if (locked) {
      icon = Icons.lock_outline_rounded;
      iconColor = SalaVerdeColors.textMuted;
    } else {
      icon = _kindIcon(l.kind);
      iconColor = SalaVerdeColors.feltGreenBright;
    }

    // Fase 1, Bloque 2, P1-3: el único diferenciador de estado hasta ahora
    // era el ícono (candado/check/tipo de lección) — invisible para un
    // screen reader. El label arma en palabras lo mismo que ya se ve. Sin
    // cambios de comportamiento/contenido en Fase 3.
    final scoreText = completed && lesson.progress.bestScore > 0
        ? ' ${AppStrings.academyScore((lesson.progress.bestScore * 100).round())}.'
        : '';
    final lockedHint = locked ? ' ${AppStrings.academyLockedLessonHint}' : '';
    final semanticLabel =
        '${l.title}. ${l.kind.label}. ${_lessonStateLabel(lesson.state)}.'
        '$scoreText$lockedHint';

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap ?? () {},
        child: Opacity(
          opacity: locked ? 0.5 : 1,
          child: Container(
            margin: const EdgeInsets.only(top: SalaVerdeSpace.sm),
            padding: const EdgeInsets.symmetric(horizontal: SalaVerdeSpace.md, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              color: SalaVerdeColors.surfaceElevated,
              border: Border.all(
                color: lesson.state == LessonState.available
                    ? SalaVerdeColors.feltGreenBright.withValues(alpha: 0.35)
                    : SalaVerdeColors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: iconColor),
                const SizedBox(width: SalaVerdeSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l.id}  ${l.title}',
                        style: SalaVerdeType.bodyStrong().copyWith(fontSize: 12.5),
                      ),
                      Text(
                        l.kind.label,
                        style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)
                            .copyWith(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                // Cifra real de rendimiento — firma tipográfica obligatoria
                // (FLOPLY_ANTI_GENERIC.md regla 12): antes era texto normal
                // (violetSoft), ahora IBM Plex Mono, la única familia
                // numérica del sistema.
                if (completed && lesson.progress.bestScore > 0)
                  Text(
                    '${(lesson.progress.bestScore * 100).round()}%',
                    style: SalaVerdeType.numeric(
                        size: 11, color: SalaVerdeColors.feltGreenBright),
                  ),
                if (!completed && !locked)
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: SalaVerdeColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _kindIcon(LessonKind kind) {
    switch (kind) {
      case LessonKind.theory:
        return Icons.menu_book_rounded;
      case LessonKind.basic:
        return Icons.school_rounded;
      case LessonKind.intermediate:
        return Icons.trending_up_rounded;
      case LessonKind.challenge:
        return Icons.bolt_rounded;
      case LessonKind.assessment:
        return Icons.workspace_premium_rounded;
    }
  }
}

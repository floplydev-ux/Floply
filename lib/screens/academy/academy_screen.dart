import 'package:flutter/material.dart';

import '../../engine/academy/academy_engine.dart';
import '../../engine/academy/academy_progress.dart';
import '../../engine/pedagogy/curriculum.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import 'academy_controller.dart';
import 'widgets/lesson_flow.dart';

/// Pantalla de la Academia: el recorrido pedagógico estructurado (niveles
/// 1–5). Reemplaza al placeholder "Próximamente" de esa pestaña.
///
/// La práctica libre sigue viviendo en el Laboratorio: la Academia es
/// *aprender y progresar*.
class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key, this.controller});

  final AcademyController? controller;

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  late final AcademyController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AcademyController();
    _ownsController = widget.controller == null;
    if (_controller.loading) _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return _controller.phase == AcademyPhase.map
                ? _MapView(controller: _controller)
                : LessonFlow(controller: _controller);
          },
        ),
      ),
    );
  }
}

// ================================================================
// Mapa de niveles
// ================================================================

class _MapView extends StatelessWidget {
  const _MapView({required this.controller});

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
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.violetPrimary.withValues(alpha: 0.18),
          ),
          child: const Icon(Icons.school_rounded,
              color: AppColors.violetBright, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.academyTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                AppStrings.academyHeaderSubtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.snapshot});

  final AcademyProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1140), Color(0xFF120C29)],
        ),
        border: Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.academyLevelLabel(
                snapshot.currentLevelNumber, snapshot.currentLevelTitle),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: snapshot.percent.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.violetBright,
                            AppColors.violetPrimary
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.academyLessonsDone(
                snapshot.completedLessons, snapshot.totalLessons),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          if (snapshot.masteredConcepts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${AppStrings.academyMasteredLabel}: '
              '${snapshot.masteredConcepts.join(", ")}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.onOpenLesson});

  final AcademyLevelView level;
  final void Function(String lessonId) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final locked = level.state == LevelState.locked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surface,
        border: Border.all(
          color: locked
              ? AppColors.surfaceBorder
              : AppColors.violetPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LevelBadge(number: level.level.number, state: level.state),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.level.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: locked
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.level.theme,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (level.state == LevelState.completed)
                const Icon(Icons.verified_rounded,
                    color: AppColors.violetBright, size: 20),
            ],
          ),
          const SizedBox(height: 12),
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
        gradient: active
            ? const LinearGradient(colors: AppColors.violetGradient)
            : null,
        color: active ? null : AppColors.surfaceElevated,
      ),
      child: state == LevelState.locked
          ? const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted)
          : Text(
              '$number',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
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
      iconColor = AppColors.violetBright;
    } else if (locked) {
      icon = Icons.lock_outline_rounded;
      iconColor = AppColors.textMuted;
    } else {
      icon = _kindIcon(l.kind);
      iconColor = AppColors.neonGreenBright;
    }

    return PressableScale(
      onTap: onTap ?? () {},
      child: Opacity(
        opacity: locked ? 0.5 : 1,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surfaceElevated,
            border: Border.all(
              color: lesson.state == LessonState.available
                  ? AppColors.neonGreen.withValues(alpha: 0.35)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l.id}  ${l.title}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      l.kind.label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (completed && lesson.progress.bestScore > 0)
                Text(
                  '${(lesson.progress.bestScore * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.violetSoft,
                  ),
                ),
              if (!completed && !locked)
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textMuted),
            ],
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

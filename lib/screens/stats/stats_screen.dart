import 'package:flutter/material.dart';

import '../../engine/academy/academy_engine.dart';
import '../../engine/academy/academy_progress.dart';
import '../../engine/concepts/mastery_bucket.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/concept_mastery_bar.dart';
import '../academy/academy_controller.dart';

/// Pantalla de Estadísticas — reemplaza el `ComingSoonScreen` del tab.
///
/// Puramente de lectura: no calcula nada que no exista ya. Lee
/// [AcademyController.snapshot]/`.levels`/`.knowledge` (mismos datos que
/// ya muestran `ContinueLearningCard`/`LevelMap`/`SessionSummary`, acá
/// reunidos en un solo lugar) — nunca un segundo cálculo de progreso.
///
/// Laboratorio queda con un estado vacío honesto a propósito: hoy
/// `LabSessionController.results`/`newEngineResults` viven solo en
/// memoria de la sesión en curso (se pierden al volver a
/// [LabPhase.idle] o al cerrar la app) — no hay historial persistido
/// que mostrar todavía. Inventar números acá sería peor que no
/// mostrar nada.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.controller});

  final AcademyController controller;

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
          animation: controller,
          builder: (context, _) {
            if (controller.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.violetSoft),
              );
            }
            return LayoutBuilder(builder: (context, constraints) {
              final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _StatsHeader(),
                    const SizedBox(height: 18),
                    _AcademySummaryCard(controller: controller),
                    const SizedBox(height: 16),
                    _LevelsCard(controller: controller),
                    const SizedBox(height: 16),
                    _ConceptMasteryCard(controller: controller),
                    const SizedBox(height: 16),
                    const _LaboratoryEmptyCard(),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

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
          child: const Icon(Icons.bar_chart_rounded,
              color: AppColors.violetBright, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.statsHeaderTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                AppStrings.statsHeaderSubtitle,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AcademySummaryCard extends StatelessWidget {
  const _AcademySummaryCard({required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    return _SectionCard(
      title: AppStrings.statsAcademySection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            AppColors.violetPrimary,
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
            '${AppStrings.academyLessonsDone(snapshot.completedLessons, snapshot.totalLessons)} '
            '· ${(snapshot.percent * 100).round()}%',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelsCard extends StatelessWidget {
  const _LevelsCard({required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.statsLevelsSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final level in controller.levels)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LevelRow(level: level),
            ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level});

  final AcademyLevelView level;

  @override
  Widget build(BuildContext context) {
    final locked = level.state == LevelState.locked;
    final completed = level.state == LevelState.completed;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: locked
                ? AppColors.surfaceElevated
                : AppColors.violetPrimary.withValues(alpha: 0.18),
          ),
          child: locked
              ? const Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted)
              : Text(
                  '${level.level.number}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.violetBright,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            level.level.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: locked ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: level.progress.clamp(0.0, 1.0),
                    child: Container(
                      color: completed
                          ? AppColors.violetBright
                          : AppColors.violetPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '${(level.progress * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConceptMasteryCard extends StatelessWidget {
  const _ConceptMasteryCard({required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final buckets = masteryBuckets(
      controller.knowledge,
      controller.engine.generator.practiceableConcepts,
    );
    return _SectionCard(
      title: AppStrings.statsConceptMasterySection,
      child: buckets.isEmpty
          ? const Text(
              AppStrings.statsConceptMasteryEmpty,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final bucket in buckets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ConceptMasteryBar(bucket: bucket),
                  ),
              ],
            ),
    );
  }
}

class _LaboratoryEmptyCard extends StatelessWidget {
  const _LaboratoryEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: AppStrings.statsLabSection,
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_rounded,
              color: AppColors.textMuted, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.statsLabEmptyTitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.statsLabEmptyBody,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../engine/academy/academy_engine.dart';
import '../../engine/academy/academy_progress.dart';
import '../../engine/concepts/mastery_bucket.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/concept_mastery_bar.dart';
import '../../widgets/sala_verde/floply_loading_indicator.dart';
import '../academy/academy_controller.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.loading) {
              return const Center(child: FloplyLoadingIndicator(size: 64));
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
            color: SalaVerdeColors.violet.withValues(alpha: 0.18),
          ),
          child: const Icon(Icons.bar_chart_rounded,
              color: SalaVerdeColors.violetBright, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.statsHeaderTitle,
                style: SalaVerdeType.title(),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.statsHeaderSubtitle,
                style: SalaVerdeType.caption(
                    color: SalaVerdeColors.textSecondary),
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
        borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
        color: SalaVerdeColors.surface,
        border: Border.all(color: SalaVerdeColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: SalaVerdeType.label(color: SalaVerdeColors.textMuted),
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
            style: SalaVerdeType.bodyStrong(),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: SalaVerdeColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: snapshot.percent.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SalaVerdeColors.violetBright,
                            SalaVerdeColors.violet,
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
            style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
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
                ? SalaVerdeColors.surfaceElevated
                : SalaVerdeColors.violet.withValues(alpha: 0.18),
          ),
          child: locked
              ? const Icon(Icons.lock_rounded,
                  size: 12, color: SalaVerdeColors.textMuted)
              : Text(
                  '${level.level.number}',
                  style: SalaVerdeType.label(
                      color: SalaVerdeColors.violetBright),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            level.level.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalaVerdeType.caption(
              color: locked
                  ? SalaVerdeColors.textMuted
                  : SalaVerdeColors.textPrimary,
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
                  Container(color: SalaVerdeColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: level.progress.clamp(0.0, 1.0),
                    child: Container(
                      color: completed
                          ? SalaVerdeColors.violetBright
                          : SalaVerdeColors.violet,
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
            style: SalaVerdeType.label(color: SalaVerdeColors.textMuted),
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
          ? Text(
              AppStrings.statsConceptMasteryEmpty,
              style: SalaVerdeType.caption(
                  color: SalaVerdeColors.textSecondary),
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
    return _SectionCard(
      title: AppStrings.statsLabSection,
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty_rounded,
              color: SalaVerdeColors.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.statsLabEmptyTitle,
                  style: SalaVerdeType.bodyStrong(),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.statsLabEmptyBody,
                  style: SalaVerdeType.caption(
                      color: SalaVerdeColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

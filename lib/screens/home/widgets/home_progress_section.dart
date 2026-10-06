import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../../academy/academy_controller.dart';
import '../../stats/stats_screen.dart';

/// "TU PROGRESO" — Academia con datos reales de
/// [AcademyController.snapshot] (mismo dato que ya usa `StatsScreen`,
/// nunca un segundo cálculo) y Laboratorio como acceso directo sin
/// números: no persiste historial entre sesiones todavía (ver
/// `PracticeRoomCard`), así que no hay "última práctica" real que
/// mostrar — mostrar un aviso honesto en vez de inventar un porcentaje.
///
/// Vive en `ProfileScreen` (se mudó del Home en el rediseño de la escena
/// de fondo): el nombre del archivo quedó igual a propósito, es el mismo
/// widget con los mismos datos, no una copia — mover el archivo también
/// no era necesario para este cambio.
class HomeProgressSection extends StatelessWidget {
  const HomeProgressSection({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.yourProgressLabel,
            style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary)),
        const SizedBox(height: SalaVerdeSpace.sm),
        Container(
          decoration: BoxDecoration(
            color: SalaVerdeColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (controller.loading) {
                return const Padding(
                  padding: EdgeInsets.all(SalaVerdeSpace.lg),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: SalaVerdeColors.violetBright),
                    ),
                  ),
                );
              }
              final snapshot = controller.snapshot;
              return Column(
                children: [
                  _ProgressRow(
                    icon: Icons.school_rounded,
                    accent: SalaVerdeColors.violetBright,
                    title: AppStrings.navAcademy,
                    body: AppStrings.academyLevelLabel(
                        snapshot.currentLevelNumber, snapshot.currentLevelTitle),
                    percent: snapshot.percent,
                    ctaLabel: AppStrings.continueLabel,
                    onTap: _continueAcademy,
                  ),
                  const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
                  _ProgressRow(
                    icon: Icons.fitness_center_rounded,
                    accent: SalaVerdeColors.feltGreenBright,
                    title: AppStrings.navLab,
                    body: AppStrings.homeLabProgressBody,
                    percent: null,
                    ctaLabel: AppStrings.practiceNowLabel,
                    onTap: onGoToLaboratory,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        SvTappableCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => StatsScreen(controller: controller)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: SalaVerdeColors.violetBright, size: 20),
              const SizedBox(width: SalaVerdeSpace.md),
              Expanded(
                child: Text(
                  AppStrings.homeSeeProgressDetails,
                  style: SalaVerdeType.bodyStrong(),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: SalaVerdeColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.percent,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final double? percent;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(SalaVerdeSpace.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.16)),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: SalaVerdeSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: SalaVerdeType.bodyStrong().copyWith(fontSize: 13.5)),
                  Text(body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SalaVerdeType.caption()),
                  if (percent != null) ...[
                    const SizedBox(height: 4),
                    SvProgressLinear(value: percent!, color: accent, height: 5),
                  ],
                ],
              ),
            ),
            const SizedBox(width: SalaVerdeSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                  border: Border.all(color: accent),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(ctaLabel,
                      style: SalaVerdeType.caption(color: accent)
                          .copyWith(fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

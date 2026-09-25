import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:poker_trainer/theme/app_colors.dart';
import 'package:poker_trainer/widgets/bottom_navigation.dart';
import 'package:poker_trainer/widgets/glass_card.dart';
import 'package:poker_trainer/widgets/home_link_card.dart';

/// Baseline visual (Fase 0) de los tres componentes "core" con más reuso
/// real medido en el inventario de arquitectura: `GlassCard`,
/// `AppBottomNavigation`, `HomeLinkCard`. Esto es una FOTO del estado
/// visual actual, no una certificación de que el diseño sea el correcto
/// (ver el criterio explícito de la Fase 0) — sirve para detectar cambios
/// visuales no intencionales en el ciclo de QA que viene después.
void main() {
  goldenTest(
    'GlassCard',
    fileName: 'glass_card',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 360),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: const ColoredBox(
            color: AppColors.background,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GlassCard(child: Text('Contenido de ejemplo')),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'gradient',
          child: const ColoredBox(
            color: AppColors.background,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GlassCard(
                gradient: LinearGradient(
                  colors: AppColors.violetCardDeepGradient,
                ),
                child: Text('Con gradiente'),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'AppBottomNavigation',
    fileName: 'app_bottom_navigation',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 390),
      children: [
        for (var i = 0; i < 5; i++)
          GoldenTestScenario(
            name: 'tab_${i}_activo',
            child: AppBottomNavigation(currentIndex: i, onTap: (_) {}),
          ),
      ],
    ),
  );

  goldenTest(
    'HomeLinkCard',
    fileName: 'home_link_card',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 360),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: ColoredBox(
            color: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HomeLinkCard(
                icon: Icons.insights_rounded,
                title: 'Tools',
                description: 'Calculadoras de póker',
                accentColor: AppColors.diamondBlue,
                onTap: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'muted',
          child: ColoredBox(
            color: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HomeLinkCard(
                icon: Icons.sports_rounded,
                title: 'Coach',
                description: 'Todavía no disponible',
                accentColor: AppColors.violetSoft,
                onTap: () {},
                muted: true,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

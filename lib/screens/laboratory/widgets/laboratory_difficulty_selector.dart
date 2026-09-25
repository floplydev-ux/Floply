import 'package:flutter/material.dart';

import '../../../engine/exercises/laboratory_difficulty.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';

/// Punto de entrada normal al Laboratorio: elegir qué tipo de
/// entrenamiento hacer, no elegir entre motores internos.
///
/// Puramente de presentación — no decide nada del motor, solo reporta
/// [onSelect] con la [LaboratoryDifficulty] elegida, o [onSelectCustom]
/// si el usuario prefiere configurar su propia sesión (Fase 8).
///
/// **Fase 7**: la rampa fácil/medio/experto usa los 3 colores semánticos
/// existentes (`success`/`warning`/`errorBright`) — es una escala de
/// intensidad real, no decoración, pero tampoco es la identidad de
/// sección (`steelBlue`): esa se reserva para el header/progreso/CTA
/// (ver `FLOPLY_PHASE_7_LABORATORIO.md` §D).
///
/// **Fase 8**: Custom se agrega como una 4ª tarjeta, deliberadamente con
/// el acento de identidad de sección (`steelBlueBright`) en vez de un 4º
/// color semántico — no representa un nivel de dificultad, representa
/// "vos decidís", así que no le corresponde un lugar en la rampa
/// fácil→difícil (ver `FLOPLY_PHASE_8_LABORATORIO_CUSTOM.md` §C).
class LaboratoryDifficultySelector extends StatelessWidget {
  const LaboratoryDifficultySelector({
    super.key,
    required this.onSelect,
    required this.onSelectCustom,
  });

  final ValueChanged<LaboratoryDifficulty> onSelect;
  final VoidCallback onSelectCustom;

  static const Map<LaboratoryDifficulty, Color> _accent = {
    LaboratoryDifficulty.easy: SalaVerdeColors.success,
    LaboratoryDifficulty.medium: SalaVerdeColors.warning,
    LaboratoryDifficulty.expert: SalaVerdeColors.errorBright,
  };

  static const Map<LaboratoryDifficulty, IconData> _icon = {
    LaboratoryDifficulty.easy: Icons.spa_rounded,
    LaboratoryDifficulty.medium: Icons.bolt_rounded,
    LaboratoryDifficulty.expert: Icons.whatshot_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.labChooseTitle, style: SalaVerdeType.title()),
        const SizedBox(height: SalaVerdeSpace.xs),
        Text(
          AppStrings.labChooseSubtitle,
          style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        for (final difficulty in LaboratoryDifficulty.values)
          Padding(
            padding: const EdgeInsets.only(bottom: SalaVerdeSpace.md),
            child: _OptionCard(
              label: difficulty.label,
              subtitle: difficulty.subtitle,
              description: difficulty.description,
              accentColor: _accent[difficulty]!,
              icon: _icon[difficulty]!,
              onTap: () => onSelect(difficulty),
            ),
          ),
        _OptionCard(
          label: AppStrings.labCustomLabel,
          subtitle: AppStrings.labCustomSubtitle,
          description: AppStrings.labCustomDescription,
          accentColor: SalaVerdeColors.steelBlueBright,
          icon: Icons.tune_rounded,
          onTap: onSelectCustom,
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final String description;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SalaVerdeSpace.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
          color: accentColor.withValues(alpha: 0.08),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: SalaVerdeSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: SalaVerdeSpace.sm,
                    children: [
                      Text(label, style: SalaVerdeType.bodyStrong(color: accentColor)),
                      Text(subtitle, style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: SalaVerdeSpace.xs),
                  Text(description, style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accentColor, size: 22),
          ],
        ),
      ),
    );
  }
}

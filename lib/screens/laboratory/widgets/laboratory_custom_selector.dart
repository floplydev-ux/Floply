import 'package:flutter/material.dart';

import '../../../engine/exercises/exercise_scenario.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Selector de la sesión Custom del Laboratorio (Fase 8): el usuario
/// elige QUÉ practicar (una o más familias reales de
/// [PreflopScenarioKind], en lenguaje de jugador vía
/// [PreflopScenarioKind.label]) y cuántos ejercicios, en vez de aceptar
/// una dificultad preconfigurada.
///
/// Itera [PreflopScenarioKind.values] — todas las familias que
/// `ExerciseScenarioBuilder` puede generar hoy, ninguna opción ficticia
/// (ver auditoría, `FLOPLY_PHASE_8_LABORATORIO_CUSTOM.md` §H/§I) —
/// crece sola cuando se agregan familias nuevas, sin tocar este widget.
/// Deliberadamente sin usar `surfaceReading`: esto es una decisión, no
/// una lectura (Sección 32 del prompt de fase).
class LaboratoryCustomSelector extends StatefulWidget {
  const LaboratoryCustomSelector({
    super.key,
    required this.onStart,
    required this.onBack,
  });

  /// Se llama solo cuando hay al menos una familia elegida — nunca con
  /// una selección vacía (ver [_canStart]).
  final void Function(Set<PreflopScenarioKind> kinds, int sessionLength) onStart;

  final VoidCallback onBack;

  @override
  State<LaboratoryCustomSelector> createState() => _LaboratoryCustomSelectorState();
}

const List<int> _kSessionLengthOptions = [5, 10, 15, 20];

class _LaboratoryCustomSelectorState extends State<LaboratoryCustomSelector> {
  final Set<PreflopScenarioKind> _selected = {};
  int _sessionLength = 10;

  bool get _canStart => _selected.isNotEmpty;

  void _toggle(PreflopScenarioKind kind) {
    setState(() {
      if (!_selected.add(kind)) _selected.remove(kind);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PressableScale(
              onTap: widget.onBack,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SalaVerdeColors.surfaceElevated,
                  border: Border.all(color: SalaVerdeColors.borderSubtle),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 18, color: SalaVerdeColors.textSecondary),
              ),
            ),
            const SizedBox(width: SalaVerdeSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.labCustomHeaderTitle, style: SalaVerdeType.title()),
                  Text(
                    AppStrings.labCustomHeaderSubtitle,
                    style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.xl),
        Text(
          AppStrings.labCustomAreasHeader,
          style: SalaVerdeType.label(color: SalaVerdeColors.textMuted),
        ),
        const SizedBox(height: SalaVerdeSpace.xs),
        Text(
          AppStrings.labCustomAreasSubtitle,
          style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        for (final kind in PreflopScenarioKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: SalaVerdeSpace.sm),
            child: _AreaTile(
              kind: kind,
              selected: _selected.contains(kind),
              onTap: () => _toggle(kind),
            ),
          ),
        const SizedBox(height: SalaVerdeSpace.md),
        Text(
          AppStrings.labCustomLengthHeader,
          style: SalaVerdeType.label(color: SalaVerdeColors.textMuted),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        Wrap(
          spacing: SalaVerdeSpace.sm,
          runSpacing: SalaVerdeSpace.sm,
          children: [
            for (final n in _kSessionLengthOptions)
              _LengthChip(
                value: n,
                selected: _sessionLength == n,
                onTap: () => setState(() => _sessionLength = n),
              ),
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.xl),
        Text(
          _canStart
              ? AppStrings.labCustomSummary(_selected.length, _sessionLength)
              : AppStrings.labCustomEmptyHint,
          textAlign: TextAlign.center,
          style: SalaVerdeType.bodyStrong(
            color: _canStart ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.textMuted,
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        SvButtonPrimary(
          label: AppStrings.labCustomStart,
          onTap: _canStart ? () => widget.onStart(_selected, _sessionLength) : null,
        ),
      ],
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({required this.kind, required this.selected, required this.onTap});

  final PreflopScenarioKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        label: kind.label,
        child: AnimatedContainer(
          duration: SalaVerdeMotion.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: SalaVerdeSpace.lg,
            vertical: SalaVerdeSpace.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
            color: selected
                ? SalaVerdeColors.steelBlueBright.withValues(alpha: 0.16)
                : SalaVerdeColors.surfaceElevated,
            border: Border.all(
              color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.borderSubtle,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.textMuted,
              ),
              const SizedBox(width: SalaVerdeSpace.md),
              Expanded(
                child: Text(
                  kind.label,
                  style: selected ? SalaVerdeType.bodyStrong() : SalaVerdeType.body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LengthChip extends StatelessWidget {
  const _LengthChip({required this.value, required this.selected, required this.onTap});

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: SalaVerdeSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
            color: selected
                ? SalaVerdeColors.steelBlueBright.withValues(alpha: 0.16)
                : SalaVerdeColors.surfaceElevated,
            border: Border.all(
              color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.borderSubtle,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            '$value',
            style: SalaVerdeType.numeric(
              size: 14,
              color: selected ? SalaVerdeColors.steelBlueBright : SalaVerdeColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

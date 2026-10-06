import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../widgets/tool_widgets.dart';
import 'range_explorer_controller.dart';
import 'widgets/range_matrix.dart';

/// Modo Construir (sección 16/17) — matriz editable: tocar una mano la
/// selecciona, los botones de frecuencia de abajo se la asignan. Nada de
/// drag-to-paint (se evaluó y se descartó por complejidad de gestos vs.
/// beneficio real: tocar-y-ajustar cubre el mismo caso de uso sin
/// gestión de `PanGestureRecognizer` para una herramienta que ya tiene
/// mucha superficie).
class RangeBuilderView extends StatefulWidget {
  const RangeBuilderView({super.key, required this.controller});

  final RangeExplorerController controller;

  @override
  State<RangeBuilderView> createState() => _RangeBuilderViewState();
}

class _RangeBuilderViewState extends State<RangeBuilderView> {
  static const _frequencySteps = [0.0, 0.25, 0.5, 0.75, 1.0];
  late final _nameController = TextEditingController(text: widget.controller.draftName);

  // Si otra herramienta ya cargó un borrador (p. ej. Blocker Explorer →
  // "Ver este rango en Construir"), arrancar directo en la matriz
  // editable en vez de mostrar los dos botones de inicio — ese borrador
  // ya "empezó", no tiene sentido pedir de nuevo el punto de partida.
  late bool _started = widget.controller.draftFrequencies.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _start(void Function() startDraft) {
    startDraft();
    _nameController.text = widget.controller.draftName;
    setState(() => _started = true);
  }

  Future<void> _save() async {
    final c = widget.controller;
    if (c.draftFrequencies.isEmpty || _nameController.text.trim().isEmpty) return;
    await c.saveRange(
      name: _nameController.text.trim(),
      frequencies: Map.of(c.draftFrequencies),
      basedOnOfficialId: c.draftBasedOnOfficialId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.rangesBuilderSavedConfirmation)),
    );
    setState(() {
      _started = false;
      _nameController.clear();
    });
    c.startDraftFromScratch();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (!_started) {
      return ToolCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SvButtonPrimary(
              label: AppStrings.rangesBuilderStartOfficial,
              accent: kToolAccent,
              onTap: () => _start(c.startDraftFromOfficial),
            ),
            const SizedBox(height: SalaVerdeSpace.sm),
            SvButtonSecondary(
              label: AppStrings.rangesBuilderStartScratch,
              onTap: () => _start(c.startDraftFromScratch),
            ),
          ],
        ),
      );
    }

    final draft = c.draftRange;
    final selected = c.selectedNotation;
    final selectedFrequency = selected != null ? draft.frequencyOf(selected) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolTextField(
          label: AppStrings.rangesBuilderNameLabel,
          controller: _nameController,
          hintText: AppStrings.rangesBuilderNameHint,
          onChanged: () => c.setDraftName(_nameController.text),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        ToolCard(
          child: RangeMatrix(
            range: draft,
            selected: selected,
            onCellTap: c.selectCell,
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        if (selected == null)
          const ToolEmptyState(
            message: AppStrings.rangesBuilderEmptyHint,
            icon: Icons.touch_app_rounded,
          )
        else
          ToolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ToolSectionLabel(
                  '${AppStrings.rangesBuilderFrequencyLabel}: $selected',
                  color: kToolAccent,
                ),
                const SizedBox(height: SalaVerdeSpace.sm),
                Wrap(
                  spacing: SalaVerdeSpace.sm,
                  runSpacing: SalaVerdeSpace.sm,
                  children: [
                    for (final step in _frequencySteps)
                      ToolModeChip(
                        label: '${(step * 100).round()}%',
                        active: selectedFrequency == step ||
                            (step == 0.0 && (selectedFrequency ?? 0) <= 0),
                        onTap: () => c.setDraftFrequency(selected, step),
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: SalaVerdeSpace.lg),
        Row(
          children: [
            Expanded(
              child: SvButtonSecondary(
                label: AppStrings.rangesBuilderClear,
                onTap: c.draftFrequencies.isEmpty ? null : c.clearDraft,
              ),
            ),
            const SizedBox(width: SalaVerdeSpace.sm),
            Expanded(
              child: SvButtonPrimary(
                label: AppStrings.rangesBuilderSave,
                accent: kToolAccent,
                onTap: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../engine/poker/combos/combo_engine.dart';
import '../../../../engine/poker/hole_cards.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../../widgets/tool_widgets.dart';
import '../range_explorer_controller.dart';

/// Detalle de una celda (sección 10/11/12/13) como bottom sheet — mismo
/// estilo que `ToolExplainerContent`'s sheet (`SalaVerdeRadius.sheet`,
/// `SalaVerdeColors.surface`). Muestra combos reales (`ComboEngine`,
/// nunca inventados) antes y después del board si hay uno cargado, y un
/// acceso directo a Blocker Explorer con la mano/board ya cargados.
Future<void> showRangeDetailSheet(
  BuildContext context, {
  required RangeExplorerController controller,
  required String notation,
  required VoidCallback onAnalyzeBlockers,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _RangeDetailSheet(
      controller: controller,
      notation: notation,
      onAnalyzeBlockers: onAnalyzeBlockers,
    ),
  );
}

class _RangeDetailSheet extends StatelessWidget {
  const _RangeDetailSheet({
    required this.controller,
    required this.notation,
    required this.onAnalyzeBlockers,
  });

  final RangeExplorerController controller;
  final String notation;
  final VoidCallback onAnalyzeBlockers;

  @override
  Widget build(BuildContext context) {
    final frequency = controller.activeRange.frequencyOf(notation);
    final handClass = HandClass.parse(notation);
    final board = controller.boardCards;
    final combosNoBoard = ComboEngine.combosForNotation(notation);
    final combosWithBoard =
        board.isEmpty ? combosNoBoard : ComboEngine.combosForNotation(notation, deadCards: board);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SalaVerdeRadius.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.rangesCellHandLabel,
                      value: notation,
                      big: true,
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.rangesCellFrequencyLabel,
                      value: '${(frequency * 100).toStringAsFixed(0)}%',
                      color: kToolAccent,
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.rangesCellCombosLabel,
                      value: '${handClass.combos}',
                      color: SalaVerdeColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
              const SizedBox(height: SalaVerdeSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: ToolSectionLabel(
                      board.isEmpty
                          ? AppStrings.rangesCellCombosLabel
                          : AppStrings.rangesCellCombosAvailableLabel,
                    ),
                  ),
                  if (board.isNotEmpty)
                    Text(
                      '${combosWithBoard.length}/${combosNoBoard.length}',
                      style: SalaVerdeType.numeric(size: 13, color: kToolAccent),
                    ),
                ],
              ),
              const SizedBox(height: SalaVerdeSpace.sm),
              if (combosWithBoard.isEmpty)
                Text(
                  AppStrings.rangesCellCombosBlockedLabel,
                  style: SalaVerdeType.caption(color: SalaVerdeColors.errorBright),
                )
              else
                Wrap(
                  spacing: SalaVerdeSpace.sm,
                  runSpacing: SalaVerdeSpace.sm,
                  children: [
                    for (final combo in combosWithBoard) _ComboChip(combo: combo),
                  ],
                ),
              const SizedBox(height: SalaVerdeSpace.lg),
              SizedBox(
                width: double.infinity,
                child: SvButtonSecondary(
                  label: AppStrings.rangesAnalyzeBlockers,
                  onTap: () {
                    Navigator.of(context).pop();
                    onAnalyzeBlockers();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.combo});

  final HoleCards combo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        color: SalaVerdeColors.surfaceElevated,
        border: Border.all(color: SalaVerdeColors.borderSubtle),
      ),
      child: Text(combo.pretty, style: SalaVerdeType.numeric(size: 13)),
    );
  }
}

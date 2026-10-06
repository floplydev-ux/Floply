import 'package:flutter/material.dart';

import '../../../engine/poker/position.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../equity_calculator_screen.dart';
import '../widgets/tool_widgets.dart';
import 'range_explorer_controller.dart';
import 'widgets/range_matrix.dart';

/// Range Compare (sección 19) — el rango activo de Explorar contra un
/// segundo rango (oficial o propio). La comparación se dibuja como
/// overlay sobre la MISMA matriz (sección 19: "no hace falta una
/// visualización compleja si una comparación visual sobre la matriz es
/// suficiente"), no un widget nuevo de diff.
class RangeCompareView extends StatelessWidget {
  const RangeCompareView({super.key, required this.controller});

  final RangeExplorerController controller;

  @override
  Widget build(BuildContext context) {
    final comparison = controller.comparison;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToolSectionLabel('${controller.officialRangeLabel} ${AppStrings.rangesCompareWith}'),
              const SizedBox(height: SalaVerdeSpace.sm),
              Wrap(
                spacing: SalaVerdeSpace.sm,
                runSpacing: SalaVerdeSpace.sm,
                children: [
                  for (final position in Position.openers)
                    if (position != controller.context.position)
                      ToolModeChip(
                        label: '${position.abbreviation} Open',
                        active: controller.compareTargetPosition == position,
                        onTap: () => controller.setCompareTargetPosition(position),
                      ),
                  for (final saved in controller.savedRanges)
                    ToolModeChip(
                      label: saved.name,
                      active: controller.compareTargetSavedId == saved.id,
                      onTap: () => controller.setCompareTargetSaved(saved.id),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        if (comparison == null)
          const ToolEmptyState(
            message: AppStrings.rangesCompareEmpty,
            icon: Icons.compare_arrows_rounded,
          )
        else ...[
          ToolCard(
            child: RangeMatrix(
              range: controller.activeRange,
              selected: controller.selectedNotation,
              onCellTap: controller.selectCell,
              comparison: comparison,
            ),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _CompareLegendItem(
                color: SalaVerdeColors.success,
                label: '${AppStrings.rangesCompareLegendAdded} (${comparison.addedCount})',
              ),
              _CompareLegendItem(
                color: SalaVerdeColors.errorBright,
                label: '${AppStrings.rangesCompareLegendRemoved} (${comparison.removedCount})',
              ),
              _CompareLegendItem(
                color: SalaVerdeColors.warning,
                label: '${AppStrings.rangesCompareLegendChanged} (${comparison.changedCount})',
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          SizedBox(
            width: double.infinity,
            child: SvButtonSecondary(
              label: AppStrings.blockerViewEquity,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EquityCalculatorScreen(
                  initialHeroRangeTokens:
                      controller.activeRange.frequencies.keys.toList(),
                  initialVillainRangeTokens:
                      controller.compareTargetRange!.frequencies.keys.toList(),
                  initialBoard: controller.boardCards,
                ),
              )),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompareLegendItem extends StatelessWidget {
  const _CompareLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
      ],
    );
  }
}

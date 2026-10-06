import 'package:flutter/material.dart';

import '../../../../l10n/app_strings.dart';
import '../../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/tool_widgets.dart';
import '../range_filters.dart';

/// Filtros de la matriz (sección 15) — colapsados por defecto (arranca
/// cerrado) para no mostrar 15 controles de entrada: la complejidad
/// aparece solo cuando el usuario la pide (sección 4).
class RangeFiltersBar extends StatefulWidget {
  const RangeFiltersBar({super.key, required this.filters, required this.onChanged});

  final RangeFilters filters;
  final ValueChanged<RangeFilters> onChanged;

  @override
  State<RangeFiltersBar> createState() => _RangeFiltersBarState();
}

class _RangeFiltersBarState extends State<RangeFiltersBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.filters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less_rounded : Icons.tune_rounded,
                size: 18,
                color: f.isEmpty ? SalaVerdeColors.textSecondary : kToolAccent,
              ),
              const SizedBox(width: SalaVerdeSpace.xs),
              Text(
                AppStrings.rangesFiltersTitle,
                style: SalaVerdeType.label(
                  color: f.isEmpty ? SalaVerdeColors.textSecondary : kToolAccent,
                ),
              ),
              if (!f.isEmpty) ...[
                const SizedBox(width: SalaVerdeSpace.xs),
                GestureDetector(
                  onTap: () => widget.onChanged(const RangeFilters()),
                  child: Text(
                    AppStrings.rangesFiltersClear,
                    style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: SalaVerdeSpace.sm),
          _FilterRow(
            label: AppStrings.rangesFiltersType,
            children: [
              for (final t in RangeTypeFilter.values)
                ToolModeChip(
                  label: t.label,
                  active: f.types.contains(t),
                  onTap: () => widget.onChanged(f.toggleType(t)),
                ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          _FilterRow(
            label: AppStrings.rangesFiltersAction,
            children: [
              for (final a in RangeActionFilter.values)
                ToolModeChip(
                  label: a.label,
                  active: f.actions.contains(a),
                  onTap: () => widget.onChanged(f.toggleAction(a)),
                ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          _FilterRow(
            label: AppStrings.rangesFiltersFrequency,
            children: [
              for (final b in RangeFrequencyBucket.values)
                ToolModeChip(
                  label: b.label,
                  active: f.frequencyBuckets.contains(b),
                  onTap: () => widget.onChanged(f.toggleFrequency(b)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)),
        const SizedBox(height: 4),
        Wrap(spacing: SalaVerdeSpace.xs, runSpacing: SalaVerdeSpace.xs, children: children),
      ],
    );
  }
}

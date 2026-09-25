import 'package:flutter/material.dart';

import '../../engine/poker/card.dart';
import '../../engine/poker/hole_cards.dart';
import '../../engine/poker/position.dart';
import '../../engine/strategy/hand_range.dart';
import '../../engine/strategy/opening_ranges.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import 'widgets/tool_widgets.dart';

/// Range Explorer — quinta y última herramienta de Tools V1 (Rangos).
///
/// A diferencia de las otras calculadoras (entrada de texto/número), acá
/// la entrada es elegir una posición y la salida es visual: la grilla
/// clásica de 13x13 de rangos de póker. Todo el dato sale de
/// [OpeningRanges] (ya migrado a JSON, ver `opening_ranges.dart`) — esta
/// pantalla no declara ningún rango propio, solo lo dibuja.
///
/// Orden de la grilla construido con la misma fórmula que
/// [HandClass.all] (fila/columna por rango de A a 2): diagonal = pares,
/// triángulo superior-derecho = suited, triángulo inferior-izquierdo =
/// offsuit. Deliberado: si algún día `HandClass.all()` cambia de orden,
/// esta pantalla sigue siendo consistente porque usa la misma fórmula,
/// no un orden hardcodeado aparte.
class RangeExplorerScreen extends StatefulWidget {
  const RangeExplorerScreen({super.key});

  @override
  State<RangeExplorerScreen> createState() => _RangeExplorerScreenState();
}

class _RangeExplorerScreenState extends State<RangeExplorerScreen> {
  Position _position = Position.btn;
  String? _selectedNotation;

  static final List<Rank> _ranks = Rank.highToLow;

  @override
  Widget build(BuildContext context) {
    final range = OpeningRanges.forPosition(_position);
    final isBb = _position == Position.bb;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ToolHeader(
                    icon: Icons.grid_on_rounded,
                    accentColor: AppColors.gold,
                    title: AppStrings.toolsRangesTitle,
                    subtitle: AppStrings.toolsRangesCalculatorSubtitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 20),
                  _PositionSelector(
                    selected: _position,
                    onSelected: (position) {
                      setState(() {
                        _position = position;
                        _selectedNotation = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isBb)
                    const ToolCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.rangesBbTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            AppStrings.rangesBbBody,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _SummaryCard(position: _position, range: range),
                    const SizedBox(height: 16),
                    ToolCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RangeGrid(
                            ranks: _ranks,
                            range: range,
                            selected: _selectedNotation,
                            onCellTap: (notation) =>
                                setState(() => _selectedNotation = notation),
                          ),
                          const SizedBox(height: 12),
                          const _Legend(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedNotation != null)
                      _DetailCard(
                        notation: _selectedNotation!,
                        frequency: range.frequencyOf(_selectedNotation!),
                      )
                    else
                      const Text(
                        AppStrings.rangesTapHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PositionSelector extends StatelessWidget {
  const _PositionSelector({required this.selected, required this.onSelected});

  final Position selected;
  final ValueChanged<Position> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final position in Position.values)
          _PositionChip(
            position: position,
            active: position == selected,
            onTap: () => onSelected(position),
          ),
      ],
    );
  }
}

class _PositionChip extends StatelessWidget {
  const _PositionChip({
    required this.position,
    required this.active,
    required this.onTap,
  });

  final Position position;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? AppColors.gold.withValues(alpha: 0.18)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: active
                ? AppColors.gold
                : AppColors.surfaceBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          position.abbreviation,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: active ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.position, required this.range});

  final Position position;
  final HandRange range;

  @override
  Widget build(BuildContext context) {
    return ToolCard(
      child: Row(
        children: [
          Expanded(
            child: ToolResultStat(
              label: AppStrings.rangesPositionLabel,
              value: position.fullName,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: ToolResultStat(
              label: AppStrings.rangesSizingLabel,
              value: '${formatToolNumber(OpeningRanges.sizingFor(position))} BB',
              color: AppColors.gold,
            ),
          ),
          Expanded(
            child: ToolResultStat(
              label: AppStrings.rangesPercentLabel,
              value: '${range.percentOfAllHands.toStringAsFixed(1)}%',
              color: AppColors.neonGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeGrid extends StatelessWidget {
  const _RangeGrid({
    required this.ranks,
    required this.range,
    required this.selected,
    required this.onCellTap,
  });

  final List<Rank> ranks;
  final HandRange range;
  final String? selected;
  final ValueChanged<String> onCellTap;

  static String _notationAt(List<Rank> ranks, int row, int col) {
    if (row == col) {
      final r = ranks[row];
      return '${r.letter}${r.letter}';
    }
    if (row < col) {
      return '${ranks[row].letter}${ranks[col].letter}s';
    }
    return '${ranks[col].letter}${ranks[row].letter}o';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.count(
        crossAxisCount: ranks.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        children: [
          for (var row = 0; row < ranks.length; row++)
            for (var col = 0; col < ranks.length; col++)
              _RangeCell(
                notation: _notationAt(ranks, row, col),
                frequency: range.frequencyOf(_notationAt(ranks, row, col)),
                isSelected: selected == _notationAt(ranks, row, col),
                onTap: onCellTap,
              ),
        ],
      ),
    );
  }
}

class _RangeCell extends StatelessWidget {
  const _RangeCell({
    required this.notation,
    required this.frequency,
    required this.isSelected,
    required this.onTap,
  });

  final String notation;
  final double frequency;
  final bool isSelected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color textColor;
    if (frequency <= 0) {
      background = AppColors.surfaceElevated;
      textColor = AppColors.textMuted;
    } else if (frequency >= 1.0) {
      background = AppColors.gold;
      textColor = AppColors.background;
    } else {
      background = AppColors.gold.withValues(alpha: 0.35 + frequency * 0.35);
      textColor = AppColors.background;
    }

    return GestureDetector(
      onTap: () => onTap(notation),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: AppColors.diamondBlue, width: 2)
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Text(
              notation,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        const _LegendItem(
            color: AppColors.gold, label: AppStrings.rangesLegendFull),
        _LegendItem(
          color: AppColors.gold.withValues(alpha: 0.5),
          label: AppStrings.rangesLegendMixed,
        ),
        const _LegendItem(
          color: AppColors.surfaceElevated,
          label: AppStrings.rangesLegendNone,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.notation, required this.frequency});

  final String notation;
  final double frequency;

  @override
  Widget build(BuildContext context) {
    final handClass = HandClass.parse(notation);
    return ToolCard(
      gradientColors: const [Color(0xFF3A2E12), Color(0xFF241B0A)],
      borderColor: AppColors.gold.withValues(alpha: 0.4),
      child: Row(
        children: [
          Expanded(
            child: ToolResultStat(
              label: AppStrings.rangesCellHandLabel,
              value: notation,
              big: true,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: ToolResultStat(
              label: AppStrings.rangesCellFrequencyLabel,
              value: '${(frequency * 100).toStringAsFixed(0)}%',
              color: AppColors.gold,
            ),
          ),
          Expanded(
            child: ToolResultStat(
              label: AppStrings.rangesCellCombosLabel,
              value: '${handClass.combos}',
              color: AppColors.neonGreen,
            ),
          ),
        ],
      ),
    );
  }
}

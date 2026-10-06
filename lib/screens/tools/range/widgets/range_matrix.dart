import 'package:flutter/material.dart';

import '../../../../engine/poker/card.dart';
import '../../../../engine/strategy/hand_range.dart';
import '../../../../engine/strategy/range_comparison.dart';
import '../../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../../theme/sala_verde/sala_verde_typography.dart';
import '../../widgets/tool_widgets.dart';
import '../range_filters.dart';

/// La grilla 13×13 — corazón visual de Rangos (sección 8). Extraída y
/// ampliada de la versión V1: ahora entiende filtros (atenúa lo que no
/// matchea) y una comparación opcional (contornea agregadas/quitadas/
/// cambiadas), sin dejar de ser la misma grilla de siempre para el caso
/// simple (un rango, sin filtros, sin comparación).
class RangeMatrix extends StatelessWidget {
  const RangeMatrix({
    super.key,
    required this.range,
    required this.selected,
    required this.onCellTap,
    this.filters = const RangeFilters(),
    this.comparison,
  });

  final HandRange range;
  final String? selected;
  final ValueChanged<String> onCellTap;
  final RangeFilters filters;

  /// Si no es null, cada celda se contornea según
  /// `RangeComparison.diffOf(notation)` (agregada/quitada/cambiada).
  final RangeComparison? comparison;

  static final List<Rank> _ranks = Rank.highToLow;

  static String notationAt(List<Rank> ranks, int row, int col) {
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
        crossAxisCount: _ranks.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        children: [
          for (var row = 0; row < _ranks.length; row++)
            for (var col = 0; col < _ranks.length; col++)
              Builder(builder: (context) {
                final notation = notationAt(_ranks, row, col);
                final frequency = range.frequencyOf(notation);
                return _RangeCell(
                  notation: notation,
                  frequency: frequency,
                  isSelected: selected == notation,
                  isDimmed: !filters.isEmpty && !filters.matches(notation, frequency),
                  diff: comparison?.diffOf(notation),
                  onTap: onCellTap,
                );
              }),
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
    required this.isDimmed,
    required this.diff,
    required this.onTap,
  });

  final String notation;
  final double frequency;
  final bool isSelected;
  final bool isDimmed;
  final RangeHandDiff? diff;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color textColor;
    if (frequency <= 0) {
      background = SalaVerdeColors.surfaceElevated;
      textColor = SalaVerdeColors.textMuted;
    } else if (frequency >= 1.0) {
      background = SalaVerdeColors.success;
      textColor = SalaVerdeColors.background;
    } else {
      background = SalaVerdeColors.success.withValues(alpha: 0.35 + frequency * 0.35);
      textColor = SalaVerdeColors.background;
    }

    Color? diffBorder;
    if (diff != null) {
      if (diff!.isAdded) {
        diffBorder = SalaVerdeColors.success;
      } else if (diff!.isRemoved) {
        diffBorder = SalaVerdeColors.errorBright;
      } else if (diff!.isFrequencyChanged) {
        diffBorder = SalaVerdeColors.warning;
      }
    }

    return GestureDetector(
      onTap: () => onTap(notation),
      child: Opacity(
        opacity: isDimmed ? 0.28 : 1.0,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(3),
            border: isSelected
                ? Border.all(color: kToolAccent, width: 2)
                : diffBorder != null
                    ? Border.all(color: diffBorder, width: 2)
                    : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Text(
                notation,
                style: SvMonoStyles.technicalValue.copyWith(
                  fontSize: 9,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

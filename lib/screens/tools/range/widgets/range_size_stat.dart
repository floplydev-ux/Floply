import 'package:flutter/material.dart';

import '../../../../engine/strategy/hand_range.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/tool_widgets.dart';

/// "Range 18.4% / Combos 242/1326" con un toggle entre las dos vistas
/// (sección 14) — ambas salen del mismo `HandRange` real, sin aproximar
/// nada (`comboCount`/`percentOfAllHands` ya hacen combinatoria exacta).
class RangeSizeStat extends StatefulWidget {
  const RangeSizeStat({super.key, required this.range});

  final HandRange range;

  @override
  State<RangeSizeStat> createState() => _RangeSizeStatState();
}

class _RangeSizeStatState extends State<RangeSizeStat> {
  bool _showCombos = false;

  @override
  Widget build(BuildContext context) {
    final combos = widget.range.comboCount.round();
    final percent = widget.range.percentOfAllHands;
    return GestureDetector(
      onTap: () => setState(() => _showCombos = !_showCombos),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ToolResultStat(
            label: AppStrings.rangesRangeLabel,
            value: _showCombos ? '$combos/1326' : '${percent.toStringAsFixed(1)}%',
            color: SalaVerdeColors.success,
          ),
          const SizedBox(width: SalaVerdeSpace.sm),
          const Icon(Icons.swap_horiz_rounded, size: 16, color: SalaVerdeColors.textMuted),
        ],
      ),
    );
  }
}

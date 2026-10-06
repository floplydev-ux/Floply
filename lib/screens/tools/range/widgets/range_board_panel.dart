import 'package:flutter/material.dart';

import '../../../../l10n/app_strings.dart';
import '../../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/card_situation.dart';
import '../../widgets/tool_widgets.dart';
import '../range_explorer_controller.dart';

/// Board opcional (sección 12) — mismo `CardGroupField` que ya usa
/// Blocker Explorer, sin un picker paralelo. Preflop/Flop/Turn/River
/// (sección 24) es solo una etiqueta derivada de cuántas cartas hay, no
/// una acción postflop inventada.
class RangeBoardPanel extends StatelessWidget {
  const RangeBoardPanel({super.key, required this.controller});

  final RangeExplorerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.board,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.rangesBoardLabel,
                  style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kToolAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                ),
                child: Text(
                  controller.streetLabel,
                  style: SalaVerdeType.caption(color: kToolAccent)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          CardGroupField(controller: controller.board, groupId: 'board'),
        ],
      ),
    );
  }
}

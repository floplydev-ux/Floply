import 'package:flutter/material.dart';

import '../../../../engine/poker/position.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/tool_widgets.dart';
import '../range_explorer_controller.dart';

/// El rango nunca aparece aislado (sección 5): breadcrumb con el
/// contexto fijo ("6-max · 100 BB · Cash · Open Raise") + el selector de
/// posición (único eje realmente interactivo hoy) + una insignia que
/// distingue un rango oficial de FLOPly de uno propio abierto desde Mis
/// Rangos (sección 18).
class RangeContextBar extends StatelessWidget {
  const RangeContextBar({super.key, required this.controller});

  final RangeExplorerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                controller.context.breadcrumb,
                style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
              ),
            ),
            _SourceBadge(controller: controller),
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        Wrap(
          spacing: SalaVerdeSpace.sm,
          runSpacing: SalaVerdeSpace.sm,
          children: [
            for (final position in Position.values)
              ToolModeChip(
                label: position.abbreviation,
                active: position == controller.context.position,
                onTap: () => controller.setPosition(position),
              ),
          ],
        ),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.controller});

  final RangeExplorerController controller;

  @override
  Widget build(BuildContext context) {
    final isOfficial = controller.isViewingOfficial;
    final color = isOfficial ? kToolAccent : SalaVerdeColors.brassBright;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isOfficial ? AppStrings.rangesOfficialBadge : AppStrings.rangesViewingSaved,
        style: SalaVerdeType.caption(color: color).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

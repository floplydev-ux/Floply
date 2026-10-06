import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../tools/widgets/tool_widgets.dart' show kToolAccent;
import 'home_feature_banner.dart';

/// Puerta de entrada a Herramientas en el Home — a todo el ancho, debajo
/// de la fila Academia/Campo de Entrenamiento (esa fila no cambia: sigue
/// lado a lado). Un único bloque principal (`HomeFeatureBanner`, mismo
/// formato que [HomeCoachBanner]): la selección de las 6 herramientas
/// individuales sigue viviendo dentro de `ToolsScreen`, acá solo quedan
/// listadas en chico como referencia, sin ser tap targets propios — todo
/// el banner es un único tap target.
class HomeToolsBanner extends StatelessWidget {
  const HomeToolsBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _backgroundImage = 'assets/images/home/tools_banner_bg.jpg';

  static const _tools = [
    (Icons.grid_on_rounded, 'Rangos'),
    (Icons.pie_chart_rounded, 'Equity'),
    (Icons.percent_rounded, 'Pot Odds'),
    (Icons.query_stats_rounded, 'EV'),
    (Icons.style_rounded, 'Combos'),
    (Icons.block_rounded, 'Blockers'),
  ];

  @override
  Widget build(BuildContext context) {
    return HomeFeatureBanner(
      accent: kToolAccent,
      title: AppStrings.toolsTitle,
      description: AppStrings.toolsBannerDescription,
      backgroundImage: _backgroundImage,
      onTap: onTap,
      footer: Wrap(
        spacing: SalaVerdeSpace.md,
        runSpacing: 6,
        children: [
          for (final (icon, label) in _tools) _ToolChip(icon: icon, label: label),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: SalaVerdeColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)
                .copyWith(fontSize: 10.5)),
      ],
    );
  }
}

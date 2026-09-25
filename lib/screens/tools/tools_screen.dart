import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home_link_card.dart';
import 'blocker_explorer_screen.dart';
import 'combo_calculator_screen.dart';
import 'equity_calculator_screen.dart';
import 'ev_calculator_screen.dart';
import 'pot_odds_calculator_screen.dart';
import 'range_explorer_screen.dart';

/// Hub de Tools — reemplaza el `ComingSoonScreen` al que apuntaba la
/// tarjeta de Home. Tools V1 completo (Pot Odds, Equity, EV, Combos,
/// Rangos) más Blockers de Tools V2, todas calculadoras reales sobre el
/// motor (`PotOddsEngine`, `EquityEngine`, `EVEngine`, `ComboEngine`,
/// `OpeningRanges`) — ninguna entrada deshabilitada.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 20),
                  HomeLinkCard(
                    icon: Icons.calculate_rounded,
                    title: AppStrings.toolsPotOddsTitle,
                    description: AppStrings.toolsPotOddsCardDescription,
                    accentColor: AppColors.diamondBlue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PotOddsCalculatorScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeLinkCard(
                    icon: Icons.pie_chart_rounded,
                    title: AppStrings.toolsEquityTitle,
                    description: AppStrings.toolsEquityCardDescription,
                    accentColor: AppColors.violetPrimary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const EquityCalculatorScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeLinkCard(
                    icon: Icons.trending_up_rounded,
                    title: AppStrings.toolsEvTitle,
                    description: AppStrings.toolsEvCardDescription,
                    accentColor: AppColors.neonGreen,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const EvCalculatorScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeLinkCard(
                    icon: Icons.view_module_rounded,
                    title: AppStrings.toolsComboTitle,
                    description: AppStrings.toolsComboCardDescription,
                    accentColor: AppColors.gold,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ComboCalculatorScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeLinkCard(
                    icon: Icons.grid_on_rounded,
                    title: AppStrings.toolsRangesTitle,
                    description: AppStrings.toolsRangesCardDescription,
                    accentColor: AppColors.gold,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RangeExplorerScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeLinkCard(
                    icon: Icons.block_rounded,
                    title: AppStrings.toolsBlockerTitle,
                    description: AppStrings.toolsBlockerCardDescription,
                    accentColor: AppColors.danger,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const BlockerExplorerScreen()),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.diamondBlue.withValues(alpha: 0.18),
          ),
          child: const Icon(Icons.insights_rounded,
              color: AppColors.diamondBlue, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.toolsHeaderTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                AppStrings.toolsHeaderSubtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

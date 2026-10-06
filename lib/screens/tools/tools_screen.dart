import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/ads/admob_rewarded_ad_service.dart';
import '../../services/economy/economy_access_service.dart';
import '../../services/economy/floply_coins_service.dart';
import '../../services/economy/training_quota_service.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import '../economy/widgets/economy_gate.dart';
import '../home/widgets/sv_home_link_card.dart';
import 'blocker_explorer_screen.dart';
import 'combo_calculator_screen.dart';
import 'equity_calculator_screen.dart';
import 'ev_calculator_screen.dart';
import 'pot_odds_calculator_screen.dart';
import 'range/range_explorer_screen.dart';
import 'widgets/tool_explainer.dart' show ToolInfoButton;
import 'widgets/tool_guide_screen.dart';
import 'widgets/tool_widgets.dart';
import 'widgets/tools_guide_sheet.dart';

/// Hub de Tools — Pot Odds, Equity, EV, Combos, Rangos, Blockers, todas
/// calculadoras reales sobre el motor.
///
/// Grupo 2 (profesionalización de Tools): migrado a Sala Verde y a
/// [SvHomeLinkCard] (el mismo componente que ya usa la Home para sus
/// tarjetas de acceso — antes esta pantalla tenía su propia
/// `HomeLinkCard` con un color de marca distinto por herramienta;
/// ahora las 6 comparten el acento de Tools, `graphiteSteelBright`, ya
/// definido como su temperatura en `SvSectionHeaderVariant.tools`).
///
/// **Integración de economía**: las 6 comparten exactamente el mismo
/// costo por minuto (pedido explícito: "no diferenciar herramientas por
/// complejidad") — cada una se abre envuelta en [EconomyGate], el único
/// mecanismo de gate+medición de tiempo de toda la economía. Esta
/// pantalla (el hub en sí, con la lista de accesos) nunca consume nada
/// — el costo empieza recién al entrar a una calculadora puntual.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key, this.access, this.coins});

  /// `null` arma una economía propia de respaldo (nunca usado en
  /// producción real: `HomeScreen` siempre pasa la instancia compartida
  /// al navegar acá) — solo para que ningún call site/test anterior a
  /// esta integración se rompa por un parámetro nuevo.
  final EconomyAccessService? access;
  final FloplyCoinsService? coins;

  static final FloplyCoinsService _fallbackCoins = FloplyCoinsService()..load();
  static final EconomyAccessService _fallbackAccess = EconomyAccessService(
    coins: _fallbackCoins,
    training: TrainingQuotaService()..load(),
    premium: StubPremiumService(),
    ads: AdMobRewardedAdService(coins: _fallbackCoins),
  );

  Route<void> _gated(WidgetBuilder builder) => MaterialPageRoute(
        builder: (_) => EconomyGate(
          access: access ?? _fallbackAccess,
          coins: coins ?? _fallbackCoins,
          blockedTitle: AppStrings.economyNoCoinsTitle,
          blockedBody: AppStrings.economyNoCoinsBody,
          builder: builder,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SvSectionHeader(
                  icon: Icons.insights_rounded,
                  title: AppStrings.toolsHeaderTitle,
                  subtitle: AppStrings.toolsHeaderSubtitle,
                  variant: SvSectionHeaderVariant.tools,
                  // Acceso discreto a la guía consolidada ("¿Cómo usar
                  // las herramientas?") — mismo botón ⓘ que ya usa cada
                  // Tool puntual (`ToolHeader.trailing`), nunca un
                  // componente nuevo.
                  trailing: Semantics(
                    button: true,
                    label: AppStrings.toolsGuideButtonLabel,
                    child: ToolInfoButton(onTap: () => showToolsGuideSheet(context)),
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.xl),
                // Orden conceptual del ecosistema (Rangos alimenta a las
                // demás; Pot Odds y EV cierran la cadena de decisión) —
                // no el orden alfabético ni el de implementación.
                SvHomeLinkCard(
                  icon: Icons.grid_on_rounded,
                  title: AppStrings.toolsRangesTitle,
                  description: AppStrings.toolsRangesCardDescription,
                  accentColor: kToolAccent,
                  onTap: () => Navigator.of(context).push(_gated((_) =>
                      ToolGuideScreen(
                        content: kRangeGuide,
                        calculatorBuilder: (_) => const RangeExplorerScreen(),
                      ))),
                ),
                const SizedBox(height: SalaVerdeSpace.md),
                SvHomeLinkCard(
                  icon: Icons.pie_chart_rounded,
                  title: AppStrings.toolsEquityTitle,
                  description: AppStrings.toolsEquityCardDescription,
                  accentColor: kToolAccent,
                  onTap: () => Navigator.of(context).push(_gated((_) =>
                      ToolGuideScreen(
                        content: kEquityGuide,
                        calculatorBuilder: (_) => const EquityCalculatorScreen(),
                      ))),
                ),
                const SizedBox(height: SalaVerdeSpace.md),
                SvHomeLinkCard(
                  icon: Icons.percent_rounded,
                  title: AppStrings.toolsPotOddsTitle,
                  description: AppStrings.toolsPotOddsCardDescription,
                  accentColor: kToolAccent,
                  onTap: () => Navigator.of(context).push(_gated((_) =>
                      ToolGuideScreen(
                        content: kPotOddsGuide,
                        calculatorBuilder: (_) => const PotOddsCalculatorScreen(),
                      ))),
                ),
                const SizedBox(height: SalaVerdeSpace.md),
                SvHomeLinkCard(
                  icon: Icons.query_stats_rounded,
                  title: AppStrings.toolsEvTitle,
                  description: AppStrings.toolsEvCardDescription,
                  accentColor: kToolAccent,
                  onTap: () => Navigator.of(context).push(_gated((_) =>
                      ToolGuideScreen(
                        content: kEvGuide,
                        calculatorBuilder: (_) => const EvCalculatorScreen(),
                      ))),
                ),
                const SizedBox(height: SalaVerdeSpace.md),
                SvHomeLinkCard(
                  icon: Icons.style_rounded,
                  title: AppStrings.toolsComboTitle,
                  description: AppStrings.toolsComboCardDescription,
                  accentColor: kToolAccent,
                  onTap: () => Navigator.of(context).push(_gated((_) =>
                      ToolGuideScreen(
                        content: kComboGuide,
                        calculatorBuilder: (_) => const ComboCalculatorScreen(),
                      ))),
                ),
                const SizedBox(height: SalaVerdeSpace.md),
                SvHomeLinkCard(
                  icon: Icons.block_rounded,
                  title: AppStrings.toolsBlockerTitle,
                  description: AppStrings.toolsBlockerCardDescription,
                  accentColor: kToolAccent,
                  onTap: () => Navigator.of(context).push(_gated((_) =>
                      ToolGuideScreen(
                        content: kBlockerGuide,
                        calculatorBuilder: (_) => const BlockerExplorerScreen(),
                      ))),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

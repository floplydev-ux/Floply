import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../../services/economy/coins_economy_state.dart';
import '../../services/economy/economy_access_service.dart';
import '../../services/economy/floply_coins_service.dart';
import '../../services/economy/training_quota_service.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';

/// "Tu economía" (sección 13) — el detalle completo que en Home solo se
/// insinúa (`HomeTopBar`): Coins, tiempo disponible, próxima
/// regeneración, entrenamientos gratis y cuándo vuelven, estado Premium,
/// y la opción de ver un anuncio cuando corresponde — reemplaza el
/// acceso de diagnóstico que antes vivía acá (`EconomyDebugScreen`
/// sigue existiendo para desarrollo, solo que ya no hace falta para ver
/// esto de verdad).
class EconomyProfileSection extends StatelessWidget {
  const EconomyProfileSection({
    super.key,
    required this.coins,
    required this.training,
    required this.premium,
    required this.economyAccess,
  });

  final FloplyCoinsService coins;
  final TrainingQuotaService training;
  final PremiumService premium;
  final EconomyAccessService economyAccess;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([coins, training]),
      builder: (context, _) {
        final isPremium = premium.isPremium;
        final nextRegen = coins.nextRegenerationAt;
        final isFull = coins.coins >= CoinsEconomyState.maxCoins;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.economyProfileSectionTitle,
                style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary)),
            const SizedBox(height: SalaVerdeSpace.sm),
            SvSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          label: AppStrings.economyProfileCoinsLabel,
                          value: '${coins.coins}',
                        ),
                      ),
                      Expanded(
                        child: _StatBlock(
                          label: AppStrings.economyProfileMinutesLabel,
                          value: '${coins.availableMinutes}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SalaVerdeSpace.sm),
                  Text(
                    isPremium
                        ? AppStrings.economyProfilePremiumActive
                        : nextRegen != null
                            ? AppStrings.economyProfileNextRegeneration(_relativeTime(nextRegen))
                            : AppStrings.economyProfileFullCoins,
                    style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
                  ),
                  const Divider(height: SalaVerdeSpace.xl, color: SalaVerdeColors.borderSubtle),
                  Row(
                    children: [
                      Expanded(
                        child: Text(AppStrings.economyProfileTrainingLabel,
                            style: SalaVerdeType.body()),
                      ),
                      Text('${training.remaining}',
                          style: SalaVerdeType.numeric(
                              size: 16, color: SalaVerdeColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.economyProfileTrainingReset(
                        _relativeTime(_nextMidnight(training.resetDate))),
                    style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
                  ),
                  const Divider(height: SalaVerdeSpace.xl, color: SalaVerdeColors.borderSubtle),
                  Row(
                    children: [
                      Expanded(
                        child: Text(AppStrings.economyProfilePremiumLabel,
                            style: SalaVerdeType.body()),
                      ),
                      Text(
                        isPremium
                            ? AppStrings.economyProfilePremiumActive
                            : AppStrings.economyProfilePremiumInactive,
                        style: SalaVerdeType.caption(
                            color: isPremium
                                ? SalaVerdeColors.success
                                : SalaVerdeColors.textMuted),
                      ),
                    ],
                  ),
                  if (!isPremium && !isFull) ...[
                    const SizedBox(height: SalaVerdeSpace.md),
                    _WatchAdRow(economyAccess: economyAccess, coins: coins),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static DateTime _nextMidnight(DateTime resetDate) =>
      DateTime(resetDate.year, resetDate.month, resetDate.day + 1);
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: SalaVerdeType.numeric(size: 26, color: SalaVerdeColors.brassBright)),
        Text(label, style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
      ],
    );
  }
}

/// La fila de "Ver anuncio +1 Coin" dentro de Perfil — una fila chica
/// propia (reutilizar la vista de bloqueo sería excesivo acá: esto no es
/// un bloqueo, el usuario puede tener Coins de sobra y solo quiere sumar
/// más) sobre la misma llamada real ([EconomyAccessService.watchRewardedAd]).
class _WatchAdRow extends StatefulWidget {
  const _WatchAdRow({required this.economyAccess, required this.coins});

  final EconomyAccessService economyAccess;
  final FloplyCoinsService coins;

  @override
  State<_WatchAdRow> createState() => _WatchAdRowState();
}

class _WatchAdRowState extends State<_WatchAdRow> {
  bool _watching = false;
  String? _message;

  Future<void> _watch() async {
    setState(() {
      _watching = true;
      _message = AppStrings.economyWatchingAd;
    });
    final result = await widget.economyAccess.watchRewardedAd();
    if (!mounted) return;
    setState(() {
      _watching = false;
      _message = switch (result) {
        RewardedAdShowResult.rewardGranted => AppStrings.economyAdRewardGranted,
        RewardedAdShowResult.rewardRejectedByEconomy => AppStrings.economyAdRewardRejected,
        RewardedAdShowResult.dismissedWithoutReward => AppStrings.economyAdDismissed,
        RewardedAdShowResult.notAvailable ||
        RewardedAdShowResult.unsupportedPlatform =>
          AppStrings.economyAdNotAvailable,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final canWatch = !_watching && widget.coins.canRequestAdReward;
    final remaining = widget.coins.rewardedAdsUsedInWindow;
    const max = CoinsEconomyState.maxRewardedAdsPerWindow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SvButtonSecondary(
          label: _watching ? AppStrings.economyWatchingAd : AppStrings.economyWatchAdCta,
          onTap: canWatch ? _watch : null,
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.economyAdsRemainingInWindow((max - remaining).clamp(0, max), max),
          style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
        ),
        if (_message != null) ...[
          const SizedBox(height: 4),
          Text(_message!, style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
        ],
      ],
    );
  }
}

String _relativeTime(DateTime target) {
  final diff = target.difference(DateTime.now());
  if (diff.inMinutes <= 0) return 'en un momento';
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  if (hours > 0) {
    return minutes > 0 ? 'en ${hours}h ${minutes}min' : 'en ${hours}h';
  }
  return 'en $minutes min';
}

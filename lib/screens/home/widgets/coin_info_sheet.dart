import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/ads/rewarded_ad_service.dart';
import '../../../services/economy/coins_economy_state.dart';
import '../../../services/economy/economy_access_service.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Tipo de coin cuya info se muestra.
enum CoinInfoType { floplyCoins, trainingQuota }

/// Hoja modal informativa que explica para qué sirve cada coin/cuota y
/// cómo se recarga. Se abre al tocar el módulo de Coins o Entrenamiento
/// en [HomeTopBar].
///
/// Cuando [access] se proporciona (solo para [CoinInfoType.floplyCoins]),
/// añade la opción de ver un anuncio para recuperar +1 Coin directamente
/// desde Home — mismo servicio y misma economía que usa [EconomyGate],
/// sin ningún flujo paralelo.
class CoinInfoSheet extends StatefulWidget {
  const CoinInfoSheet({super.key, required this.type, this.access});

  final CoinInfoType type;

  /// Servicio de acceso económico real — `null` muestra solo info estática.
  final EconomyAccessService? access;

  static void show(
    BuildContext context,
    CoinInfoType type, {
    EconomyAccessService? access,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CoinInfoSheet(type: type, access: access),
    );
  }

  @override
  State<CoinInfoSheet> createState() => _CoinInfoSheetState();
}

class _CoinInfoSheetState extends State<CoinInfoSheet> {
  bool _watching = false;
  String? _statusMessage;

  String get _title => widget.type == CoinInfoType.floplyCoins
      ? AppStrings.economyCoinInfoTitle
      : AppStrings.economyTrainingInfoTitle;

  String get _body => widget.type == CoinInfoType.floplyCoins
      ? AppStrings.economyCoinInfoBody
      : AppStrings.economyTrainingInfoBody;

  Color get _accent => widget.type == CoinInfoType.floplyCoins
      ? SalaVerdeColors.brass
      : SalaVerdeColors.feltGreenBright;

  Future<void> _watchAd() async {
    final access = widget.access;
    if (access == null) return;
    setState(() {
      _watching = true;
      _statusMessage = AppStrings.economyWatchingAd;
    });
    final result = await access.watchRewardedAd();
    if (!mounted) return;
    if (result == RewardedAdShowResult.rewardGranted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _watching = false;
      _statusMessage = switch (result) {
        RewardedAdShowResult.rewardRejectedByEconomy =>
          AppStrings.economyAdRewardRejected,
        RewardedAdShowResult.dismissedWithoutReward =>
          AppStrings.economyAdDismissed,
        RewardedAdShowResult.notAvailable ||
        RewardedAdShowResult.unsupportedPlatform =>
          AppStrings.economyAdNotAvailable,
        RewardedAdShowResult.rewardGranted => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = widget.access;
    final showAdSection =
        widget.type == CoinInfoType.floplyCoins && access != null;

    return Container(
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SalaVerdeRadius.panel),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        SalaVerdeSpace.lg,
        SalaVerdeSpace.lg,
        SalaVerdeSpace.lg,
        SalaVerdeSpace.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen/ícono del tipo de coin
          Center(
            child: widget.type == CoinInfoType.floplyCoins
                ? SizedBox(
                    width: 72,
                    height: 72,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/home/floply_coin.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: _accent,
                      size: 34,
                    ),
                  ),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: SalaVerdeType.title(),
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          Text(
            _body,
            style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
          ),
          // Sección de anuncio — solo para FLOPly Coins y cuando se
          // tiene acceso al servicio económico real.
          if (showAdSection)
            AnimatedBuilder(
              animation: access.coins,
              builder: (context, _) {
                final decision = access.checkTimedAccess();
                if (!decision.canWatchRewardedAd) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: SalaVerdeSpace.md),
                    const Divider(color: SalaVerdeColors.borderSubtle, height: 1),
                    const SizedBox(height: SalaVerdeSpace.md),
                    Text(
                      AppStrings.economyAdsRemainingInWindow(
                        decision.rewardedAdsRemainingInWindow,
                        CoinsEconomyState.maxRewardedAdsPerWindow,
                      ),
                      style: SalaVerdeType.caption(
                          color: SalaVerdeColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: SalaVerdeSpace.xs),
                      Text(
                        _statusMessage!,
                        style: SalaVerdeType.caption(
                            color: SalaVerdeColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: SalaVerdeSpace.sm),
                    SvButtonPrimary(
                      label: AppStrings.economyWatchAdCta,
                      onTap: (!_watching && decision.canWatchRewardedAd)
                          ? _watchAd
                          : null,
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: SalaVerdeSpace.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _accent.withValues(alpha: 0.18),
              foregroundColor: _accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              ),
            ),
            child: Text(
              AppStrings.economyCoinInfoClose,
              style: SalaVerdeType.bodyStrong(color: _accent),
            ),
          ),
        ],
      ),
    );
  }
}

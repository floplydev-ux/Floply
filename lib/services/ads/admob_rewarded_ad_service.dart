import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../economy/floply_coins_service.dart';
import 'ad_config.dart';
import 'rewarded_ad_service.dart';

/// Implementación real de [RewardedAdService], sobre `google_mobile_ads`.
///
/// Deliberadamente delgada: la única decisión de negocio que toma
/// (¿corresponde sumar la Coin?) se delega a [resolveRewardedAdOutcome],
/// compartida con la implementación de tests — acá solo se traduce el
/// ciclo de vida real del SDK (cargar, mostrar, escuchar
/// `onUserEarnedReward`, liberar el objeto, precargar el siguiente) a ese
/// contrato.
///
/// En Web (`kIsWeb`) nunca toca el SDK: `google_mobile_ads` no tiene
/// soporte nativo ahí, así que [preload]/[showForCoinReward] devuelven de
/// inmediato sin intentar nada (ver el pedido de compatibilidad web).
class AdMobRewardedAdService implements RewardedAdService {
  AdMobRewardedAdService({required this.coins});

  final FloplyCoinsService coins;

  RewardedAd? _ad;
  bool _loadingAd = false;

  @override
  bool get isReady => _ad != null;

  @override
  Future<void> preload() async {
    if (kIsWeb || _loadingAd || _ad != null) return;
    _loadingAd = true;
    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
          },
          onAdFailedToLoad: (error) {
            _ad = null;
          },
        ),
      );
    } catch (_) {
      // best-effort: sin SDK/red disponible, simplemente no hay anuncio
      // listo — `isReady` ya refleja eso, no hace falta propagar la
      // excepción.
      _ad = null;
    } finally {
      _loadingAd = false;
    }
  }

  @override
  Future<RewardedAdShowResult> showForCoinReward() async {
    if (kIsWeb) return RewardedAdShowResult.unsupportedPlatform;

    // Chequeo rápido antes de gastar inventario de anuncios en un usuario
    // que igual no podría cobrar la recompensa — la decisión FINAL y
    // autoritativa la sigue tomando `FloplyCoinsService.grantAdReward`
    // dentro de `resolveRewardedAdOutcome`, nunca este valor solo.
    if (!coins.canRequestAdReward) {
      return RewardedAdShowResult.rewardRejectedByEconomy;
    }

    if (_ad == null) await preload();
    final ad = _ad;
    if (ad == null) return RewardedAdShowResult.notAvailable;
    _ad = null; // un `RewardedAd` se muestra una sola vez.

    final completer = Completer<RewardedAdShowResult>();
    var earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        unawaited(preload());
        if (completer.isCompleted) return;
        unawaited(
          resolveRewardedAdOutcome(earnedReward: earnedReward, coins: coins)
              .then(completer.complete),
        );
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(RewardedAdShowResult.notAvailable);
      },
    );

    await ad.show(
      onUserEarnedReward: (_, __) {
        earnedReward = true;
      },
    );

    return completer.future;
  }
}

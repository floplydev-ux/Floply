import '../premium/premium_service.dart';
import 'coins_economy_state.dart';
import 'floply_coins_service.dart';
import 'training_quota_service.dart';

/// Vista de solo lectura de TODA la economía en un momento dado — pensada
/// para una futura UI real (Fase 2) y para la pantalla de diagnóstico de
/// esta fase (`lib/dev/economy_debug/`).
///
/// **No es una fuente de verdad nueva**: cada campo se lee directamente de
/// [FloplyCoinsService]/[TrainingQuotaService]/[PremiumService] en el
/// momento de construirse — nunca se persiste ni se cachea por su cuenta,
/// así que nunca puede quedar desincronizada de los servicios reales (ver
/// el pedido: "no duplicar estos valores en múltiples lugares").
class EconomySnapshot {
  const EconomySnapshot({
    required this.availableMinutes,
    required this.coins,
    required this.maxCoins,
    required this.nextRegenerationAt,
    required this.dailyTrainingRemaining,
    required this.dailyTrainingResetDate,
    required this.rewardedAdsUsedInWindow,
    required this.maxRewardedAdsPerWindow,
    required this.isPremium,
  });

  final int availableMinutes;
  final int coins;
  final int maxCoins;
  final DateTime? nextRegenerationAt;
  final int dailyTrainingRemaining;
  final DateTime dailyTrainingResetDate;
  final int rewardedAdsUsedInWindow;
  final int maxRewardedAdsPerWindow;
  final bool isPremium;

  factory EconomySnapshot.of({
    required FloplyCoinsService coins,
    required TrainingQuotaService training,
    required PremiumService premium,
  }) =>
      EconomySnapshot(
        availableMinutes: coins.availableMinutes,
        coins: coins.coins,
        maxCoins: CoinsEconomyState.maxCoins,
        nextRegenerationAt: coins.nextRegenerationAt,
        dailyTrainingRemaining: training.remaining,
        dailyTrainingResetDate: training.resetDate,
        rewardedAdsUsedInWindow: coins.rewardedAdsUsedInWindow,
        maxRewardedAdsPerWindow: CoinsEconomyState.maxRewardedAdsPerWindow,
        isPremium: premium.isPremium,
      );
}

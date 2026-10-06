import '../economy/floply_coins_service.dart';
import 'rewarded_ad_service.dart';

/// Doble de prueba de [RewardedAdService] — `flutter test` no puede cargar
/// anuncios reales (no hay canales de plataforma disponibles), así que
/// esta clase simula el ciclo de vida del SDK con métodos explícitos en
/// vez de esperar un anuncio real.
///
/// Comparte [resolveRewardedAdOutcome] con [AdMobRewardedAdService] (real):
/// un test contra esta fake ejercita la MISMA decisión de negocio que la
/// implementación real, no una reimplementación paralela.
class FakeRewardedAdService implements RewardedAdService {
  FakeRewardedAdService({required this.coins});

  final FloplyCoinsService coins;

  bool _ready = true;
  bool _forceNextLoadFailure = false;

  @override
  bool get isReady => _ready;

  /// Hace que la próxima [preload]/[showForCoinReward] falle como si el
  /// SDK no hubiera podido cargar el anuncio — para el test de "errores
  /// del anuncio no otorgan Coin".
  void simulateLoadFailure() => _forceNextLoadFailure = true;

  @override
  Future<void> preload() async {
    if (_forceNextLoadFailure) {
      _ready = false;
      return;
    }
    _ready = true;
  }

  /// Simula que el usuario vio el anuncio hasta el final y el SDK
  /// confirmó la recompensa (`onUserEarnedReward`).
  Future<RewardedAdShowResult> showAndEarnReward() => _show(earnedReward: true);

  /// Simula que el usuario cerró el anuncio antes de completarlo — tocar
  /// "ver publicidad", por sí solo, nunca alcanza para ganar la Coin.
  Future<RewardedAdShowResult> showAndDismissWithoutReward() =>
      _show(earnedReward: false);

  @override
  Future<RewardedAdShowResult> showForCoinReward() => showAndEarnReward();

  Future<RewardedAdShowResult> _show({required bool earnedReward}) async {
    if (!coins.canRequestAdReward) {
      return RewardedAdShowResult.rewardRejectedByEconomy;
    }
    if (!_ready || _forceNextLoadFailure) {
      _forceNextLoadFailure = false;
      _ready = false;
      return RewardedAdShowResult.notAvailable;
    }
    _ready = false; // un anuncio se muestra una sola vez, igual que el real.
    final result = await resolveRewardedAdOutcome(earnedReward: earnedReward, coins: coins);
    await preload();
    return result;
  }
}

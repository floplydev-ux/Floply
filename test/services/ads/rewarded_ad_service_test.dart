import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/persistence/coins_economy_store.dart';
import 'package:poker_trainer/services/ads/fake_rewarded_ad_service.dart';
import 'package:poker_trainer/services/ads/rewarded_ad_service.dart';
import 'package:poker_trainer/services/economy/floply_coins_service.dart';

/// `flutter test` no puede cargar Rewarded Ads reales (no hay canales de
/// plataforma disponibles) — estos tests ejercitan `FakeRewardedAdService`,
/// que comparte `resolveRewardedAdOutcome` con la implementación real de
/// AdMob (`AdMobRewardedAdService`): la decisión de negocio bajo prueba acá
/// es exactamente la misma que tomaría la real, no una reimplementación
/// paralela (ver el doc-comment de `resolveRewardedAdOutcome`).
void main() {
  late FloplyCoinsService coins;
  late FakeRewardedAdService ads;

  Future<void> setUp_() async {
    coins = FloplyCoinsService(store: InMemoryCoinsEconomyStore());
    await coins.load();
    ads = FakeRewardedAdService(coins: coins);
  }

  group('RewardedAdService — solo onUserEarnedReward otorga la Coin', () {
    test('18. el click en "ver publicidad" (precargar/mostrar el anuncio) '
        'por sí solo no otorga nada: solo preload() no cambia las Coins',
        () async {
      await setUp_();
      await coins.consumeTime(const Duration(minutes: 90)); // hace lugar
      final before = coins.coins;

      await ads.preload();
      await ads.preload();
      expect(coins.coins, before);
    });

    test('19. solamente onUserEarnedReward puede otorgar la recompensa —'
        ' completar el anuncio sí suma la Coin', () async {
      await setUp_();
      await coins.consumeTime(const Duration(minutes: 90));
      final before = coins.coins;

      final result = await ads.showAndEarnReward();

      expect(result, RewardedAdShowResult.rewardGranted);
      expect(coins.coins, before + 1);
    });

    test('19b. cerrar el anuncio sin completarlo nunca suma una Coin,'
        ' aunque se repita varias veces', () async {
      await setUp_();
      await coins.consumeTime(const Duration(minutes: 90));
      final before = coins.coins;

      for (var i = 0; i < 3; i++) {
        final result = await ads.showAndDismissWithoutReward();
        expect(result, RewardedAdShowResult.dismissedWithoutReward);
      }
      expect(coins.coins, before);
    });
  });

  group('RewardedAdService — errores nunca otorgan', () {
    test('21. si el anuncio no está disponible (falló la carga), no se '
        'otorga nada', () async {
      await setUp_();
      await coins.consumeTime(const Duration(minutes: 90));
      final before = coins.coins;

      ads.simulateLoadFailure();
      final result = await ads.showForCoinReward();

      expect(result, RewardedAdShowResult.notAvailable);
      expect(coins.coins, before);
    });
  });

  group('RewardedAdService — respeta los límites de la economía', () {
    test('rechaza mostrar/otorgar si la economía ya está en el máximo de '
        'Coins, sin siquiera llegar a "mostrar" el anuncio', () async {
      await setUp_(); // arranca lleno (6 Coins)
      final result = await ads.showForCoinReward();
      expect(result, RewardedAdShowResult.rewardRejectedByEconomy);
      expect(coins.coins, 6);
    });

    test('17 (a nivel del servicio de ads). respeta el máximo de 3 '
        'recompensas cada 12 horas', () async {
      await setUp_();
      await coins.consumeTime(const Duration(minutes: 90));

      expect((await ads.showAndEarnReward()), RewardedAdShowResult.rewardGranted);
      expect((await ads.showAndEarnReward()), RewardedAdShowResult.rewardGranted);
      expect((await ads.showAndEarnReward()), RewardedAdShowResult.rewardGranted);

      final fourth = await ads.showAndEarnReward();
      expect(fourth, RewardedAdShowResult.rewardRejectedByEconomy);
      expect(coins.coins, 3);
    });
  });

  group('RewardedAdService — ciclo de vida', () {
    test('isReady refleja si hay un anuncio precargado, y se recarga solo '
        'tras usarse', () async {
      await setUp_();
      expect(ads.isReady, isTrue); // fake arranca "lista" por defecto
      await coins.consumeTime(const Duration(minutes: 90));
      await ads.showAndEarnReward();
      // Tras mostrarse, el propio flujo vuelve a precargar para la
      // próxima vez.
      expect(ads.isReady, isTrue);
    });
  });
}

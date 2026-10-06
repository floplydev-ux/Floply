import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/persistence/coins_economy_store.dart';
import 'package:poker_trainer/persistence/training_quota_store.dart';
import 'package:poker_trainer/services/ads/fake_rewarded_ad_service.dart';
import 'package:poker_trainer/services/economy/coins_economy_state.dart';
import 'package:poker_trainer/services/economy/economy_access_service.dart';
import 'package:poker_trainer/services/economy/floply_coins_service.dart';
import 'package:poker_trainer/services/economy/training_quota_service.dart';
import 'package:poker_trainer/services/economy/training_quota_state.dart';
import 'package:poker_trainer/services/premium/premium_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class _AlwaysPremium extends PremiumService {
  @override
  bool get isPremium => true;
  @override
  bool get isLoading => false;
  @override
  Future<Offerings?> getOfferings() async => null;
  @override
  Future<bool> purchasePackage(Package package) async => false;
  @override
  Future<bool> restorePurchases() async => false;
}

void main() {
  late FloplyCoinsService coins;
  late TrainingQuotaService training;

  EconomyAccessService build({PremiumService? premium}) =>
      EconomyAccessService(
        coins: coins,
        training: training,
        premium: premium ?? StubPremiumService(),
        ads: FakeRewardedAdService(coins: coins),
      );

  setUp(() async {
    coins = FloplyCoinsService(store: InMemoryCoinsEconomyStore());
    training = TrainingQuotaService(store: InMemoryTrainingQuotaStore());
    await coins.load();
    await training.load();
  });

  group('EconomyAccessService — Premium siempre puede acceder', () {
    test('checkTimedAccess (Tools/Coach) devuelve premium sin tocar Coins',
        () async {
      await coins.consumeTime(CoinsEconomyState.maxAvailableTime); // deja 0
      final access = build(premium: _AlwaysPremium());
      final decision = access.checkTimedAccess();
      expect(decision.status, EconomyAccessStatus.premium);
      expect(decision.isGranted, isTrue);
      expect(decision.consumesCoins, isFalse);
    });

    test('checkTrainingAccess devuelve premium aunque la quota ya esté en 0',
        () async {
      for (var i = 0; i < TrainingQuotaState.dailyFreeTrainings; i++) {
        await training.consumeTraining();
      }
      expect(training.hasFreeTrainingLeft, isFalse);
      final access = build(premium: _AlwaysPremium());
      expect(access.checkTrainingAccess().status, EconomyAccessStatus.premium);
    });
  });

  group('EconomyAccessService — Training Quota (1-5 gratis, 6+ con Coins)', () {
    test('mientras queda cupo gratis, el status es freeTraining (nunca '
        'consume Coins)', () {
      final access = build();
      final decision = access.checkTrainingAccess();
      expect(decision.status, EconomyAccessStatus.freeTraining);
      expect(decision.consumesCoins, isFalse);
      expect(decision.trainingRemainingToday, TrainingQuotaState.dailyFreeTrainings);
    });

    test('tras agotar los 5 gratis, con Coins disponibles el status pasa a '
        'accessible (consume Coins por tiempo, nunca gratis)', () async {
      final access = build();
      for (var i = 0; i < TrainingQuotaState.dailyFreeTrainings; i++) {
        final ok = await access.confirmFreeTrainingStart();
        expect(ok, isTrue, reason: 'entrenamiento gratis #$i');
      }
      final decision = access.checkTrainingAccess();
      expect(decision.status, EconomyAccessStatus.accessible);
      expect(decision.consumesCoins, isTrue);
    });

    test('agotado el cupo gratis y sin Coins, el status es noCoins', () async {
      final access = build();
      for (var i = 0; i < TrainingQuotaState.dailyFreeTrainings; i++) {
        await access.confirmFreeTrainingStart();
      }
      await coins.consumeTime(CoinsEconomyState.maxAvailableTime);
      final decision = access.checkTrainingAccess();
      expect(decision.status, EconomyAccessStatus.noCoins);
      expect(decision.isGranted, isFalse);
    });
  });

  group('EconomyAccessService — 0 Coins bloquea contenido pago (Tools/Coach)', () {
    test('con tiempo disponible, checkTimedAccess es accessible', () {
      expect(build().checkTimedAccess().status, EconomyAccessStatus.accessible);
    });

    test('en 0 Coins, checkTimedAccess es noCoins', () async {
      await coins.consumeTime(CoinsEconomyState.maxAvailableTime);
      final decision = build().checkTimedAccess();
      expect(decision.status, EconomyAccessStatus.noCoins);
      expect(decision.isGranted, isFalse);
    });

    test('un resto de minutos por debajo de una Coin completa sigue siendo '
        'tiempo real accesible (nunca se bloquea por la proyección entera '
        'de coins)', () async {
      // Deja 5 minutos — menos que 1 Coin completa (15 min) pero tiempo
      // real utilizable de verdad.
      await coins.consumeTime(CoinsEconomyState.maxAvailableTime - const Duration(minutes: 5));
      expect(coins.coins, 0, reason: 'precondición: 0 Coins enteras');
      expect(build().checkTimedAccess().status, EconomyAccessStatus.accessible);
    });
  });

  group('EconomyAccessService — Rewarded Ads disponibles/limitados', () {
    test('con Coins de sobra, no corresponde ofrecer el anuncio (ya está '
        'lleno)', () {
      final decision = build().checkTimedAccess();
      expect(decision.canWatchRewardedAd, isFalse);
    });

    test('sin Coins y dentro del límite de la ventana, sí corresponde '
        'ofrecerlo', () async {
      await coins.consumeTime(CoinsEconomyState.maxAvailableTime);
      final decision = build().checkTimedAccess();
      expect(decision.canWatchRewardedAd, isTrue);
      expect(decision.rewardedAdsRemainingInWindow, CoinsEconomyState.maxRewardedAdsPerWindow);
    });

    test('tras agotar las 3 recompensas de la ventana de 12h, ya no '
        'corresponde ofrecerlo', () async {
      await coins.consumeTime(CoinsEconomyState.maxAvailableTime);
      final access = build();
      for (var i = 0; i < CoinsEconomyState.maxRewardedAdsPerWindow; i++) {
        final result = await access.watchRewardedAd();
        expect(result.name, 'rewardGranted', reason: 'anuncio #$i');
      }
      final decision = access.checkTimedAccess();
      expect(decision.canWatchRewardedAd, isFalse);
      expect(decision.rewardedAdsRemainingInWindow, 0);
    });
  });
}

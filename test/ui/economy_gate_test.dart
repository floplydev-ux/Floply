import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/persistence/coins_economy_store.dart';
import 'package:poker_trainer/screens/economy/widgets/economy_gate.dart';
import 'package:poker_trainer/services/ads/fake_rewarded_ad_service.dart';
import 'package:poker_trainer/services/economy/coins_economy_state.dart';
import 'package:poker_trainer/services/economy/economy_access_service.dart';
import 'package:poker_trainer/services/economy/floply_coins_service.dart';
import 'package:poker_trainer/services/economy/training_quota_service.dart';
import 'package:poker_trainer/services/premium/premium_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// [EconomyGate] es el único mecanismo de gate+sesión económica de
/// Tools/Coach (sección 3/5 del pedido) — estos tests fijan el contrato
/// real: bloquea en 0 Coins sin que la pantalla paga llegue a montarse,
/// nunca falla silenciosamente, y "Ver anuncio" (mediante el callback
/// real `onUserEarnedReward`, simulado acá por `FakeRewardedAdService`)
/// la desbloquea sin que nadie tenga que reabrirla a mano.
void main() {
  Widget harness(EconomyAccessService access, FloplyCoinsService coins) {
    return MaterialApp(
      home: EconomyGate(
        access: access,
        coins: coins,
        blockedTitle: AppStrings.economyNoCoinsTitle,
        blockedBody: AppStrings.economyNoCoinsBody,
        builder: (_) => const Scaffold(body: Text('PANTALLA REAL')),
      ),
    );
  }

  testWidgets('con Coins disponibles, muestra la pantalla real directo —'
      ' nunca el aviso de bloqueo', (tester) async {
    final coins = FloplyCoinsService(store: InMemoryCoinsEconomyStore());
    await coins.load();
    final access = EconomyAccessService(
      coins: coins,
      training: TrainingQuotaService(),
      premium: StubPremiumService(),
      ads: FakeRewardedAdService(coins: coins),
    );

    await tester.pumpWidget(harness(access, coins));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA REAL'), findsOneWidget);
    expect(find.text(AppStrings.economyNoCoinsTitle), findsNothing);
  });

  testWidgets('sin Coins, bloquea de entrada — la pantalla real nunca '
      'llega a montarse', (tester) async {
    final coins = FloplyCoinsService(store: InMemoryCoinsEconomyStore());
    await coins.load();
    await coins.consumeTime(CoinsEconomyState.maxAvailableTime);
    final access = EconomyAccessService(
      coins: coins,
      training: TrainingQuotaService(),
      premium: StubPremiumService(),
      ads: FakeRewardedAdService(coins: coins),
    );

    await tester.pumpWidget(harness(access, coins));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA REAL'), findsNothing);
    expect(find.text(AppStrings.economyNoCoinsTitle), findsOneWidget);
  });

  testWidgets('desde el bloqueo, "Ver anuncio" y ganar la recompensa real '
      'abre la pantalla paga sola', (tester) async {
    final coins = FloplyCoinsService(store: InMemoryCoinsEconomyStore());
    await coins.load();
    await coins.consumeTime(CoinsEconomyState.maxAvailableTime);
    final access = EconomyAccessService(
      coins: coins,
      training: TrainingQuotaService(),
      premium: StubPremiumService(),
      ads: FakeRewardedAdService(coins: coins),
    );

    await tester.pumpWidget(harness(access, coins));
    await tester.pumpAndSettle();
    expect(find.text('PANTALLA REAL'), findsNothing);

    await tester.tap(find.text(AppStrings.economyWatchAdCta));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA REAL'), findsOneWidget);
    expect(coins.coins, greaterThan(0));
  });

  testWidgets('Premium: nunca bloquea, aunque esté en 0 Coins', (tester) async {
    final coins = FloplyCoinsService(store: InMemoryCoinsEconomyStore());
    await coins.load();
    await coins.consumeTime(CoinsEconomyState.maxAvailableTime);
    final access = EconomyAccessService(
      coins: coins,
      training: TrainingQuotaService(),
      premium: _AlwaysPremium(),
      ads: FakeRewardedAdService(coins: coins),
    );

    await tester.pumpWidget(harness(access, coins));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA REAL'), findsOneWidget);
  });
}

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

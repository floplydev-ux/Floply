import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/dev/economy_debug/economy_debug_screen.dart';
import 'package:poker_trainer/persistence/coins_economy_store.dart';
import 'package:poker_trainer/persistence/training_quota_store.dart';
import 'package:poker_trainer/services/ads/fake_rewarded_ad_service.dart';
import 'package:poker_trainer/services/economy/floply_coins_service.dart';
import 'package:poker_trainer/services/economy/training_quota_service.dart';

/// Smoke test de la pantalla de diagnóstico de la Fase 1 de monetización —
/// mismo criterio que `test/dev/design_playground_prototype_test.dart`
/// para el resto de `lib/dev/`: solo confirma que renderiza y que tocar
/// los controles no tira ninguna excepción.
///
/// Inyecta stores en memoria y [FakeRewardedAdService] — nunca la
/// implementación real (`AdMobRewardedAdService`/`FileCoinsEconomyStore`):
/// `flutter test` no tiene canales de plataforma reales, y un canal sin
/// responder puede directamente colgar el test en vez de fallar rápido
/// (confirmado al escribir este test), no solo lanzar una excepción — el
/// best-effort de esas clases está pensado para un dispositivo real, no
/// para este entorno.
void main() {
  testWidgets('EconomyDebugScreen renderiza y sus botones no tiran '
      'ninguna excepción', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EconomyDebugScreen(
        coins: FloplyCoinsService(store: InMemoryCoinsEconomyStore()),
        training: TrainingQuotaService(store: InMemoryTrainingQuotaStore()),
        adsBuilder: (coins) => FakeRewardedAdService(coins: coins),
      ),
    ));
    await tester.pumpAndSettle(); // deja correr la inicialización asíncrona

    expect(tester.takeException(), isNull);
    expect(find.text('FLOPly Coins'), findsOneWidget);

    await tester.tap(find.text('Consumir 4 minutos'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Sumar 1 Coin manualmente'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Consumir 1 entrenamiento'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // El economy arranca lleno (6/6 Coins): el propio servicio rechaza el
    // pedido antes de tocar el SDK de anuncios, así que este tap tampoco
    // debería tirar ninguna excepción de plataforma.
    await tester.tap(find.text('Ver anuncio (+1 Coin)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

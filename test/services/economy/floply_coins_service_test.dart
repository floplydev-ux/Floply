import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/persistence/coins_economy_store.dart';
import 'package:poker_trainer/services/economy/coins_economy_state.dart';
import 'package:poker_trainer/services/economy/floply_coins_service.dart';

/// Reloj de prueba: `now` avanza solo cuando el test lo pide
/// (`clock.advance`) — nunca depende de que pase tiempo real mientras
/// corre la suite (determinismo, pedido explícito de la Fase 1).
class _FakeClock {
  DateTime _now = DateTime(2026, 1, 1, 12);
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  late _FakeClock clock;
  late InMemoryCoinsEconomyStore store;
  late FloplyCoinsService service;

  Future<void> setUp_() async {
    clock = _FakeClock();
    store = InMemoryCoinsEconomyStore();
    service = FloplyCoinsService(store: store, clock: clock.call);
    await service.load();
  }

  group('FLOPly Coins — estado inicial y topes', () {
    test('1. comienza con el estado definido por la app: 6 Coins / 90 min',
        () async {
      await setUp_();
      expect(service.coins, 6);
      expect(service.availableMinutes, 90);
    });

    test('2. nunca supera 6 Coins, ni sumando manualmente por encima del '
        'máximo', () async {
      await setUp_();
      await service.addCoin();
      await service.addCoin();
      expect(service.coins, 6);
      expect(service.availableMinutes, 90);
    });

    test('3. 1 Coin representa 15 minutos', () async {
      await setUp_();
      await service.consumeTime(const Duration(minutes: 75)); // deja 1 Coin
      expect(service.availableMinutes, 15);
      expect(service.coins, 1);
    });

    test('4. 6 Coins representan 90 minutos', () async {
      await setUp_();
      expect(service.coins, 6);
      expect(service.availableMinutes, 90);
    });
  });

  group('FLOPly Coins — consumo de tiempo real (nunca "abrir = -1 Coin")', () {
    test('5. consumir minutos reduce correctamente el tiempo disponible '
        '(4 min consumidos de 90 → quedan 86, no se pierde una Coin '
        'entera)', () async {
      await setUp_();
      final consumed = await service.consumeTime(const Duration(minutes: 4));
      expect(consumed, const Duration(minutes: 4));
      expect(service.availableMinutes, 86);
      // Todavía cuenta como 5 Coins completas (86/15 = 5.73 → floor 5):
      // el consumo parcial no descuenta una Coin entera de una.
      expect(service.coins, 5);
    });

    test('6. nunca permite tiempo negativo: pedir más de lo disponible '
        'consume solo lo que queda', () async {
      await setUp_();
      final consumed = await service.consumeTime(const Duration(minutes: 200));
      expect(consumed, const Duration(minutes: 90));
      expect(service.availableMinutes, 0);
      expect(service.coins, 0);
    });
  });

  group('FLOPly Coins — regeneración (basada en timestamps, nunca en un '
      'Timer)', () {
    test('7. regenera 1 Coin (15 min) cada 60 minutos', () async {
      await setUp_();
      await service.consumeTime(const Duration(minutes: 90)); // vacío
      clock.advance(const Duration(minutes: 60));
      expect(service.availableMinutes, 15);
      expect(service.coins, 1);
      clock.advance(const Duration(minutes: 60));
      expect(service.availableMinutes, 30);
      expect(service.coins, 2);
    });

    test('8. calcula correctamente la regeneración al volver después de '
        'cerrar la app (recarga desde el store persistido, sin Timer '
        'corriendo mientras tanto)', () async {
      await setUp_();
      await service.consumeTime(const Duration(minutes: 90)); // vacío
      clock.advance(const Duration(minutes: 125)); // 2 Coins de sobra

      // "Cerrar la app": una instancia nueva del servicio, mismo store,
      // mismo reloj (ya avanzado) — nada de estado en memoria sobrevive.
      final reopened = FloplyCoinsService(store: store, clock: clock.call);
      await reopened.load();

      expect(reopened.availableMinutes, 30); // 2 Coins completas
      expect(reopened.coins, 2);
    });

    test('9. no acumula regeneración ilimitada mientras está en el máximo '
        '— pasa una semana llena, y al gastar 2 Coins no aparecen 6 de '
        'golpe', () async {
      await setUp_();
      expect(service.coins, 6);
      clock.advance(const Duration(days: 7)); // toda una semana al máximo
      expect(service.coins, 6); // sigue en el máximo, no de más

      await service.consumeTime(const Duration(minutes: 30)); // gasta 2 Coins
      expect(service.coins, 4);

      // Si el ancla se hubiera quedado atrasada toda la semana, acá
      // aparecerían instantáneamente varias Coins de más. No debe pasar:
      // sin que avance el reloj, el estado tiene que seguir igual.
      expect(service.coins, 4);
      expect(service.availableMinutes, 60);
    });

    test('9b. tras gastar estando lleno, la regeneración retoma desde ese '
        'momento (no arrastra crédito de cuando estaba lleno)', () async {
      await setUp_();
      clock.advance(const Duration(days: 7));
      await service.consumeTime(const Duration(minutes: 90)); // vacío
      clock.advance(const Duration(minutes: 60));
      expect(service.coins, 1); // exactamente 1, no varias de golpe
    });

    test('10. añadir Coin manualmente respeta el máximo', () async {
      await setUp_();
      await service.consumeTime(const Duration(minutes: 90)); // vacío
      for (var i = 0; i < 10; i++) {
        await service.addCoin();
      }
      expect(service.coins, 6);
      expect(service.availableMinutes, 90);
    });
  });

  group('FLOPly Coins — persistencia', () {
    test('el estado sobrevive un ciclo completo de guardar/cargar '
        '(cierre y reapertura de la app)', () async {
      await setUp_();
      await service.consumeTime(const Duration(minutes: 20));
      final minutesBefore = service.availableMinutes;

      final reopened = FloplyCoinsService(store: store, clock: clock.call);
      await reopened.load();
      expect(reopened.availableMinutes, minutesBefore);
    });

    test('sin nada persistido todavía, arranca con el estado inicial de '
        'la app (nunca crashea)', () async {
      final freshStore = InMemoryCoinsEconomyStore();
      final freshService = FloplyCoinsService(store: freshStore, clock: clock.call);
      await freshService.load();
      expect(freshService.coins, 6);
    });
  });

  group('FLOPly Coins — recompensas de publicidad (grantAdReward, la única '
      'vía real de otorgar por anuncio)', () {
    test('otorga la Coin cuando hay lugar y no se agotó el cupo de la '
        'ventana', () async {
      await setUp_();
      await service.consumeTime(const Duration(minutes: 90));
      final result = await service.grantAdReward();
      expect(result, AdRewardGrantResult.granted);
      expect(service.availableMinutes, 15);
    });

    test('20. una recompensa nunca supera el máximo de 6 Coins', () async {
      await setUp_();
      // Ya está lleno.
      final result = await service.grantAdReward();
      expect(result, AdRewardGrantResult.rejectedAtMaxCoins);
      expect(service.coins, 6);
    });

    test('17. máximo 3 recompensas de publicidad en una ventana de 12 '
        'horas — la cuarta se rechaza aunque haya lugar para más Coins',
        () async {
      await setUp_();
      await service.consumeTime(const Duration(minutes: 90)); // deja lugar

      expect(await service.grantAdReward(), AdRewardGrantResult.granted);
      expect(await service.grantAdReward(), AdRewardGrantResult.granted);
      expect(await service.grantAdReward(), AdRewardGrantResult.granted);
      expect(service.coins, 3);

      final fourth = await service.grantAdReward();
      expect(fourth, AdRewardGrantResult.rejectedRateLimited);
      expect(service.coins, 3); // no cambia nada al rechazar

      // Pasadas las 12 horas desde la primera recompensa, la VENTANA de
      // publicidad se libera — puede que mientras tanto también se haya
      // regenerado alguna Coin por separado, así que se vacía de nuevo
      // para aislar específicamente que el límite de publicidad (no el
      // de Coins) ya no bloquea.
      clock.advance(const Duration(hours: 12, minutes: 1));
      await service.consumeTime(service.availableTime);
      expect(await service.grantAdReward(), AdRewardGrantResult.granted);
    });

    test('rewardedAdsUsedInWindow cuenta solo recompensas realmente '
        'concedidas dentro de la ventana, nunca intentos rechazados',
        () async {
      await setUp_();
      // Ya está lleno: el intento se rechaza (rejectedAtMaxCoins) y no
      // tiene que sumar al conteo — solo cuenta lo REALMENTE concedido.
      final rejected = await service.grantAdReward();
      expect(rejected, AdRewardGrantResult.rejectedAtMaxCoins);
      expect(service.rewardedAdsUsedInWindow, 0);

      await service.consumeTime(const Duration(minutes: 20)); // hace lugar
      expect(await service.grantAdReward(), AdRewardGrantResult.granted);
      expect(service.rewardedAdsUsedInWindow, 1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/persistence/coins_economy_store.dart';
import 'package:poker_trainer/services/economy/coins_economy_state.dart';
import 'package:poker_trainer/services/economy/economy_session.dart';
import 'package:poker_trainer/services/economy/floply_coins_service.dart';

/// [EconomySession] es el único mecanismo reutilizable de medición de
/// tiempo de toda la economía (Tools, Coach, entrenamiento extra) — estos
/// tests fijan su contrato: cobra el tiempo real transcurrido (nunca más
/// de lo usado), nunca cobra dos veces el mismo tramo, nunca deja el
/// saldo negativo, y detecta cuando se quedó sin Coins.
///
/// El `checkpointInterval` se deja corto a propósito (milisegundos reales,
/// nunca los 60s de producción) para que el `Timer` real dispare rápido en
/// el test — el [clock] inyectado (no el reloj real) es quien decide
/// CUÁNTO tiempo "pasó" en cada cobro, así que un test puede simular horas
/// de uso sin esperar horas de verdad.
void main() {
  group('EconomySession — cobro real, nunca más de lo usado', () {
    test('un checkpoint cobra exactamente el tiempo transcurrido según el '
        'reloj inyectado', () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      final session = EconomySession(
        coins: coins,
        checkpointInterval: const Duration(milliseconds: 15),
        clock: () => now,
      );
      session.start();

      now = now.add(const Duration(minutes: 5));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(coins.availableTime,
          CoinsEconomyState.maxAvailableTime - const Duration(minutes: 5));
      session.dispose();
    });

    test('varios checkpoints seguidos no cobran dos veces el mismo tramo '
        '(cada uno resetea desde dónde cuenta)', () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      final session = EconomySession(
        coins: coins,
        checkpointInterval: const Duration(milliseconds: 15),
        clock: () => now,
      );
      session.start();

      // 3 avances de 2 minutos, con tiempo real entre medio para que el
      // timer dispare varias veces — el total cobrado tiene que ser
      // exactamente 6 minutos, ni más ni menos (nunca un tramo contado
      // dos veces, nunca uno salteado).
      for (var i = 0; i < 3; i++) {
        now = now.add(const Duration(minutes: 2));
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      expect(coins.availableTime,
          CoinsEconomyState.maxAvailableTime - const Duration(minutes: 6));
      session.dispose();
    });

    test('pause() cobra el tramo hasta ese momento y detiene el cobro — '
        'el tiempo "en background" nunca se cobra', () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      final session = EconomySession(
        coins: coins,
        checkpointInterval: const Duration(milliseconds: 20),
        clock: () => now,
      );
      session.start();

      now = now.add(const Duration(minutes: 3));
      await session.pause();
      final afterPause = coins.availableTime;
      expect(afterPause, CoinsEconomyState.maxAvailableTime - const Duration(minutes: 3));

      // Mientras está en pausa, pasan otros 30 minutos reales de reloj
      // (menos del intervalo de regeneración, para no confundir "no se
      // cobra de más" con la regeneración normal de Coins, que es un
      // comportamiento real e independiente de esta sesión) — nunca se
      // cobran porque nadie dispara un checkpoint sin `resume()`.
      now = now.add(const Duration(minutes: 30));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(coins.availableTime, afterPause);

      session.dispose();
    });

    test('resume() cuenta desde el momento de reanudar, nunca desde antes '
        'de la pausa (evita doble conteo)', () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      final session = EconomySession(
        coins: coins,
        checkpointInterval: const Duration(milliseconds: 15),
        clock: () => now,
      );
      session.start();

      now = now.add(const Duration(minutes: 1));
      await session.pause();
      // Menos de los 60 minutos del intervalo de regeneración, a
      // propósito: el punto de este test es el conteo de la sesión, no
      // la regeneración real de Coins (que sigue su propio curso
      // independiente de esto, ver el test de `pause`).
      now = now.add(const Duration(minutes: 20)); // tiempo "perdido" en pausa
      session.resume();
      now = now.add(const Duration(minutes: 2));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // Solo se cobraron el minuto antes de pausar + los 2 después de
      // reanudar — nunca los 20 minutos de en medio.
      expect(coins.availableTime,
          CoinsEconomyState.maxAvailableTime - const Duration(minutes: 3));
      session.dispose();
    });

    test('end() es idempotente — una segunda llamada no cobra de nuevo',
        () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      final session = EconomySession(coins: coins, clock: () => now);
      session.start();
      now = now.add(const Duration(minutes: 4));
      await session.end();
      final afterFirstEnd = coins.availableTime;
      await session.end();
      expect(coins.availableTime, afterFirstEnd);
    });

    test('nunca deja el saldo negativo: pedir más tiempo del que hay '
        'consume solo lo que queda y marca que se quedó sin Coins',
        () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      // Deja solo 2 minutos disponibles antes de arrancar la sesión.
      await coins.consumeTime(CoinsEconomyState.maxAvailableTime - const Duration(minutes: 2));
      expect(coins.availableTime, const Duration(minutes: 2));

      final session = EconomySession(
        coins: coins,
        checkpointInterval: const Duration(milliseconds: 15),
        clock: () => now,
      );
      session.start();
      now = now.add(const Duration(minutes: 10)); // pide mucho más de lo que hay
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(coins.availableTime, Duration.zero);
      expect(session.ranOutOfCoins, isTrue);
      session.dispose();
    });

    test('dispose() cobra el tramo final pendiente sin que el caller '
        'tenga que esperar (best-effort, igual que la persistencia real)',
        () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      final session = EconomySession(coins: coins, clock: () => now);
      session.start();
      now = now.add(const Duration(minutes: 7));
      session.dispose();
      // El estado en memoria ya queda correcto de forma síncrona dentro
      // de `consumeTime`, antes de que termine el `Future` disparado por
      // `dispose()` — no hace falta ningún `await` para verlo reflejado.
      expect(coins.availableTime,
          CoinsEconomyState.maxAvailableTime - const Duration(minutes: 7));
      expect(session.isActive, isFalse);
    });

    test('start() es no-op si ya había una sesión activa — nunca dos '
        'sesiones superpuestas sobre la misma pantalla', () async {
      var now = DateTime(2024, 1, 1, 12);
      final coins = FloplyCoinsService(
        store: InMemoryCoinsEconomyStore(),
        clock: () => now,
      );
      await coins.load();
      final session = EconomySession(
        coins: coins,
        checkpointInterval: const Duration(milliseconds: 20),
        clock: () => now,
      );
      session.start();
      session.start(); // segunda llamada: no reinicia nada.
      now = now.add(const Duration(minutes: 3));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(coins.availableTime,
          CoinsEconomyState.maxAvailableTime - const Duration(minutes: 3));
      session.dispose();
    });
  });
}

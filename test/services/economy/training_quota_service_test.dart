import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/persistence/training_quota_store.dart';
import 'package:poker_trainer/services/economy/training_quota_service.dart';

class _FakeClock {
  DateTime _now = DateTime(2026, 9, 29, 10);
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
  void jumpTo(DateTime t) => _now = t;
}

void main() {
  late _FakeClock clock;
  late InMemoryTrainingQuotaStore store;
  late TrainingQuotaService service;

  Future<void> setUp_() async {
    clock = _FakeClock();
    store = InMemoryTrainingQuotaStore();
    service = TrainingQuotaService(store: store, clock: clock.call);
    await service.load();
  }

  group('Entrenamientos diarios — cupo del día', () {
    test('11. comienza con 5 disponibles', () async {
      await setUp_();
      expect(service.remaining, 5);
    });

    test('12. consume correctamente', () async {
      await setUp_();
      await service.consumeTraining();
      await service.consumeTraining();
      expect(service.remaining, 3);
    });

    test('13. llega a 0 y no baja de ahí', () async {
      await setUp_();
      for (var i = 0; i < 5; i++) {
        expect(await service.consumeTraining(), isTrue);
      }
      expect(service.remaining, 0);

      final consumedAtZero = await service.consumeTraining();
      expect(consumedAtZero, isFalse);
      expect(service.remaining, 0);
    });

    test('14. no se restaura el mismo día calendario, aunque pasen varias '
        'horas', () async {
      await setUp_();
      await service.consumeTraining();
      await service.consumeTraining();
      clock.advance(const Duration(hours: 10)); // sigue siendo el mismo día
      expect(service.remaining, 3);
    });

    test('15. se restaura a 5 al cruzar al día calendario siguiente',
        () async {
      await setUp_();
      await service.consumeTraining();
      await service.consumeTraining();
      expect(service.remaining, 3);

      clock.jumpTo(DateTime(2026, 9, 30, 0, 5)); // ya es el día siguiente
      expect(service.remaining, 5);
    });

    test('16. no depende de una ventana de 24 horas exactas: cruzar la '
        'medianoche alcanza aunque hayan pasado solo minutos reales',
        () async {
      await setUp_();
      clock.jumpTo(DateTime(2026, 9, 29, 23, 58));
      await service.consumeTraining();
      expect(service.remaining, 4);

      clock.jumpTo(DateTime(2026, 9, 30, 0, 1)); // 3 minutos después
      expect(service.remaining, 5); // ya se restableció

      clock.jumpTo(DateTime(2026, 9, 30, 23, 0)); // 23h después del primero
      await service.consumeTraining();
      expect(service.remaining, 4); // todavía el mismo día (30), no reset
    });

    test('saltarse varios días no acumula entrenamientos: siempre '
        'restablece a exactamente 5, nunca 5×días', () async {
      await setUp_();
      await service.consumeTraining();
      clock.jumpTo(DateTime(2026, 10, 5)); // una semana después
      expect(service.remaining, 5);
    });
  });

  group('Entrenamientos diarios — persistencia', () {
    test('el cupo consumido hoy sobrevive cerrar y reabrir la app',
        () async {
      await setUp_();
      await service.consumeTraining();
      await service.consumeTraining();

      final reopened = TrainingQuotaService(store: store, clock: clock.call);
      await reopened.load();
      expect(reopened.remaining, 3);
    });

    test('reabrir al día siguiente restaura 5, incluso con estado '
        'persistido de ayer', () async {
      await setUp_();
      await service.consumeTraining();

      clock.jumpTo(DateTime(2026, 9, 30, 9));
      final reopened = TrainingQuotaService(store: store, clock: clock.call);
      await reopened.load();
      expect(reopened.remaining, 5);
    });
  });
}

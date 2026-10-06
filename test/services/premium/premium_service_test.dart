import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/services/premium/premium_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Implementación de prueba que cualquier consumidor futuro podría usar
/// para simular un usuario Premium sin billing real.
class _FakePremiumService extends PremiumService {
  _FakePremiumService(this.isPremium);

  @override
  final bool isPremium;

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
  group('PremiumService', () {
    test('22. isPremium puede consultarse sin implementar billing — el '
        'stub de esta fase siempre da false', () {
      final service = StubPremiumService();
      expect(service.isPremium, isFalse);
    });

    test('23. la arquitectura está preparada para un bypass futuro: '
        'cualquier código que dependa de PremiumService (la interfaz, no '
        'del stub concreto) funciona igual si el día de mañana isPremium '
        'da true', () {
      PremiumService service = StubPremiumService();
      expect(service.isPremium, isFalse);

      // Sin tocar ningún otro archivo, una implementación distinta de la
      // MISMA interfaz alcanza para "activar" Premium en todo lo que
      // dependa de PremiumService.
      service = _FakePremiumService(true);
      expect(service.isPremium, isTrue);
    });
  });
}

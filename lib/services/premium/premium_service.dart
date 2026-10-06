import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Abstracción de estado Premium — fuente única de verdad para "¿esta
/// cuenta tiene acceso ilimitado?". Extiende [ChangeNotifier] para que los
/// widgets puedan escuchar cambios en tiempo real (compra completada,
/// restauración, cambio de usuario).
///
/// La implementación real es [RevenueCatPremiumService]. [StubPremiumService]
/// existe únicamente para tests y para entornos donde el billing no está
/// disponible — siempre devuelve `false`.
abstract class PremiumService extends ChangeNotifier {
  bool get isPremium;

  /// `true` mientras se está resolviendo el estado inicial (primer fetch a
  /// RevenueCat al arrancar). Los widgets deben mostrar un indicador de carga
  /// mientras sea `true`.
  bool get isLoading;

  /// Devuelve las Offerings configuradas en el dashboard de RevenueCat, o
  /// `null` si no se pudieron cargar (sin red, clave pendiente, error RC).
  Future<Offerings?> getOfferings();

  /// Inicia la compra de [package]. Devuelve `true` si la compra se
  /// completó y el entitlement quedó activo.
  Future<bool> purchasePackage(Package package);

  /// Restaura compras previas. Devuelve `true` si el entitlement quedó activo
  /// tras la restauración.
  Future<bool> restorePurchases();
}

/// Solo para tests y entornos sin RevenueCat configurado.
class StubPremiumService extends PremiumService {
  @override
  bool get isPremium => false;

  @override
  bool get isLoading => false;

  @override
  Future<Offerings?> getOfferings() async => null;

  @override
  Future<bool> purchasePackage(Package package) async => false;

  @override
  Future<bool> restorePurchases() async => false;
}

import 'package:purchases_flutter/purchases_flutter.dart';

import 'premium_service.dart';
import 'revenue_cat_config.dart';

/// Implementación real de [PremiumService] respaldada por RevenueCat.
///
/// Ciclo de vida:
///   1. [initialize] — se llama UNA SOLA VEZ desde [_PokerTrainerAppState],
///      antes de que se monte [AuthGate]/[AppShell]. Configura el SDK y
///      obtiene el estado inicial del entitlement.
///   2. [onUserChanged] — se llama cada vez que cambia el estado de auth
///      (inicio de sesión / cierre). Sincronizia el `appUserID` de RevenueCat
///      con el UID de Firebase para que las compras sean portables.
///   3. RC notifica cambios vía listener → [notifyListeners] → widgets
///      reconstruyen automáticamente.
class RevenueCatPremiumService extends PremiumService {
  bool _isPremium = false;
  bool _isLoading = true;
  bool _initialized = false;

  @override
  bool get isPremium => _isPremium;

  @override
  bool get isLoading => _isLoading;

  // Mismo tear-off en toda la vida del objeto — necesario para poder llamar
  // removeCustomerInfoUpdateListener con la misma referencia.
  late final void Function(CustomerInfo) _listener = _onCustomerInfoUpdated;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final config = PurchasesConfiguration(RevenueCatConfig.androidApiKey);
    await Purchases.configure(config);
    Purchases.addCustomerInfoUpdateListener(_listener);
    try {
      final info = await Purchases.getCustomerInfo();
      _onCustomerInfoUpdated(info);
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    final newPremium =
        info.entitlements.active.containsKey(RevenueCatConfig.entitlementId);
    final changed = newPremium != _isPremium || _isLoading;
    _isPremium = newPremium;
    _isLoading = false;
    if (changed) notifyListeners();
  }

  /// Sincroniza el usuario de RevenueCat con el estado de auth.
  /// - [firebaseUid] != null → logIn (usuario autenticado).
  /// - [firebaseUid] == null → logOut (invitado / no autenticado).
  /// Los errores se descartan silenciosamente: la sesión RC anterior sigue
  /// siendo válida y el estado de entitlement se mantiene.
  Future<void> onUserChanged(String? firebaseUid) async {
    if (!_initialized) return;
    if (firebaseUid != null) {
      try {
        await Purchases.logIn(firebaseUid);
      } catch (_) {}
    } else {
      try {
        await Purchases.logOut();
      } catch (_) {}
    }
  }

  @override
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _onCustomerInfoUpdated(result.customerInfo);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _onCustomerInfoUpdated(info);
      return _isPremium;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      Purchases.removeCustomerInfoUpdateListener(_listener);
    }
    super.dispose();
  }
}

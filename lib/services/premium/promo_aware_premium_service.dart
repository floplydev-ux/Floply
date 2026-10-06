import 'package:purchases_flutter/purchases_flutter.dart';

import '../promo/promo_code_service.dart';
import 'premium_service.dart';
import 'reviewer_claims_service.dart';

/// Envuelve un [PremiumService] base (RevenueCat) y añade dos carriles
/// adicionales de acceso Premium:
///
/// - **Promo**: [PromoCodeService] — códigos redimibles por cualquier usuario.
/// - **Reviewer**: [ReviewerClaimsService] — Firebase Custom Claim exclusivo
///   para la cuenta de Google Play Reviewer, asignado vía Admin SDK.
///
/// [isPremium] es `true` si CUALQUIERA de los tres carriles lo es. Una única
/// fuente de verdad — ninguna pantalla necesita saber cómo se combinan.
class PromoAwarePremiumService extends PremiumService {
  PromoAwarePremiumService({
    required PremiumService base,
    required PromoCodeService promo,
    required ReviewerClaimsService reviewer,
  })  : _base = base,
        _promo = promo,
        _reviewer = reviewer {
    _base.addListener(_notify);
    _promo.addListener(_notify);
    _reviewer.addListener(_notify);
  }

  final PremiumService _base;
  final PromoCodeService _promo;
  final ReviewerClaimsService _reviewer;

  /// Expone el servicio de promos para que [PremiumPaywallScreen] pueda
  /// construir la sección de canje sin necesidad de inyectar una referencia
  /// separada por todo el árbol de widgets.
  PromoCodeService get promoService => _promo;

  void _notify() => notifyListeners();

  @override
  bool get isPremium =>
      _base.isPremium || _promo.isPromoActive || _reviewer.isReviewer;

  @override
  bool get isLoading => _base.isLoading;

  @override
  Future<Offerings?> getOfferings() => _base.getOfferings();

  @override
  Future<bool> purchasePackage(Package package) =>
      _base.purchasePackage(package);

  @override
  Future<bool> restorePurchases() => _base.restorePurchases();

  @override
  void dispose() {
    _base.removeListener(_notify);
    _promo.removeListener(_notify);
    _reviewer.removeListener(_notify);
    // No se disposan _base, _promo ni _reviewer aquí — son owned por
    // _PokerTrainerAppState.
    super.dispose();
  }
}

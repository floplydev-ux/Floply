import 'promo_code_failure.dart';
import 'promo_code_service.dart';

/// Implementación en memoria para tests — no toca Firebase.
class FakePromoCodeService extends PromoCodeService {
  PromoCodeResult? _nextResult;
  DateTime? _promoExpiresAt;

  /// El próximo [redeem] devolverá [result].
  void queueResult(PromoCodeResult result) => _nextResult = result;

  /// Simula que la promo vence en [expiry] (notifica listeners).
  void setPromoExpiry(DateTime? expiry) {
    _promoExpiresAt = expiry;
    notifyListeners();
  }

  @override
  DateTime? get promoExpiresAt => _promoExpiresAt;

  @override
  bool get isPromoActive {
    final expiry = _promoExpiresAt;
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  @override
  Future<PromoCodeResult> redeem(String code) async {
    final result = _nextResult ?? const PromoCodeFailure(PromoCodeFailureReason.serverError);
    _nextResult = null;
    if (result is PromoCodeSuccess) {
      // Simula que el backend pone promoExpiresAt en 30 días.
      _promoExpiresAt = DateTime.now().add(const Duration(days: 30));
      notifyListeners();
    }
    return result;
  }

  @override
  void onUserChanged(String? uid) {}

  @override
  void dispose() {
    // noop — ValueNotifier.dispose() se encarga.
    super.dispose();
  }
}

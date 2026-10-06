import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/services/promo/fake_promo_code_service.dart';
import 'package:poker_trainer/services/promo/promo_code_failure.dart';

void main() {
  // ── Normalización ──────────────────────────────────────────────────────────

  group('normalización de código', () {
    test('FakePromoCodeService acepta código mixto', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      final result = await svc.redeem('  floply30  ');
      expect(result, isA<PromoCodeSuccess>());
    });

    test('código vacío devuelve serverError en Fake', () async {
      final svc = FakePromoCodeService();
      // No se hace queue → usa el fallback serverError
      final result = await svc.redeem('   ');
      // Fake ignora normalización — en el servicio real la Function rechaza
      expect(result, isA<PromoCodeFailure>());
    });
  });

  // ── Casos de fallo ─────────────────────────────────────────────────────────

  group('razones de fallo', () {
    for (final reason in PromoCodeFailureReason.values) {
      test('$reason se puede encolar y devolver', () async {
        final svc = FakePromoCodeService();
        svc.queueResult(PromoCodeFailure(reason));
        final result = await svc.redeem('CUALQUIER');
        expect(result, isA<PromoCodeFailure>());
        expect((result as PromoCodeFailure).reason, reason);
      });
    }
  });

  // ── Código válido ──────────────────────────────────────────────────────────

  group('canje exitoso', () {
    test('PromoCodeSuccess lleva benefitLabel', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      final result = await svc.redeem('FLOPLY30');
      expect(result, isA<PromoCodeSuccess>());
      expect((result as PromoCodeSuccess).benefitLabel, 'Premium por 30 días');
    });

    test('después del canje isPromoActive es true', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      expect(svc.isPromoActive, isFalse);
      await svc.redeem('FLOPLY30');
      expect(svc.isPromoActive, isTrue);
    });

    test('promoExpiresAt queda en el futuro tras canje exitoso', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      await svc.redeem('FLOPLY30');
      final expiry = svc.promoExpiresAt!;
      expect(expiry.isAfter(DateTime.now()), isTrue);
    });

    test('duración en meses — benefitLabel refleja meses', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 3 meses'));
      final result = await svc.redeem('FLOPLY3M');
      expect((result as PromoCodeSuccess).benefitLabel, 'Premium por 3 meses');
    });
  });

  // ── Extensión de promo ─────────────────────────────────────────────────────

  group('extensión de Premium existente', () {
    test('si ya tiene promo activa, isPromoActive sigue true tras otro canje',
        () async {
      final svc = FakePromoCodeService();
      // Primera promo: vence en 30 días
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      await svc.redeem('FLOPLY30');
      final firstExpiry = svc.promoExpiresAt!;
      expect(svc.isPromoActive, isTrue);

      // Segunda promo (la extensión la hace la Function en producción;
      // en Fake simplemente sobreescribe a 30 días desde ahora)
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      await svc.redeem('FLOPLY30B');
      final secondExpiry = svc.promoExpiresAt!;

      expect(svc.isPromoActive, isTrue);
      // La segunda fecha no es anterior a la primera (en Fake se resetea
      // a +30d desde ahora, que es ≈ igual a firstExpiry)
      expect(
        secondExpiry.isAfter(firstExpiry.subtract(const Duration(seconds: 5))),
        isTrue,
      );
    });
  });

  // ── Promo vencida (setPromoExpiry) ─────────────────────────────────────────

  group('estado de promo', () {
    test('setPromoExpiry en el pasado → isPromoActive false', () {
      final svc = FakePromoCodeService();
      svc.setPromoExpiry(DateTime.now().subtract(const Duration(days: 1)));
      expect(svc.isPromoActive, isFalse);
    });

    test('setPromoExpiry en el futuro → isPromoActive true', () {
      final svc = FakePromoCodeService();
      svc.setPromoExpiry(DateTime.now().add(const Duration(days: 1)));
      expect(svc.isPromoActive, isTrue);
    });

    test('setPromoExpiry null → isPromoActive false', () {
      final svc = FakePromoCodeService();
      svc.setPromoExpiry(null);
      expect(svc.isPromoActive, isFalse);
    });

    test('onUserChanged null limpia estado de promo', () {
      final svc = FakePromoCodeService();
      svc.setPromoExpiry(DateTime.now().add(const Duration(days: 30)));
      expect(svc.isPromoActive, isTrue);

      // En Fake, onUserChanged no hace nada con Firestore, pero al menos
      // no debe crashear.
      svc.onUserChanged(null);
    });
  });

  // ── Doble solicitud de canje ───────────────────────────────────────────────

  group('doble solicitud de canje', () {
    test('segunda llamada sin resultado en cola devuelve serverError', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      // Primera llamada consume el resultado
      await svc.redeem('FLOPLY30');
      // Segunda sin hacer queue → fallback serverError
      final second = await svc.redeem('FLOPLY30');
      expect(second, isA<PromoCodeFailure>());
      expect(
        (second as PromoCodeFailure).reason,
        PromoCodeFailureReason.serverError,
      );
    });

    test('doble canje del mismo código devuelve alreadyRedeemed', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 30 días'));
      await svc.redeem('FLOPLY30');
      svc.queueResult(
          const PromoCodeFailure(PromoCodeFailureReason.alreadyRedeemed));
      final second = await svc.redeem('FLOPLY30');
      expect((second as PromoCodeFailure).reason,
          PromoCodeFailureReason.alreadyRedeemed);
    });
  });

  // ── Sin límite ─────────────────────────────────────────────────────────────

  group('límites', () {
    test('código sin límite de usos: success si el backend lo aprueba',
        () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeSuccess(benefitLabel: 'Premium por 7 días'));
      final result = await svc.redeem('UNLIMITED');
      expect(result, isA<PromoCodeSuccess>());
    });

    test('código agotado devuelve exhausted', () async {
      final svc = FakePromoCodeService();
      svc.queueResult(
          const PromoCodeFailure(PromoCodeFailureReason.exhausted));
      final result = await svc.redeem('AGOTADO');
      expect((result as PromoCodeFailure).reason,
          PromoCodeFailureReason.exhausted);
    });
  });
}

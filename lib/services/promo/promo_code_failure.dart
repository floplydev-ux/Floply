/// Razones por las que un canje puede fallar — la capa de dominio nunca
/// expone excepciones de Firebase ni textos técnicos a la UI.
enum PromoCodeFailureReason {
  notFound,
  inactive,
  notStarted,
  expired,
  exhausted,
  alreadyRedeemed,
  unauthenticated,
  serverError,
}

/// Resultado sellado de [PromoCodeService.redeem].
sealed class PromoCodeResult {
  const PromoCodeResult();
}

/// El canje fue exitoso. [benefitLabel] es el texto a mostrar al usuario,
/// construido por el backend (ej. "Premium por 30 días").
class PromoCodeSuccess extends PromoCodeResult {
  const PromoCodeSuccess({required this.benefitLabel});
  final String benefitLabel;
}

/// El canje falló por [reason]. La UI mapea esto a un mensaje amigable.
class PromoCodeFailure extends PromoCodeResult {
  const PromoCodeFailure(this.reason);
  final PromoCodeFailureReason reason;
}

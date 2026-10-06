/// Configuración de RevenueCat — claves públicas y constantes del producto.
///
/// **PENDIENTE DE CONFIGURACIÓN**: `androidApiKey` debe reemplazarse con la
/// clave pública SDK real antes de publicar en Google Play.
/// Para obtenerla:
///   1. Crear la app Android en el panel de RevenueCat (app.revenuecat.com).
///   2. Copiar la "Public SDK key" en API Keys → Apps.
///   3. Reemplazar la constante abajo.
///   4. Confirmar que el entitlement `"premium"` existe en el dashboard.
///
/// NO guardar en este archivo: service accounts, claves privadas, secretos
/// del server de RevenueCat ni credenciales de Google Play.
abstract final class RevenueCatConfig {
  /// Clave pública SDK de Android (Public API Key — no es un secreto,
  /// es la misma clave que el SDK embebe en el binario de la app).
  static const String androidApiKey = 'goog_iPMGkxgmKajcwdtwSbavMarwJmH';

  /// Identificador exacto del entitlement Premium en RevenueCat Dashboard.
  static const String entitlementId = 'premium';
}

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

bool _initialized = false;

/// Inicializa el SDK de Google Mobile Ads — una única vez por proceso, y
/// solo en plataformas móviles reales: en Web no existe soporte nativo de
/// `google_mobile_ads`, así que ni se intenta (evita romper la build/
/// ejecución web, ver el pedido de compatibilidad web).
///
/// Debe llamarse una sola vez, al arrancar la app (`main.dart`), antes de
/// intentar cargar cualquier anuncio — `RewardedAdService` no lo vuelve a
/// llamar por su cuenta.
Future<void> initializeMobileAdsSdk() async {
  if (kIsWeb || _initialized) return;
  _initialized = true;
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // best-effort: si el SDK no puede inicializar (Google Play Services
    // ausente/desactualizado, etc.), la app sigue funcionando — no va a
    // haber Rewarded Ads disponibles, y `RewardedAdService` ya maneja "no
    // hay anuncio listo" como un resultado normal, nunca una excepción
    // que llegue hasta la UI.
  }
}

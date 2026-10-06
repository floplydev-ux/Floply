import 'package:flutter/foundation.dart';

/// Configuración centralizada de unidades de anuncio — **nunca** hardcodear
/// un Ad Unit ID directamente en la lógica de negocio (`RewardedAdService`
/// y compañía lo leen de acá, nada más).
///
/// En debug se usan los IDs de PRUEBA oficiales de Google (ver
/// https://developers.google.com/admob/android/test-ads).
/// En release se usan los IDs reales de FLOPly, que deben completarse en
/// [_productionRewardedAdUnitId] y [_productionBannerAdUnitId].
/// ACCIÓN EXTERNA: crear las unidades de anuncio en AdMob Console para
/// FLOPly y completar las constantes de producción en este archivo.
class AdConfig {
  const AdConfig._();

  /// `true` en debug — fuerza el uso del ID de prueba de Google.
  /// En release ([kDebugMode] == false) se usarán los IDs de producción
  /// siempre que [_productionRewardedAdUnitId] no esté vacío.
  /// ACCIÓN EXTERNA: una vez completados los IDs reales, este flag
  /// cambiará automáticamente en el build de release.
  static const bool useTestAds = kDebugMode;

  /// Rewarded Ad Unit ID de prueba oficial de Google para Android — el
  /// mismo para cualquier app durante desarrollo. NUNCA un ID real de
  /// FLOPly.
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// Ad Unit ID real de FLOPly para Rewarded — producción.
  static const String _productionRewardedAdUnitId = 'ca-app-pub-3250574167221735/8818948771';

  /// El Ad Unit ID que corresponde usar ahora mismo — de prueba mientras
  /// [useTestAds] sea `true` o no haya todavía un ID real cargado.
  static String get rewardedAdUnitId =>
      useTestAds || _productionRewardedAdUnitId.isEmpty
          ? _testRewardedAdUnitId
          : _productionRewardedAdUnitId;

  // ── Banner — lección completada ────────────────────────────────────────────

  /// Banner Ad Unit ID de prueba oficial de Google para Android.
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';

  /// Ad Unit ID real de FLOPly para Banner (lección completada) — producción.
  static const String _productionBannerAdUnitId = 'ca-app-pub-3250574167221735/2525003164';

  static String get lessonCompletionBannerAdUnitId =>
      useTestAds || _productionBannerAdUnitId.isEmpty
          ? _testBannerAdUnitId
          : _productionBannerAdUnitId;
}

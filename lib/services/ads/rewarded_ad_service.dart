import '../economy/coins_economy_state.dart';
import '../economy/floply_coins_service.dart';

/// Resultado de intentar mostrar un Rewarded Ad para ganar una Coin — la UI
/// (Fase 2) puede mostrar un mensaje distinto para cada caso, en vez de un
/// simple éxito/fracaso.
enum RewardedAdShowResult {
  /// El usuario terminó de ver el anuncio, AdMob confirmó la recompensa
  /// (`onUserEarnedReward`), y la economía sumó 1 Coin de verdad.
  rewardGranted,

  /// AdMob confirmó la recompensa, pero la economía la rechazó (ya estaba
  /// lleno de Coins o ya agotó el cupo de 3 cada 12 horas) — nunca se
  /// pierde silenciosamente: se distingue de [rewardGranted] a propósito.
  rewardRejectedByEconomy,

  /// No había ningún anuncio listo para mostrar (todavía cargando, o la
  /// carga falló) — no es un error del usuario.
  notAvailable,

  /// El usuario cerró el anuncio antes de completarlo — nunca otorga
  /// recompensa (ver el pedido: "el click no otorga recompensa").
  dismissedWithoutReward,

  /// La plataforma actual no soporta Rewarded Ads (Web) — nunca se intenta
  /// tocar el SDK ahí.
  unsupportedPlatform,
}

/// Contrato que la UI (Fase 2) va a usar para pedir un Rewarded Ad — nunca
/// conoce detalles de `google_mobile_ads` ni de AdMob: solo pide mostrar el
/// anuncio y recibe un [RewardedAdShowResult] claro. La decisión de sumar
/// la Coin vive siempre en la capa de economía ([FloplyCoinsService]),
/// nunca acá ni en la UI — ver [resolveRewardedAdOutcome].
abstract class RewardedAdService {
  /// `true` si ya hay un anuncio precargado, listo para mostrarse sin
  /// demora.
  bool get isReady;

  /// Precarga un anuncio para la próxima vez — no otorga nada por sí sola.
  Future<void> preload();

  /// Muestra el anuncio (precargándolo antes si hace falta) y, solo si
  /// AdMod confirma la recompensa, la acredita en la economía.
  Future<RewardedAdShowResult> showForCoinReward();
}

/// La única función que decide si una recompensa de publicidad se traduce
/// en una Coin — compartida por [AdMobRewardedAdService] (real,
/// `admob_rewarded_ad_service.dart`) y `FakeRewardedAdService` (tests,
/// `fake_rewarded_ad_service.dart`): ambas terminan pasando por acá, así
/// que un test contra la fake ejercita exactamente la misma decisión que
/// tomaría la implementación real, no una reimplementación paralela que
/// podría desincronizarse.
///
/// [earnedReward] tiene que venir de una confirmación real (el callback
/// `onUserEarnedReward` del SDK, o su simulación explícita en tests) —
/// nunca de "el usuario tocó el botón" ni de "el anuncio se mostró".
Future<RewardedAdShowResult> resolveRewardedAdOutcome({
  required bool earnedReward,
  required FloplyCoinsService coins,
}) async {
  if (!earnedReward) return RewardedAdShowResult.dismissedWithoutReward;
  final result = await coins.grantAdReward();
  return result == AdRewardGrantResult.granted
      ? RewardedAdShowResult.rewardGranted
      : RewardedAdShowResult.rewardRejectedByEconomy;
}

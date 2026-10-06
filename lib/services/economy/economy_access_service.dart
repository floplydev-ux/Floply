import '../ads/rewarded_ad_service.dart';
import '../premium/premium_service.dart';
import 'coins_economy_state.dart';
import 'floply_coins_service.dart';
import 'training_quota_service.dart';

/// Por qué se puede (o no) acceder a una función paga — nunca un `bool`
/// suelto: la UI necesita el motivo exacto para elegir qué mostrar.
enum EconomyAccessStatus {
  /// Premium: acceso total, nunca consume nada.
  premium,

  /// Solo para Campo de Entrenamiento: todavía quedan entrenamientos
  /// gratis hoy (Training Quota) — no consume Coins.
  freeTraining,

  /// Hay tiempo disponible (Coins) — se puede iniciar/continuar la
  /// sesión paga (Tools, Coach, o entrenamiento extra).
  accessible,

  /// Sin tiempo disponible: bloqueado. Ver [EconomyAccessDecision] para
  /// las alternativas (anuncio / próxima regeneración).
  noCoins,
}

/// El resultado completo de una consulta de acceso — estado + todo lo
/// que la UI necesita para explicar la alternativa (nunca recalculado
/// aparte: son los mismos datos que ya exponen los servicios reales).
class EconomyAccessDecision {
  const EconomyAccessDecision({
    required this.status,
    required this.canWatchRewardedAd,
    required this.rewardedAdsRemainingInWindow,
    required this.nextRegenerationAt,
    this.trainingRemainingToday,
    this.trainingResetDate,
  });

  final EconomyAccessStatus status;

  /// `true` si en este momento tiene sentido ofrecer "Ver anuncio +1
  /// Coin" (no está lleno de Coins Y no agotó el cupo de la ventana de
  /// 12 horas) — la decisión FINAL y autoritativa de si realmente se
  /// acredita sigue siendo [EconomyAccessService.watchRewardedAd].
  final bool canWatchRewardedAd;

  final int rewardedAdsRemainingInWindow;

  /// `null` si ya está al máximo de Coins (no hay "próxima" mientras no
  /// se gaste nada).
  final DateTime? nextRegenerationAt;

  /// Solo poblado cuando la consulta fue sobre Campo de Entrenamiento.
  final int? trainingRemainingToday;
  final DateTime? trainingResetDate;

  /// `true` salvo [EconomyAccessStatus.noCoins] — el único estado que
  /// bloquea de verdad.
  bool get isGranted => status != EconomyAccessStatus.noCoins;

  /// `true` solo cuando acceder implica empezar a consumir tiempo real
  /// (nunca para `premium` ni para `freeTraining`, que no tocan Coins).
  bool get consumesCoins => status == EconomyAccessStatus.accessible;
}

/// La única capa de decisión de producto para toda la economía de
/// FLOPly — combina [FloplyCoinsService] + [TrainingQuotaService] +
/// [PremiumService] + [RewardedAdService] para responder preguntas de
/// alto nivel ("¿puede abrir Tools?", "¿puede iniciar un entrenamiento
/// extra?"), para que ninguna pantalla tenga que armar esa combinación
/// a mano.
///
/// No es un [ChangeNotifier] propio ni una fuente de verdad nueva: cada
/// consulta lee los servicios reales en el momento (mismo criterio que
/// [EconomySnapshot]) — la UI sigue escuchando los `ChangeNotifier`
/// reales ([coins]/[training]) para saber cuándo recalcular.
class EconomyAccessService {
  const EconomyAccessService({
    required this.coins,
    required this.training,
    required this.premium,
    required this.ads,
  });

  final FloplyCoinsService coins;
  final TrainingQuotaService training;
  final PremiumService premium;
  final RewardedAdService ads;

  bool get isPremium => premium.isPremium;

  /// Tools y Coach comparten exactamente este gate — mismo costo por
  /// minuto, mismo comportamiento en 0 Coins (pedido explícito: "mismo
  /// gate de entrada"). También es el gate del entrenamiento EXTRA (más
  /// allá del cupo gratis), que funciona como cualquier otra sesión
  /// paga por tiempo.
  EconomyAccessDecision checkTimedAccess() => _decide();

  /// Campo de Entrenamiento: distingue el cupo gratis del diario (no
  /// consume Coins) de la necesidad de pagar con Coins una vez agotado.
  EconomyAccessDecision checkTrainingAccess() {
    if (premium.isPremium) return _premiumDecision();
    if (training.hasFreeTrainingLeft) {
      return EconomyAccessDecision(
        status: EconomyAccessStatus.freeTraining,
        canWatchRewardedAd: false,
        rewardedAdsRemainingInWindow: _adsRemaining,
        nextRegenerationAt: coins.nextRegenerationAt,
        trainingRemainingToday: training.remaining,
        trainingResetDate: training.resetDate,
      );
    }
    return _decide(includeTrainingContext: true);
  }

  EconomyAccessDecision _decide({bool includeTrainingContext = false}) {
    if (premium.isPremium) return _premiumDecision();
    // La fuente de verdad real es el tiempo (ver el doc-comment de
    // `CoinsEconomyState`), nunca la proyección entera de `coins`: un
    // resto de minutos por debajo de una Coin completa sigue siendo
    // tiempo real y utilizable, no hay que bloquear el acceso solo
    // porque todavía no redondeó a una Coin entera.
    final hasTime = coins.availableTime > Duration.zero;
    return EconomyAccessDecision(
      status: hasTime ? EconomyAccessStatus.accessible : EconomyAccessStatus.noCoins,
      canWatchRewardedAd: coins.canRequestAdReward && ads.isReady,
      rewardedAdsRemainingInWindow: _adsRemaining,
      nextRegenerationAt: coins.nextRegenerationAt,
      trainingRemainingToday: includeTrainingContext ? training.remaining : null,
      trainingResetDate: includeTrainingContext ? training.resetDate : null,
    );
  }

  EconomyAccessDecision _premiumDecision() => EconomyAccessDecision(
        status: EconomyAccessStatus.premium,
        canWatchRewardedAd: false,
        rewardedAdsRemainingInWindow: _adsRemaining,
        nextRegenerationAt: coins.nextRegenerationAt,
        trainingRemainingToday: training.remaining,
        trainingResetDate: training.resetDate,
      );

  int get _adsRemaining =>
      (CoinsEconomyState.maxRewardedAdsPerWindow - coins.rewardedAdsUsedInWindow)
          .clamp(0, CoinsEconomyState.maxRewardedAdsPerWindow);

  /// Confirma el inicio de un entrenamiento gratis — consume 1 Training
  /// Quota. El caller es responsable de llamarlo una única vez, recién
  /// al confirmar que la sesión arranca de verdad (nunca desde
  /// `build()`/un rebuild) — mismo contrato que ya documenta
  /// [TrainingQuotaService.consumeTraining].
  Future<bool> confirmFreeTrainingStart() => training.consumeTraining();

  /// Muestra un Rewarded Ad real y, si AdMob confirma la recompensa
  /// (`onUserEarnedReward`), acredita la Coin — nunca antes. Delega por
  /// completo en [RewardedAdService]/[resolveRewardedAdOutcome]: esta
  /// clase no decide nada de publicidad por su cuenta.
  Future<RewardedAdShowResult> watchRewardedAd() => ads.showForCoinReward();
}

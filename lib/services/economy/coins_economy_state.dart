/// El resultado de intentar otorgar +1 Coin por publicidad
/// ([CoinsEconomyState.grantingAdReward]) — nunca un `bool` suelto: la UI
/// (Fase 2) necesita distinguir "ya está lleno" de "ya viste demasiados
/// anuncios por ahora" para mostrar el mensaje correcto.
enum AdRewardGrantResult {
  /// Se sumó 1 Coin de verdad.
  granted,

  /// El usuario ya tiene el máximo de Coins — la recompensa no puede
  /// llevarlo por encima de 6.
  rejectedAtMaxCoins,

  /// Ya se otorgaron `maxRewardedAdsPerWindow` recompensas dentro de
  /// [CoinsEconomyState.rewardedAdsWindow].
  rejectedRateLimited,
}

/// El resultado de [CoinsEconomyState.grantingAdReward]: el estado nuevo
/// (con la Coin ya sumada, si correspondía) junto con qué pasó.
class CoinsGrantOutcome {
  const CoinsGrantOutcome(this.state, this.result);

  final CoinsEconomyState state;
  final AdRewardGrantResult result;
}

/// El estado completo de la economía de FLOPly Coins — **fuente de verdad
/// única**, e inmutable: cada método devuelve un [CoinsEconomyState] nuevo,
/// nunca muta `this`. Vive independiente de cualquier motor de póker, de
/// Firebase o de widgets: es aritmética pura sobre [Duration]/[DateTime].
///
/// La unidad de cuenta REAL es [availableTime] (tiempo, no "Coins" —
/// pedido explícito de Fase 1: "la economía debe manejar tiempo real
/// disponible", nunca "abrir una herramienta = -1 Coin"). [coins] es una
/// proyección de solo lectura para mostrarle algo simple al usuario.
///
/// Regeneración: nunca depende de un `Timer` corriendo mientras la app
/// está abierta — [regenerationAnchor] es el único timestamp persistido, y
/// [advanced] recalcula desde ahí de forma determinista sea cual sea el
/// tiempo real transcurrido (cerrar la app una hora, un día, una semana).
/// Ver el doc-comment de [advanced] para el manejo del tope de 6 Coins.
class CoinsEconomyState {
  const CoinsEconomyState({
    required this.availableTime,
    required this.regenerationAnchor,
    this.adRewardGrants = const [],
  });

  /// Máximo de Coins acumulables.
  static const int maxCoins = 6;

  /// Cuánto tiempo de uso de herramientas representa 1 Coin.
  static const Duration timePerCoin = Duration(minutes: 15);

  /// Tope real del pool de tiempo — exactamente `maxCoins * timePerCoin`
  /// (90 minutos), nunca un número mágico aparte.
  static const Duration maxAvailableTime = Duration(minutes: 90);

  /// Cada cuánto se regenera 1 Coin (15 minutos de tiempo) mientras no se
  /// esté en el tope.
  static const Duration regenerationInterval = Duration(minutes: 60);

  /// Máximo de recompensas publicitarias otorgadas dentro de
  /// [rewardedAdsWindow].
  static const int maxRewardedAdsPerWindow = 3;

  static const Duration rewardedAdsWindow = Duration(hours: 12);

  /// El pool de tiempo disponible — la fuente de verdad real (ver el
  /// doc-comment de la clase). Nunca negativo, nunca por encima de
  /// [maxAvailableTime] (ambos invariantes los mantienen los métodos de
  /// esta clase, nunca el caller).
  final Duration availableTime;

  /// Desde cuándo se cuenta el tiempo transcurrido para la próxima
  /// regeneración — la única fuente de verdad de la regeneración (nunca
  /// un `Timer`). Ver [advanced].
  final DateTime regenerationAnchor;

  /// Timestamps de recompensas de publicidad ya concedidas (no de
  /// intentos ni de taps) — [advanced] descarta las que ya salieron de
  /// [rewardedAdsWindow], así que esta lista nunca crece sin límite.
  final List<DateTime> adRewardGrants;

  /// Estado inicial de una cuenta nueva: llena (6 Coins / 90 minutos) —
  /// mismo criterio que el ejemplo del pedido ("Estado inicial: coins =
  /// 6, availableMinutes = 90").
  factory CoinsEconomyState.initial(DateTime now) => CoinsEconomyState(
        availableTime: maxAvailableTime,
        regenerationAnchor: now,
      );

  /// Proyección de solo lectura de [availableTime] en "Coins" completas —
  /// nunca la fuente de verdad (ver el doc-comment de la clase). Una Coin
  /// solo cuenta cuando el bloque de 15 minutos está completo.
  int get coins =>
      (availableTime.inMinutes / timePerCoin.inMinutes).floor().clamp(0, maxCoins);

  int get availableMinutes => availableTime.inMinutes;

  /// Cuándo se sumará la próxima Coin completa por regeneración — `null`
  /// si ya está en el tope (no hay "próxima" mientras no se gaste nada).
  /// Asume que `this` ya está al día (ver [advanced]) — la próxima
  /// regeneración real es siempre `regenerationAnchor + regenerationInterval`
  /// una vez sincronizado.
  DateTime? get nextRegenerationAt =>
      availableTime >= maxAvailableTime ? null : regenerationAnchor.add(regenerationInterval);

  /// Recompensas de publicidad concedidas en las últimas
  /// [rewardedAdsWindow] horas, contadas desde [now] — asume que `this`
  /// ya está al día (ver [advanced]).
  List<DateTime> adRewardGrantsWithin(DateTime now) =>
      adRewardGrants.where((t) => now.difference(t) < rewardedAdsWindow).toList(growable: false);

  /// `true` si en este momento ([now]) se podría conceder otra recompensa
  /// de publicidad: no está lleno Y no se llegó al límite de
  /// [maxRewardedAdsPerWindow] en la ventana. Asume que `this` ya está al
  /// día (ver [advanced]) — el caller (`FloplyCoinsService`) siempre llama
  /// [advanced] antes.
  bool canRequestAdReward(DateTime now) =>
      coins < maxCoins && adRewardGrantsWithin(now).length < maxRewardedAdsPerWindow;

  /// Aplica la regeneración que corresponde por el tiempo real
  /// transcurrido entre [regenerationAnchor] y [now] — pura función de
  /// tiempo, sin ningún `Timer`: da exactamente el mismo resultado sea
  /// cual sea el momento en que se llame (al abrir la app, al consultar
  /// el estado, al consumir tiempo), y sea cual sea cuánto tiempo real
  /// pasó mientras tanto.
  ///
  /// **El tope de 6 Coins nunca acumula crédito de regeneración**: en
  /// cuanto el tiempo disponible llega al máximo, el ancla se adelanta
  /// hasta [now] — así, si el usuario se queda lleno una semana y después
  /// gasta 2 Coins, no recibe instantáneamente todas las Coins que
  /// "debería" haber regenerado esa semana (nunca las acumuló, porque el
  /// ancla nunca se quedó atrás mientras estaba lleno).
  ///
  /// El bucle está acotado a lo sumo a [maxCoins] iteraciones (cada una
  /// suma como mucho 1 Coin y nunca supera el tope), así que da igual si
  /// [now] está a una hora o a un año de [regenerationAnchor].
  CoinsEconomyState advanced(DateTime now) {
    var time = availableTime;
    var anchor = regenerationAnchor;
    while (time < maxAvailableTime) {
      final elapsed = now.difference(anchor);
      if (elapsed < regenerationInterval) break;
      anchor = anchor.add(regenerationInterval);
      final next = time + timePerCoin;
      time = next > maxAvailableTime ? maxAvailableTime : next;
    }
    if (time >= maxAvailableTime && anchor.isBefore(now)) {
      anchor = now;
    }
    return CoinsEconomyState(
      availableTime: time,
      regenerationAnchor: anchor,
      adRewardGrants: adRewardGrants.where((t) => now.difference(t) < rewardedAdsWindow).toList(
            growable: false,
          ),
    );
  }

  /// Consume hasta [amount] del tiempo disponible — nunca deja
  /// [availableTime] negativo: si se pide más de lo que hay, consume solo
  /// lo que queda. Asume que `this` ya está al día (llamar [advanced]
  /// antes) — nunca recalcula regeneración por su cuenta, para no aplicar
  /// el cálculo dos veces.
  CoinsEconomyState consuming(Duration amount) {
    final consumed = amount.isNegative
        ? Duration.zero
        : (amount > availableTime ? availableTime : amount);
    return CoinsEconomyState(
      availableTime: availableTime - consumed,
      regenerationAnchor: regenerationAnchor,
      adRewardGrants: adRewardGrants,
    );
  }

  /// Suma 1 Coin completa (15 minutos), sin superar [maxAvailableTime).
  /// Asume que `this` ya está al día (ver [consuming]).
  CoinsEconomyState addingCoin() {
    final next = availableTime + timePerCoin;
    return CoinsEconomyState(
      availableTime: next > maxAvailableTime ? maxAvailableTime : next,
      regenerationAnchor: regenerationAnchor,
      adRewardGrants: adRewardGrants,
    );
  }

  /// La única vía por la que una recompensa de publicidad puede sumar una
  /// Coin — nunca al tocar el botón, solo cuando quien llama (
  /// `RewardedAdService`, tras `onUserEarnedReward` real) ya confirmó la
  /// recompensa. Rechaza sin mutar nada si el usuario ya está lleno o ya
  /// gastó su cupo de la ventana de 12 horas. Asume que `this` ya está al
  /// día (ver [consuming]).
  CoinsGrantOutcome grantingAdReward(DateTime now) {
    if (adRewardGrantsWithin(now).length >= maxRewardedAdsPerWindow) {
      return CoinsGrantOutcome(this, AdRewardGrantResult.rejectedRateLimited);
    }
    if (coins >= maxCoins) {
      return CoinsGrantOutcome(this, AdRewardGrantResult.rejectedAtMaxCoins);
    }
    final withCoin = addingCoin();
    final granted = CoinsEconomyState(
      availableTime: withCoin.availableTime,
      regenerationAnchor: withCoin.regenerationAnchor,
      adRewardGrants: [...withCoin.adRewardGrants, now],
    );
    return CoinsGrantOutcome(granted, AdRewardGrantResult.granted);
  }

  Map<String, dynamic> toJson() => {
        'availableSeconds': availableTime.inSeconds,
        'regenerationAnchor': regenerationAnchor.toIso8601String(),
        'adRewardGrants': adRewardGrants.map((t) => t.toIso8601String()).toList(),
      };

  factory CoinsEconomyState.fromJson(Map<String, dynamic> json) => CoinsEconomyState(
        availableTime: Duration(seconds: json['availableSeconds'] as int),
        regenerationAnchor: DateTime.parse(json['regenerationAnchor'] as String),
        adRewardGrants: (json['adRewardGrants'] as List? ?? const [])
            .map((t) => DateTime.parse(t as String))
            .toList(),
      );
}

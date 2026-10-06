import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../persistence/coins_economy_store.dart';
import 'coins_economy_state.dart';

/// Fachada de la economía de FLOPly Coins — la única clase que el resto de
/// la app debería tocar para leer o mutar Coins/tiempo disponible; toda la
/// aritmética real vive en [CoinsEconomyState] (inmutable, sin IO), esta
/// clase solo orquesta: mantiene el estado vigente en memoria, lo
/// sincroniza contra el reloj real antes de cada lectura/escritura, lo
/// persiste (best-effort, nunca bloquea la app si el disco falla) y avisa
/// a quien esté escuchando ([ChangeNotifier], mismo patrón que
/// `ConnectivityService`/`AcademyController`).
///
/// **Fase 2**: ya conectada — Tools/Coach/entrenamiento extra consumen
/// tiempo real a través de `EconomySession`, y el gate de acceso a todas
/// vive en `EconomyAccessService` (`economy_access_service.dart`). Esta
/// clase sigue siendo la única fuente de verdad de Coins: ninguna
/// pantalla la muta directamente, todas pasan por acá.
class FloplyCoinsService extends ChangeNotifier {
  FloplyCoinsService({CoinsEconomyStore? store, DateTime Function()? clock})
      : _store = store ?? FileCoinsEconomyStore(),
        _clock = clock ?? DateTime.now {
    _state = CoinsEconomyState.initial(_clock());
  }

  final CoinsEconomyStore _store;
  final DateTime Function() _clock;
  late CoinsEconomyState _state;

  /// `true` hasta que [load] termina — igual que `AcademyController.
  /// loading`, para que quien construya esta clase sepa cuándo el estado
  /// ya refleja lo persistido (y no solo el default en memoria).
  bool loading = true;

  /// Hidrata el estado persistido (si hay) y lo sincroniza contra el reloj
  /// real — debe llamarse una vez, apenas se crea la instancia (mismo
  /// contrato que `AcademyController.load()`). Nunca lanza: si el disco
  /// falla, sigue con el estado en memoria (una cuenta nueva llena).
  Future<void> load() async {
    try {
      final saved = await _store.load();
      if (saved != null) _state = saved;
    } catch (_) {
      // best-effort: sin persistencia disponible, se arranca de cero.
    }
    _state = _state.advanced(_clock());
    loading = false;
    notifyListeners();
    unawaited(_persist());
  }

  int get coins => _live.coins;

  int get availableMinutes => _live.availableMinutes;

  Duration get availableTime => _live.availableTime;

  /// `null` si ya está en el máximo — no hay "próxima Coin" mientras no se
  /// gaste nada.
  DateTime? get nextRegenerationAt => _live.nextRegenerationAt;

  /// Recompensas de publicidad concedidas en las últimas 12 horas — para
  /// mostrarle al usuario "te quedan N de 3", nunca para decidir nada por
  /// su cuenta (esa decisión la toma [grantAdReward]).
  int get rewardedAdsUsedInWindow => _live.adRewardGrantsWithin(_clock()).length;

  /// `true` si en este momento se podría conceder otra recompensa de
  /// publicidad (no está lleno y no se agotó el cupo de la ventana de 12
  /// horas) — para que `RewardedAdService` decida si vale la pena siquiera
  /// mostrar el anuncio. La decisión FINAL y autoritativa sigue siendo
  /// [grantAdReward] (nunca se confía en este valor solo para otorgar).
  bool get canRequestAdReward => _live.canRequestAdReward(_clock());

  /// El estado proyectado al momento actual — nunca muta [_state]: solo
  /// [load] y los métodos de mutación de abajo avanzan la fuente de verdad
  /// de verdad (y la persisten). Una simple lectura no le hace IO a la app.
  CoinsEconomyState get _live => _state.advanced(_clock());

  /// Consume hasta [amount] de tiempo disponible — nunca deja el pool
  /// negativo; si se pide más de lo que queda, consume solo lo que hay.
  /// Devuelve cuánto se consumió de verdad. Esta es la única vía de
  /// consumo: **nunca** "abrir una herramienta = -1 Coin" (ver el
  /// doc-comment de [CoinsEconomyState]).
  Future<Duration> consumeTime(Duration amount) async {
    final before = _live;
    _state = before.consuming(amount);
    notifyListeners();
    await _persist();
    return before.availableTime - _state.availableTime;
  }

  /// Suma 1 Coin manualmente (sin pasar por publicidad) — pensado para
  /// Premium/promos futuras o para la pantalla de diagnóstico de esta
  /// fase, nunca para el flujo de Rewarded Ads (eso es [grantAdReward],
  /// que además aplica el límite de 3/12h).
  Future<void> addCoin() async {
    _state = _live.addingCoin();
    notifyListeners();
    await _persist();
  }

  /// La única vía por la que una recompensa publicitaria suma una Coin —
  /// debe llamarse exclusivamente desde la confirmación real de AdMob
  /// (`onUserEarnedReward`, ver `RewardedAdService`), nunca al tocar el
  /// botón de "ver anuncio". Aplica el tope de 6 Coins y el límite de 3
  /// recompensas cada 12 horas de forma autoritativa.
  Future<AdRewardGrantResult> grantAdReward() async {
    final outcome = _live.grantingAdReward(_clock());
    _state = outcome.state;
    notifyListeners();
    await _persist();
    return outcome.result;
  }

  Future<void> _persist() async {
    try {
      await _store.save(_state);
    } catch (_) {
      // best-effort: igual que `AcademyController._persist()`.
    }
  }
}

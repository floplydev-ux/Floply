import 'dart:async';

import 'floply_coins_service.dart';

/// Una sesión de consumo de tiempo real contra [FloplyCoinsService] — el
/// único mecanismo reutilizable de medición de tiempo de toda la economía
/// (Tools, Coach, entrenamiento extra comparten esta misma clase, nunca
/// una copia cada uno).
///
/// **Nunca depende únicamente de un `Timer`**: cada cobro mide el tiempo
/// real transcurrido desde el cobro anterior (`DateTime.now().difference`,
/// vía [clock] inyectable para tests), así que un `Timer` perdido,
/// atrasado, o que nunca llega a disparar (p. ej. la app se mata de golpe)
/// nunca genera un cobro de más — en el peor caso cobra de menos (el
/// tramo final sin cerrar), nunca de más.
///
/// **Seguro contra doble cobro**: cada [_charge] resetea el punto de
/// partida al momento exacto en que cobra, así que llamar [pause]/[end]/
/// [dispose] en cualquier combinación o repetidas veces nunca cuenta el
/// mismo tramo dos veces (cada uno vuelve a chequear `_active` primero).
class EconomySession {
  EconomySession({
    required this.coins,
    this.checkpointInterval = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FloplyCoinsService coins;

  /// Cada cuánto se cobra el tramo transcurrido mientras la sesión sigue
  /// activa — pedido explícito: "checkpoint aproximadamente cada 60
  /// segundos".
  final Duration checkpointInterval;

  final DateTime Function() _clock;

  Timer? _timer;
  DateTime? _since;
  bool _active = false;
  bool _ranOut = false;

  /// `true` entre [start] y [end] (inclusive de las pausas intermedias:
  /// una sesión pausada sigue "activa", solo no cobra mientras tanto).
  bool get isActive => _active;

  /// `true` si el último cobro dejó el pool de tiempo en cero — la UI
  /// que envuelve la sesión usa esto para mostrar el aviso de "sin
  /// Coins" sin cortar la sesión por su cuenta.
  bool get ranOutOfCoins => _ranOut;

  /// Arranca la sesión — no-op si ya estaba activa (una pantalla tiene
  /// como máximo una sesión económica activa, pedido explícito; nunca
  /// dos superpuestas sobre el mismo [EconomySession]).
  void start() {
    if (_active) return;
    _active = true;
    _ranOut = false;
    _since = _clock();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(checkpointInterval, () {
      unawaited(_charge());
      if (_active) _arm();
    });
  }

  Future<void> _charge() async {
    final start = _since;
    if (start == null) return;
    final now = _clock();
    _since = now;
    final elapsed = now.difference(start);
    if (elapsed <= Duration.zero) return;
    try {
      final before = coins.availableTime;
      final consumed = await coins.consumeTime(elapsed);
      if (before <= Duration.zero || consumed < elapsed) _ranOut = true;
    } catch (_) {
      // `coins` puede haberse disposed antes que esta sesión si quien lo
      // posee (p. ej. un host de pantalla en un test, o en una
      // secuencia de desmontaje atípica) se destruye primero — best
      // effort, mismo criterio que ya usa toda la persistencia de la
      // economía: nunca tirar la app por un cobro que ya no tiene a
      // quién acreditarse.
    }
  }

  /// Background: cobra el tramo real hasta ahora y detiene el
  /// temporizador — nunca sigue cobrando mientras la app está en
  /// background (pedido explícito). La sesión sigue "activa" (ver
  /// [resume]), solo pausada.
  Future<void> pause() async {
    if (!_active) return;
    _timer?.cancel();
    _timer = null;
    await _charge();
  }

  /// Foreground: el próximo cobro cuenta desde este instante, nunca
  /// desde antes de la pausa — evita doble conteo del tiempo en
  /// background.
  void resume() {
    if (!_active) return;
    _since = _clock();
    _arm();
  }

  /// Termina la sesión: cobra el tramo final pendiente y detiene todo.
  /// Idempotente — una segunda llamada (p. ej. `dispose` después de un
  /// "salir" explícito) no hace nada.
  Future<void> end() async {
    if (!_active) return;
    _active = false;
    _timer?.cancel();
    _timer = null;
    await _charge();
    _since = null;
  }

  /// Para el `dispose()` sincrónico de un `State` — cobra el tramo final
  /// sin que el caller tenga que `await` (best-effort, mismo criterio
  /// que la persistencia de [FloplyCoinsService]: el estado en memoria ya
  /// queda correcto de forma síncrona dentro de `consumeTime`, antes de
  /// que termine el `Future`; solo el guardado a disco queda en vuelo).
  void dispose() {
    if (!_active) return;
    _active = false;
    _timer?.cancel();
    _timer = null;
    unawaited(_charge());
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Estado mínimo de conectividad pedido: online u offline, nada más.
enum ConnectionStatus { online, offline }

/// Detección **centralizada** de conectividad (modo offline, sección 1):
/// una sola instancia, creada una vez en la raíz de la app (`app.dart`) y
/// compartida por `AuthController` (para reintentar la sincronización) y
/// por el banner discreto (`offline_banner.dart`) — ninguna pantalla
/// vuelve a preguntar por su cuenta si hay red.
///
/// Deliberadamente basado en `connectivity_plus` (interfaz de red del SO,
/// wifi/datos apagados o prendidos) y no en "ping a un servidor": es
/// exactamente la señal que describe el pedido ("cortar wifi y datos
/// móviles"), más simple y más rápida que una verificación de alcance
/// real — Firestore/Firebase Auth ya manejan por su cuenta el caso más
/// fino de "hay wifi pero sin salida a Internet" (sus propios timeouts),
/// así que no hace falta duplicar esa lógica acá.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
    _readyCompleter = Completer<void>();
    _bootstrap();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;
  bool get isOffline => _status == ConnectionStatus.offline;
  bool get isOnline => _status == ConnectionStatus.online;

  /// Se resuelve cuando [status] ya refleja la conectividad real del
  /// dispositivo al arrancar — antes de esto, [status] vale `online` por
  /// default (ver el doc-comment de [_status]) y todavía podría no ser
  /// verdad. La pantalla de entrada offline (sección 1) espera esto
  /// antes de decidir si mostrarse, para no alcanzar a mostrar la app
  /// normal ni un instante si en realidad no hay conexión.
  late final Completer<void> _readyCompleter;
  Future<void> get ready => _readyCompleter.future;

  Future<void> _bootstrap() async {
    try {
      // `timeout` (no solo el `catch` de abajo): sin esto, un plugin que
      // se cuelga (el future de `checkConnectivity()` nunca se resuelve
      // ni lanza) dejaría [ready] sin completarse nunca — pantalla de
      // carga infinita en `StartupConnectivityGate` (Grupo 8, sección 1),
      // justo lo que esa pantalla existe para evitar.
      _apply(await _connectivity.checkConnectivity().timeout(
            const Duration(seconds: 3),
            onTimeout: () => const [ConnectivityResult.wifi],
          ));
    } catch (_) {
      // Si el plugin falla en este dispositivo, mejor asumir online (el
      // comportamiento de hoy) que bloquear la app con un falso offline.
    } finally {
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    final next = offline ? ConnectionStatus.offline : ConnectionStatus.online;
    if (next == _status) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

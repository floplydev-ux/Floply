import 'package:flutter/material.dart';

import '../../services/connectivity_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sala_verde/floply_loading_indicator.dart';
import '../offline/offline_entry_screen.dart';
import '../offline/offline_tools_shell.dart';

/// Decide, antes de que se construya `AuthGate`, si la app arranca
/// normal o si el dispositivo está sin conexión (Grupo 8, secciones 1/2/9).
///
/// Tres modos posibles, nunca más:
///  - [_Mode.normal] — hay conexión (o el chequeo inicial todavía no
///    terminó y se prefiere no bloquear con un falso offline): [child]
///    tal cual, ningún cambio sobre el flujo de siempre.
///  - [_Mode.offlineEntry] — no hay conexión al arrancar: pantalla de
///    aviso ([OfflineEntryScreen]), un solo camino hacia adelante
///    ("ENTRAR EN MODO OFFLINE").
///  - [_Mode.offlineTools] — el usuario ya confirmó: [OfflineToolsShell]
///    (únicamente Herramientas — Academia, Laboratorio y todo lo que
///    dependa de red quedan fuera, sección 8).
///
/// **Solo al arranque**: si la conexión se pierde DESPUÉS de haber
/// entrado normal (Academia, Laboratorio, etc.), este gate no interviene
/// — `OfflineBannerOverlay` ya avisa con el banner discreto, y tanto
/// Academia como el resto de la app ya toleran quedarse sin red (ver
/// `SyncingAcademyStore`/`AuthController._pendingReconcile`): forzar la
/// salida de una lección a medio terminar por una caída de wifi sería
/// peor que dejarla seguir en local, justo lo que la sección 9 pide
/// evitar ("no perder progreso ni estado local").
///
/// **Recuperación automática** (sección 9): mientras el modo activo sea
/// [_Mode.offlineEntry] u [_Mode.offlineTools], este widget sigue
/// escuchando [connectivity] y vuelve solo a [_Mode.normal] apenas la
/// conectividad real cambia a online — nunca hace falta cerrar y volver
/// a abrir la app.
class StartupConnectivityGate extends StatefulWidget {
  const StartupConnectivityGate({
    super.key,
    required this.connectivity,
    required this.child,
  });

  final ConnectivityService connectivity;

  /// El árbol normal de la app (`AuthGate`) — se arma una sola vez y se
  /// reutiliza tal cual en `_Mode.normal`, nunca se reconstruye a mano.
  final Widget child;

  @override
  State<StartupConnectivityGate> createState() => _StartupConnectivityGateState();
}

enum _Mode { checking, offlineEntry, offlineTools, normal }

class _StartupConnectivityGateState extends State<StartupConnectivityGate> {
  _Mode _mode = _Mode.checking;

  @override
  void initState() {
    super.initState();
    widget.connectivity.addListener(_onConnectivityChanged);
    widget.connectivity.ready.then((_) {
      if (!mounted) return;
      setState(() {
        _mode = widget.connectivity.isOffline ? _Mode.offlineEntry : _Mode.normal;
      });
    });
  }

  @override
  void dispose() {
    widget.connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    // Solo reacciona mientras el modo activo sea uno de los dos
    // offline — ver el doc-comment de la clase sobre por qué `normal`
    // nunca se interrumpe por una caída de conexión posterior.
    if (_mode != _Mode.offlineEntry && _mode != _Mode.offlineTools) return;
    if (widget.connectivity.isOnline) {
      setState(() => _mode = _Mode.normal);
    }
  }

  void _enterOfflineMode() => setState(() => _mode = _Mode.offlineTools);

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _Mode.checking => const _CheckingSplash(),
      _Mode.offlineEntry =>
        OfflineEntryScreen(onEnterOffline: _enterOfflineMode),
      _Mode.offlineTools => const OfflineToolsShell(),
      _Mode.normal => widget.child,
    };
  }
}

/// Mismo look que el splash de `AuthGate` (`_SplashView`) — el chequeo
/// de conectividad inicial (`ConnectivityService.ready`) tarda apenas un
/// instante, así que no amerita una pantalla propia distinta.
class _CheckingSplash extends StatelessWidget {
  const _CheckingSplash();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(child: FloplyLoadingIndicator(size: 72)),
    );
  }
}

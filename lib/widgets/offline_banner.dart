import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../theme/sala_verde/sala_verde_tokens.dart';

/// Indicador discreto de conectividad (sección 7 del modo offline) —
/// envuelve TODA la app una sola vez (`app.dart`), nunca una pantalla en
/// particular: se ve arriba de `AuthGate`, así que aparece tanto en el
/// login/splash como dentro de `AppShell`, sin que cada pantalla tenga
/// que acordarse de mostrarlo.
///
/// Dos mensajes, nunca un popup que bloquee nada:
///  - offline → banner fijo, discreto, mientras dure ("Modo sin conexión").
///  - vuelve la red → "Conexión restaurada", se retira solo a los pocos
///    segundos.
class OfflineBannerOverlay extends StatefulWidget {
  const OfflineBannerOverlay({
    super.key,
    required this.connectivity,
    required this.child,
  });

  final ConnectivityService connectivity;
  final Widget child;

  @override
  State<OfflineBannerOverlay> createState() => _OfflineBannerOverlayState();
}

enum _BannerMode { hidden, offline, restored }

class _OfflineBannerOverlayState extends State<OfflineBannerOverlay> {
  late _BannerMode _mode =
      widget.connectivity.isOffline ? _BannerMode.offline : _BannerMode.hidden;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    widget.connectivity.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    widget.connectivity.removeListener(_onConnectivityChanged);
    _restoredTimer?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged() {
    _restoredTimer?.cancel();
    if (widget.connectivity.isOffline) {
      setState(() => _mode = _BannerMode.offline);
      return;
    }
    // Volvió la red: si veníamos de mostrar el banner offline, avisamos
    // "conexión restaurada" y lo retiramos solo. Si nunca estuvo offline
    // (arranque en frío ya online), no hay nada que anunciar.
    if (_mode == _BannerMode.offline) {
      setState(() => _mode = _BannerMode.restored);
      _restoredTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _mode = _BannerMode.hidden);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: SalaVerdeMotion.normal,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
              child: switch (_mode) {
                _BannerMode.hidden => const SizedBox.shrink(),
                _BannerMode.offline => const _Banner(
                    key: ValueKey('offline'),
                    icon: Icons.cloud_off_rounded,
                    label: 'Modo sin conexión',
                    color: SalaVerdeColors.warning,
                  ),
                _BannerMode.restored => const _Banner(
                    key: ValueKey('restored'),
                    icon: Icons.cloud_done_rounded,
                    label: 'Conexión restaurada',
                    color: SalaVerdeColors.success,
                  ),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        SalaVerdeSpace.lg,
        SalaVerdeSpace.sm,
        SalaVerdeSpace.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SalaVerdeSpace.md,
        vertical: SalaVerdeSpace.sm,
      ),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: SalaVerdeElevation.level1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: SalaVerdeSpace.sm),
          Flexible(
            child: Text(
              label,
              style: SalaVerdeType.caption(color: SalaVerdeColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

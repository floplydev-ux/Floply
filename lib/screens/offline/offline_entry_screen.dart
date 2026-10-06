import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';

/// Pantalla de aviso al arrancar la app sin conexión (Grupo 8, sección
/// 1) — se muestra ANTES de `AuthGate`/`AppShell`, nunca después: sin
/// Internet, ni Firebase Auth ni la sincronización de progreso tienen
/// con qué trabajar, así que no tiene sentido dejar que la app intente
/// arrancar normal para recién ahí fallar.
///
/// Un solo camino hacia adelante: [onEnterOffline] — no hay "reintentar"
/// acá porque `StartupConnectivityGate` ya vuelve solo al modo normal en
/// cuanto la conectividad real cambia (sección 9), sin que el usuario
/// tenga que pedirlo.
class OfflineEntryScreen extends StatelessWidget {
  const OfflineEntryScreen({super.key, required this.onEnterOffline});

  final VoidCallback onEnterOffline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SalaVerdeSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: SalaVerdeColors.textMuted,
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                Text(
                  AppStrings.offlineEntryTitle,
                  textAlign: TextAlign.center,
                  style: SalaVerdeType.title(),
                ),
                const SizedBox(height: SalaVerdeSpace.sm),
                Text(
                  AppStrings.offlineEntryBody,
                  textAlign: TextAlign.center,
                  style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
                ),
                const SizedBox(height: SalaVerdeSpace.xl),
                SvButtonPrimary(
                  label: AppStrings.offlineEntryCta,
                  onTap: onEnterOffline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

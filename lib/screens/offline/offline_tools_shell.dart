import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../tools/tools_screen.dart';

/// El único destino disponible en modo offline (Grupo 8, sección 1/8):
/// [ToolsScreen] tal cual (sin tocarla — ya funciona 100% con lógica
/// local, ninguna de sus calculadoras llama a Firebase/servidor), con
/// una franja fija arriba que deja explícito que Academia y Laboratorio
/// no están disponibles ahora. El indicador general de "sin conexión"
/// (sección 1) ya lo pone `OfflineBannerOverlay`, que envuelve a este
/// widget desde más arriba — acá solo hace falta aclarar el alcance
/// (qué SÍ está disponible), no repetir que no hay red.
class OfflineToolsShell extends StatelessWidget {
  const OfflineToolsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: SalaVerdeColors.surfaceElevated,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SalaVerdeSpace.lg,
                vertical: SalaVerdeSpace.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 16, color: SalaVerdeColors.warning),
                  const SizedBox(width: SalaVerdeSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.offlineToolsBannerTitle,
                          style: SalaVerdeType.bodyStrong(),
                        ),
                        Text(
                          AppStrings.offlineToolsBannerBody,
                          style: SalaVerdeType.caption(
                              color: SalaVerdeColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(child: ToolsScreen()),
      ],
    );
  }
}

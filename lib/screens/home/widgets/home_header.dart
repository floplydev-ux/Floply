import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/user_avatar.dart';

/// Encabezado de la Home: identidad del usuario y nada más. Sin XP, sin
/// monedas, sin diamantes — ninguna de esas métricas existe de verdad hoy
/// (ver `models/user_progress.dart`, retirado en este rediseño).
///
/// Fase 2: solo cambia tipografía/color a Sala Verde — `UserAvatar` (widget
/// compartido, no migrado) y la estructura de accesibilidad del botón de
/// ajustes (círculo visual 38×38 dentro de un área tocable 48×48) quedan
/// exactamente igual.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    this.photoUrl,
    required this.onOpenProfile,
  });

  final String name;
  final String? photoUrl;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(displayName: name, photoUrl: photoUrl, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.homeGreeting(name),
                style: SalaVerdeType.title(),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.homeGreetingSubtitle,
                style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: AppStrings.homeProfileButtonLabel,
          child: PressableScale(
            onTap: onOpenProfile,
            // Fase 1, Bloque 1, P1-D: el círculo VISUAL sigue midiendo
            // 38×38 (sin cambios de apariencia) pero el área TOCABLE ahora
            // es el SizedBox de 48×48 que lo envuelve — cumple
            // androidTapTargetGuideline (48×48) e iOSTapTargetGuideline
            // (44×44) a la vez, sin agrandar el ícono. Sin cambios en
            // Fase 2, solo el color del ícono/borde.
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SalaVerdeColors.surfaceElevated,
                    border: Border.all(color: SalaVerdeColors.borderSubtle),
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: SalaVerdeColors.textSecondary, size: 18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

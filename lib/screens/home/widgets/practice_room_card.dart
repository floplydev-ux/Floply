import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import 'sv_home_link_card.dart';

/// Segunda vía de aprendizaje: "ya aprendiste teoría, ahora practicá".
/// Lleva al Laboratorio (hoy la única pantalla de práctica libre — no hay
/// una feature "Practice Room" separada en el proyecto). No muestra
/// estadísticas de sesiones anteriores: no hay ninguna todavía persistida
/// de verdad, así que no se inventa un número.
///
/// Fase 2: acento `steelBlueBright` (temperatura de Laboratorio, variante
/// segura para ícono/texto — ver `FLOPLY_DESIGN_LANGUAGE.md` "Principio de
/// contraste por contexto de uso") en vez de `neonGreen`.
class PracticeRoomCard extends StatelessWidget {
  const PracticeRoomCard({super.key, required this.onPracticeNow});

  final VoidCallback onPracticeNow;

  @override
  Widget build(BuildContext context) {
    return SvHomeLinkCard(
      icon: Icons.bolt_rounded,
      title: AppStrings.practiceRoomTitle,
      description: AppStrings.practiceRoomBody,
      accentColor: SalaVerdeColors.steelBlueBright,
      onTap: onPracticeNow,
    );
  }
}

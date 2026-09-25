import 'package:flutter/material.dart';

import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Banner compacto de acceso a un módulo secundario de la Home (Bankroll,
/// Tools, Coach) o a Laboratorio (Practice Room) — ícono + título +
/// descripción + chevron, un solo color de acento por card.
///
/// **Fase 2 — no es una migración de `lib/widgets/home_link_card.dart`**:
/// ese widget también lo usa `ToolsScreen` (fuera de alcance de esta
/// migración de Home), así que se deja intacto y este es un componente
/// nuevo, scoped a `screens/home/`, con la misma anatomía funcional
/// (mismos parámetros, mismo comportamiento) pero el tratamiento visual ya
/// validado en el playground (`home_prototype_preview.dart` Fase 1.5):
/// superficie plana `surfaceElevated` (no un fondo teñido por el color de
/// acento) + un ícono chico tinte — el acento identifica la sección sin
/// convertir toda la card en ese color.
///
/// Nota de presupuesto de `brass` (`FLOPLY_ANTI_GENERIC.md` 0.2): la card
/// de Bankroll usa `brass` acá SOLO en ícono, nunca como relleno — el
/// hero de arriba ya gastó el único relleno brass permitido en esta
/// pantalla (el botón CONTINUAR/PRACTICAR).
class SvHomeLinkCard extends StatelessWidget {
  const SvHomeLinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  /// Visualmente subordinado: opacidad reducida del conjunto. Pensado para
  /// secciones "preparadas para el futuro" (Coach) que no deben competir
  /// con Academia.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? SalaVerdeColors.textMuted : accentColor;

    return SvTappableCard(
      onTap: onTap,
      opacity: muted ? 0.6 : 1.0,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: SalaVerdeSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SalaVerdeType.bodyStrong()),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: SalaVerdeSpace.sm),
          Icon(Icons.chevron_right_rounded, color: color, size: 22),
        ],
      ),
    );
  }
}

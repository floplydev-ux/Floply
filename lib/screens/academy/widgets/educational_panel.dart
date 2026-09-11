import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Clave de test: la tarjeta del panel educativo.
const Key kAcademyEducationalPanelKey = Key('academy.educationalPanel');

/// Tipografía del texto educativo del panel. Legible sin zoom; nunca se
/// encoge para "hacer entrar" contenido.
const TextStyle kEducationalPanelTextStyle = TextStyle(
  fontSize: 14,
  height: 1.5,
  fontWeight: FontWeight.w500,
  color: AppColors.textPrimary,
);

/// El panel educativo: la zona de explicación estable, debajo de la mesa.
/// Es el "profesor" — la mesa es el escenario.
///
/// Muestra el texto **completo** (nunca `maxLines` ni `ellipsis` para
/// contenido pedagógico); si excepcionalmente no cabe en su alto, hace
/// scroll interno como último recurso. Mantiene el vínculo con la mesa con
/// una etiqueta de contexto ([contextLabel], p. ej. "EL FLOP" / "VOS") y el
/// resaltado que sigue activo arriba.
///
/// Funciona tanto con alto acotado (dentro de un `Expanded`: el cuerpo
/// scrollea si hace falta) como sin acotar (dentro de un scroll: crece con
/// el contenido) — así lo reutiliza también `feedback_view`.
class EducationalPanel extends StatelessWidget {
  const EducationalPanel({
    super.key,
    required this.text,
    this.stepNumber,
    this.contextLabel,
    this.icon,
    this.accent = AppColors.violetPrimary,
  });

  final String text;

  /// Número del paso / ítem para el indicador circular. `null` lo oculta.
  final int? stepNumber;

  /// Etiqueta corta del elemento explicado (mantiene el vínculo con la
  /// mesa).
  final String? contextLabel;

  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // El panel se ajusta a su contenido. Si el texto excepcionalmente
      // no entra en el alto disponible, el cuerpo (y sólo el cuerpo)
      // scrollea; el encabezado queda fijo. `Flexible` en un Column
      // `min` + alto acotado = "hasta tu contenido, con tope".
      final bounded = constraints.hasBoundedHeight;
      final body = SingleChildScrollView(
        primary: false,
        physics: bounded
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: Text(text, style: kEducationalPanelTextStyle),
      );

      final inner = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            icon: icon,
            contextLabel: contextLabel,
            stepNumber: stepNumber,
            accent: accent,
          ),
          const SizedBox(height: 10),
          if (bounded) Flexible(child: body) else body,
        ],
      );

      return Container(
        key: kAcademyEducationalPanelKey,
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                accent.withValues(alpha: 0.12),
                AppColors.surface,
              ),
              AppColors.surface,
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: inner,
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.contextLabel,
    required this.stepNumber,
    required this.accent,
  });

  final IconData? icon;
  final String? contextLabel;
  final int? stepNumber;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: [
          Icon(icon ?? Icons.school_rounded, size: 14, color: accent),
          const SizedBox(width: 6),
          if (contextLabel != null && contextLabel!.isNotEmpty)
            Flexible(
              child: Text(
                contextLabel!.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: accent,
                ),
              ),
            ),
          const Spacer(),
          if (stepNumber != null)
            Text(
              'PASO $stepNumber',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: accent.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

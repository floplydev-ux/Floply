import 'package:flutter/material.dart';

import '../../../theme/sala_verde/sala_verde_tokens.dart';
import 'home_banner_action_button.dart';

/// El "bloque grande" compartido por Herramientas y Coach en el Home —
/// mismo tamaño/contenedor, misma jerarquía visual, misma lógica de
/// elevación/profundidad. El tap target es el banner completo; el círculo
/// con chevron en la esquina inferior derecha es la indicación visual de
/// acceso.
class HomeFeatureBanner extends StatelessWidget {
  const HomeFeatureBanner({
    super.key,
    required this.accent,
    required this.title,
    required this.description,
    required this.onTap,
    this.backgroundImage,
    this.backgroundImageAlignment = Alignment.center,
    this.footer,
  });

  final Color accent;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? backgroundImage;
  final Alignment backgroundImageAlignment;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final image = backgroundImage;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 156),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SalaVerdeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 36,
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (image != null) ...[
              Positioned.fill(
                child: Image.asset(image, fit: BoxFit.cover, alignment: backgroundImageAlignment),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.38),
                        Colors.black.withValues(alpha: 0.68),
                        Colors.black.withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(SalaVerdeSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SalaVerdeType.bodyStrong().copyWith(fontSize: 15, letterSpacing: .4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: SalaVerdeSpace.md),
                    footer!,
                  ],
                ],
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: HomeBannerActionButton(onPressed: onTap),
            ),
          ],
        ),
      );
  }
}

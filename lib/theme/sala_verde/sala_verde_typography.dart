/// Sistema tipográfico centralizado de "Sala Verde".
///
/// Tres familias:
///  - **Fraunces** — display / headlines / identidad premium (variable, ejes wght + opsz)
///  - **PublicSans** — UI principal: body, botones, nav, labels (variable, eje wght)
///  - **IBMPlexMono** — datos numéricos/técnicos de póker, via [SvMonoStyles]
///
/// El [TextTheme] de este archivo se consume en `AppTheme.dark` (y en cualquier
/// ThemeData futuro) como `textTheme: SalaVerdeTypography.textTheme`.
///
/// Para datos numéricos usá las constantes de [SvMonoStyles] directamente —
/// esos estilos NO forman parte del TextTheme porque se aplican selectivamente
/// solo donde aparecen BB, stacks, porcentajes, EV, equity, contadores, etc.
library;

import 'package:flutter/material.dart';

import 'sala_verde_tokens.dart';

// ---------------------------------------------------------------------------
// Helpers privados
// ---------------------------------------------------------------------------

TextStyle _fraunces({
  required double size,
  required FontWeight weight,
  double height = 1.2,
  Color? color,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Fraunces',
    fontVariations: [
      FontVariation('wght', weight.value.toDouble()),
      const FontVariation('opsz', 72),
    ],
    fontWeight: weight,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? SalaVerdeColors.textPrimary,
  );
}

TextStyle _publicSans({
  required double size,
  required FontWeight weight,
  double height = 1.4,
  Color? color,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'PublicSans',
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    fontWeight: weight,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? SalaVerdeColors.textPrimary,
  );
}

// ---------------------------------------------------------------------------
// TextTheme
// ---------------------------------------------------------------------------

/// TextTheme completo de "Sala Verde".
///
/// Asignación de familias siguiendo el rol semántico de Material 3:
///  - display* / headline* → **Fraunces** (identidad premium, jerarquía visual)
///  - title* / body* / label* → **PublicSans** (legibilidad de UI)
abstract final class SalaVerdeTypography {
  static TextTheme get textTheme => TextTheme(
        // ── Fraunces: display ──────────────────────────────────────────────
        displayLarge: _fraunces(size: 57, weight: FontWeight.w300),
        displayMedium: _fraunces(size: 45, weight: FontWeight.w300),
        displaySmall: _fraunces(size: 36, weight: FontWeight.w400),

        // ── Fraunces: headlines ────────────────────────────────────────────
        headlineLarge: _fraunces(size: 32, weight: FontWeight.w400),
        headlineMedium: _fraunces(size: 28, weight: FontWeight.w400),
        headlineSmall: _fraunces(size: 24, weight: FontWeight.w400),

        // ── PublicSans: títulos de sección ─────────────────────────────────
        titleLarge: _publicSans(size: 22, weight: FontWeight.w500),
        titleMedium: _publicSans(size: 16, weight: FontWeight.w500),
        titleSmall: _publicSans(size: 14, weight: FontWeight.w500),

        // ── PublicSans: body ───────────────────────────────────────────────
        bodyLarge: _publicSans(size: 16, weight: FontWeight.w400),
        bodyMedium: _publicSans(size: 14, weight: FontWeight.w400),
        bodySmall: _publicSans(size: 12, weight: FontWeight.w400),

        // ── PublicSans: labels ─────────────────────────────────────────────
        labelLarge: _publicSans(size: 14, weight: FontWeight.w500),
        labelMedium: _publicSans(size: 12, weight: FontWeight.w500),
        labelSmall: _publicSans(size: 11, weight: FontWeight.w500),
      );
}

// ---------------------------------------------------------------------------
// SvMonoStyles — datos numéricos/técnicos de póker
// ---------------------------------------------------------------------------

/// Estilos IBM Plex Mono para datos numéricos y técnicos de póker.
///
/// No forman parte del TextTheme; se aplican manualmente solo donde
/// corresponde: BB, stack, pot, blinds, porcentajes (equity/pot odds/EV),
/// contadores de monedas FLOPly, estadísticas numéricas, timers, combos,
/// valores de herramientas y notación de cartas/rangos.
///
/// Uso:
/// ```dart
/// Text('72%', style: SvMonoStyles.numeric)
/// Text('3.2 BB', style: SvMonoStyles.stat)
/// Text('Ah', style: SvMonoStyles.pokerValue)
/// ```
abstract final class SvMonoStyles {
  /// Datos numéricos estándar: porcentajes, frecuencias, contadores.
  /// IBM Plex Mono Regular 14px.
  static const TextStyle numeric = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Estadísticas destacadas: stacks grandes, EV, valores de sesión.
  /// IBM Plex Mono Medium 16px.
  static const TextStyle stat = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Notación de cartas y rangos: Ah, KQs, 44, AKo.
  /// IBM Plex Mono Medium 13px.
  static const TextStyle pokerValue = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Valores técnicos secundarios: pot odds, combos, métricas de herramienta.
  /// IBM Plex Mono Regular 12px.
  static const TextStyle technicalValue = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

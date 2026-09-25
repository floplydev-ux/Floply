/// PROTOTIPO — Fase 1 del lenguaje visual "Sala Verde".
///
/// Ver `docs/design/FLOPLY_PROTOTYPE_PHASE_1.md` y, antes que nada,
/// `docs/design/FLOPLY_DESIGN_TOKENS.md` (esto es la traducción 1:1 de esa
/// estructura conceptual a Dart, solo que **localizada**: nada de acá se
/// importa desde código de producción, y `AppColors`/`AppTheme` no se
/// tocan. Es una capa aislada y reversible que solo usan los widgets bajo
/// `lib/dev/design_playground/` para poder juzgar el lenguaje visual en
/// pantallas reales sin migrar nada todavía.
///
/// Nota deliberada sobre tipografía: la Fase 0.5/Tokens dejó explícito que
/// elegir familias display/UI/numérica reales (con licencia) es tarea de
/// la fase de implementación, no de este prototipo. Acá se usa la fuente
/// de sistema para las tres, diferenciada por peso/tamaño/letter-spacing
/// (igual que ya hace el sistema actual) — la única excepción real es que
/// todo lo "numérico" fija `FontFeature.tabularFigures()`, que es la parte
/// de la firma tipográfica que sí se puede validar hoy sin una fuente
/// nueva.
library;

import 'package:flutter/material.dart';

/// `color.*` — ver `FLOPLY_DESIGN_LANGUAGE.md` §5.1.
abstract final class ProtoColor {
  // Superficies
  static const background = Color(0xFF0E0D0B);
  static const surface = Color(0xFF17140F);
  static const surfaceElevated = Color(0xFF211C15);
  static const surfaceReading = Color(0xFFF3ECDD);

  /// Franja acotada — NUNCA fondo de pantalla completa (regla dura, ver
  /// `FLOPLY_ANTI_GENERIC.md` "Materialidad" 0.1). Los prototipos de esta
  /// fase la usan como mucho en una cabecera de altura fija.
  static const surfaceFelt = Color(0xFF123B29);

  // Metal de marca — máximo un uso de superficie por pantalla (ver
  // FLOPLY_DESIGN_LANGUAGE.md §5.1 "Metal de acento").
  static const brass = Color(0xFFC89B4A);
  static const brassBright = Color(0xFFE4C179);

  /// Texto/ícono de `brass` sobre `surfaceReading` (marfil) — `brass` puro
  /// mide 2.17:1 ahí (FALLA WCAG AA), hallazgo real de la Fase 1.5 (ver
  /// `FLOPLY_VISUAL_STRESS_TEST.md` §J). `brassDeep` sobre `surfaceReading`
  /// mide 5.39:1. Regla: `brass`/`brassBright` = relleno o texto sobre
  /// fondo OSCURO; `brassDeep` = texto/ícono sobre superficie CLARA.
  static const brassDeep = Color(0xFF7A5A22);

  // Temperatura por sección. IMPORTANTE (Fase 1.5): estos 3 valores base
  // están calibrados para SUPERFICIE/RELLENO/BORDE, no para texto ni
  // ícono — medidos contra `background`/`surfaceElevated` dan 2.3-3.5:1,
  // por debajo de AA. Para texto/ícono usar SIEMPRE la variante `*Bright`
  // de abajo (≥5.5:1 contra `background` y `surfaceElevated`).
  static const feltGreen = Color(0xFF1F6E4A); // Academia — superficie/relleno
  static const steelBlue = Color(0xFF3E6E8E); // Laboratorio — superficie/relleno
  static const graphiteSteel = Color(0xFF4A4E54); // Tools — superficie/relleno

  static const feltGreenBright = Color(0xFF32B277); // Academia — texto/ícono
  static const steelBlueBright = Color(0xFF5DA5D5); // Laboratorio — texto/ícono
  static const graphiteSteelBright = Color(0xFF8C949F); // Tools — texto/ícono

  // Semánticos
  static const success = Color(0xFF3FA66B);
  static const warning = Color(0xFFC97A3B);
  static const error = Color(0xFFB23B3B);

  /// `error` puro mide 3.31:1 contra `background` — pasa el umbral de
  /// "texto grande" pero no el de texto normal/negrita chica (los chips de
  /// estado usan 12.5sp). Usar `errorBright` (5.2-5.5:1) para texto/ícono;
  /// `error` queda para relleno/borde donde 3:1 alcanza.
  static const errorBright = Color(0xFFF04F4F);
  static const information = Color(0xFF4E8CA6);
  static const disabled = Color(0xFF4A463C);

  // Texto sobre superficies oscuras
  static const textPrimary = Color(0xFFF1ECE0);
  static const textSecondary = Color(0xFFB9AF9C);
  static const textMuted = Color(0xFF7C7568);

  // Texto sobre `surfaceReading` (marfil)
  static const inkPrimary = Color(0xFF241E14);
  static const inkSecondary = Color(0xFF5A5140);

  static const borderSubtle = Color(0xFF2B271E);
  static const separator = Color(0xFF241F17);
}

/// `space.*` — ver `FLOPLY_DESIGN_LANGUAGE.md` §5.3. Unidad base 4px.
abstract final class ProtoSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 48.0;
}

/// `radius.*` — ver `FLOPLY_DESIGN_LANGUAGE.md` §5.4. Cinco valores, cada
/// uno con un significado (tocable / legible / instrumento / estado /
/// sheet) — nunca un sexto valor inventado por pantalla.
abstract final class ProtoRadius {
  static const sharp = 2.0;
  static const panel = 10.0;
  static const control = 14.0;
  static const pill = 999.0;
  static const sheet = 20.0;
}

/// `elevation.*` — ver `FLOPLY_DESIGN_LANGUAGE.md` §5.5. Máximo 2 niveles
/// reales; nivel 0 es "sin sombra", no está acá porque no es una lista de
/// BoxShadow sino la ausencia de una.
abstract final class ProtoElevation {
  /// Nivel 1 — "apoyado": sombra de contacto corta y dura.
  static const level1 = [
    BoxShadow(color: Color(0x59000000), offset: Offset(0, 2), blurRadius: 6),
  ];

  /// Nivel 2 — "flotante": overlays reales únicamente (sheets, diálogos).
  static const level2 = [
    BoxShadow(color: Color(0x73000000), offset: Offset(0, 8), blurRadius: 20),
  ];
}

/// `motion.*` — ver `FLOPLY_MOTION.md`. Sistema canónico cerrado en Fase
/// 1.75: `instant`/`fast` (Responder) y `normal`/`emphasis` (Asentarse).
/// `instant = 110ms`, no 100 — es el valor real de `PressableScale`
/// (`lib/widgets/pressable_scale.dart:40`); se adoptó el token al código
/// real en vez de al revés.
abstract final class ProtoMotion {
  // Responder
  static const instant = Duration(milliseconds: 110);
  static const fast = Duration(milliseconds: 160);
  // Asentarse
  static const normal = Duration(milliseconds: 220);
  static const emphasis = Duration(milliseconds: 320);

  // Alias heredados de Fase 1 — mismo valor que `fast`/`normal`/`emphasis`,
  // se mantienen para no romper referencias existentes en el playground.
  static const quick = fast;
  static const settle = normal;
  static const reveal = emphasis;

  static const respondCurve = Curves.easeInOut;
  static const settleCurve = Curves.easeOut;
}

/// `type.*` — ver `FLOPLY_DESIGN_LANGUAGE.md` §5.2. Tres familias
/// conceptuales (display/UI/numérica), una sola fuente física en este
/// prototipo (ver nota de cabecera).
abstract final class ProtoType {
  static const _tabular = [FontFeature.tabularFigures()];

  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: ProtoColor.textPrimary,
  );

  static const headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: ProtoColor.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: ProtoColor.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ProtoColor.textPrimary,
  );

  static const bodyStrong = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: ProtoColor.textPrimary,
  );

  static const label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.4,
    color: ProtoColor.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.2,
    color: ProtoColor.textSecondary,
  );

  /// Firma tipográfica más importante del sistema — obligatoria para todo
  /// BB/%/EV/frecuencia/saldo/contador (`FLOPLY_ANTI_GENERIC.md` regla 12).
  static const numericDisplay = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.1,
    color: ProtoColor.textPrimary,
    fontFeatures: _tabular,
  );

  static const numericInline = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: ProtoColor.textPrimary,
    fontFeatures: _tabular,
  );

  static const numericMicro = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: ProtoColor.textSecondary,
    fontFeatures: _tabular,
  );

  /// Variantes sobre `surfaceReading` (marfil) — único lugar donde el
  /// color de texto es `ink*` en vez de `text*`.
  static TextStyle onReading(TextStyle base, {bool secondary = false}) {
    return base.copyWith(
      color: secondary ? ProtoColor.inkSecondary : ProtoColor.inkPrimary,
    );
  }
}

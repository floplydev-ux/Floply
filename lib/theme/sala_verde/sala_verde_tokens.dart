/// Tokens de producción de "Sala Verde" — ver
/// `docs/design/FLOPLY_DESIGN_DECISIONS.md` para el contrato completo de
/// cada decisión (color, tipografía, motion) y `docs/design/
/// FLOPLY_DESIGN_LANGUAGE.md` para la especificación.
///
/// **Alcance:** Fase 2 lo empezó consumiendo solo desde `lib/screens/home/`;
/// Fase 3 lo extiende a `lib/screens/academy/widgets/level_map.dart` y
/// `written_theory_view.dart` (mapa + teoría piloto). `AppColors`/
/// `AppTheme` (`lib/theme/app_colors.dart`/`app_theme.dart`) siguen sin
/// tocarse y siguen siendo la fuente real del resto de Academia
/// (ejercicios/feedback/resultado, compartidos con Bankroll vía
/// `lesson_widgets.dart` — fuera de alcance de Fase 3) y de Laboratorio/
/// Tools/Bankroll — la migración es incremental, no un reemplazo global.
library;

import 'package:flutter/material.dart';

/// `color.*` — valores verificados con contraste WCAG real (Fase 1.5) y
/// con la regla de "variante según uso" cerrada en Fase 1.75: los colores
/// de temperatura y `error` tienen una forma base (relleno/superficie) y
/// una forma `Bright` (texto/ícono sobre fondo oscuro) — nunca un único
/// valor para los dos usos.
abstract final class SalaVerdeColors {
  // Superficies
  static const background = Color(0xFF0E0D0B);
  static const surface = Color(0xFF17140F);
  static const surfaceElevated = Color(0xFF211C15);

  // Metal de marca — máximo un relleno de superficie por pantalla (ver
  // FLOPLY_ANTI_GENERIC.md "Materialidad" 0.2).
  static const brass = Color(0xFFC89B4A);
  static const brassBright = Color(0xFFE4C179);

  /// Texto/ícono de brass sobre `surfaceReading` (marfil) — `brass` puro
  /// mide 2.17:1 ahí (falla), `brassDeep` mide 5.39:1. Regla: `brass`/
  /// `brassBright` para fondo oscuro, `brassDeep` para superficie clara.
  static const brassDeep = Color(0xFF7A5A22);

  // Temperatura de Academia (feltGreen) — relleno/superficie. Texto/ícono
  // usa feltGreenBright.
  static const feltGreen = Color(0xFF1F6E4A);
  static const feltGreenBright = Color(0xFF32B277);

  // Temperatura de Laboratorio/Tools — Home solo las usa como ÍCONO en sus
  // 2 link cards hacia esas secciones (Practice Room → Laboratorio, Tools
  // → Tools), nunca como relleno de superficie acá.
  static const steelBlueBright = Color(0xFF5DA5D5);
  static const graphiteSteelBright = Color(0xFF8C949F);

  // Acento violeta — tratamiento puntual de la tarjeta grande de Academia
  // y del bloque de nivel en el Home rediseñado (pedido explícito del
  // usuario). Deliberadamente NO es un cambio de la identidad de sección:
  // el resto de Academia (mapa, lección, ejercicios, Estadísticas) sigue
  // usando feltGreen/feltGreenBright de arriba, sin tocar — dos pantallas
  // pueden mostrar un acento distinto para la misma sección durante esta
  // transición, a propósito, hasta que se decida si conviene extenderlo.
  static const violet = Color(0xFF5B3FA6);
  static const violetBright = Color(0xFF9C7EE8);

  // Semánticos
  static const success = Color(0xFF3FA66B);
  static const warning = Color(0xFFC97A3B);
  static const error = Color(0xFFB23B3B);
  static const errorBright = Color(0xFFF04F4F);

  /// Superficie "papel" — exclusiva de lectura larga (teoría). Fase 3: primer
  /// uso en producción. Nunca en botones/chips ni fuera de Academia/Bankroll
  /// (`FLOPLY_DESIGN_LANGUAGE.md` §5.1).
  static const surfaceReading = Color(0xFFF3ECDD);

  // Texto
  static const textPrimary = Color(0xFFF1ECE0);
  static const textSecondary = Color(0xFFB9AF9C);
  static const textMuted = Color(0xFF7C7568);

  // Texto sobre surfaceReading — nunca text*/brass ahí (brass puro mide
  // 2.17:1 sobre marfil, falla — ver FLOPLY_DESIGN_DECISIONS.md #7).
  static const inkPrimary = Color(0xFF241E14);
  static const inkSecondary = Color(0xFF5A5140);

  static const borderSubtle = Color(0xFF2B271E);
}

/// `space.*` — unidad base 4px (`FLOPLY_DESIGN_LANGUAGE.md` §5.3).
abstract final class SalaVerdeSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 48.0;
}

/// `radius.*` — 5 valores con significado, nunca un sexto inventado.
abstract final class SalaVerdeRadius {
  static const sharp = 2.0;
  static const panel = 10.0;
  static const control = 14.0;
  static const pill = 999.0;
  static const sheet = 20.0;
}

/// `elevation.*` — máximo 2 niveles reales.
abstract final class SalaVerdeElevation {
  static const level1 = [
    BoxShadow(color: Color(0x59000000), offset: Offset(0, 2), blurRadius: 6),
  ];
  static const level2 = [
    BoxShadow(color: Color(0x73000000), offset: Offset(0, 8), blurRadius: 20),
  ];
}

/// `motion.*` — sistema canónico cerrado en Fase 1.75
/// (`FLOPLY_DESIGN_DECISIONS.md` #5). `instant=110ms` porque es el valor
/// real de `PressableScale` (`lib/widgets/pressable_scale.dart:40`) — el
/// token se adaptó al código existente, no al revés.
abstract final class SalaVerdeMotion {
  static const instant = Duration(milliseconds: 110);
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 220);
  static const emphasis = Duration(milliseconds: 320);

  static const respondCurve = Curves.easeInOut;
  static const settleCurve = Curves.easeOut;
}

/// `type.*` — Fraunces (display) + Public Sans (UI/body) + IBM Plex Mono
/// (numérica), las 3 bajo SIL OFL 1.1 (verificado, ver
/// `FLOPLY_DESIGN_DECISIONS.md` #3). Fraunces/Public Sans son variable
/// fonts — el peso se pide vía `fontVariations`, no solo `fontWeight`
/// (Flutter necesita ambos: `fontWeight` para métricas de fallback,
/// `fontVariations` para que el eje `wght` real se aplique).
abstract final class SalaVerdeType {
  static TextStyle _display({required double size, required FontWeight weight, Color? color}) {
    return TextStyle(
      fontFamily: 'Fraunces',
      fontVariations: [FontVariation('wght', weight.value.toDouble()), const FontVariation('opsz', 72)],
      fontWeight: weight,
      fontSize: size,
      height: 1.2,
      color: color ?? SalaVerdeColors.textPrimary,
    );
  }

  static TextStyle _ui({required double size, required FontWeight weight, Color? color, double? letterSpacing, double? height}) {
    return TextStyle(
      fontFamily: 'PublicSans',
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      fontWeight: weight,
      fontSize: size,
      letterSpacing: letterSpacing,
      height: height ?? 1.4,
      color: color ?? SalaVerdeColors.textPrimary,
      decoration: TextDecoration.none,
    );
  }

  /// Título de mayor jerarquía visible (lección actual, título de logro).
  static TextStyle headline({Color? color}) =>
      _display(size: 21, weight: FontWeight.w600, color: color);

  static TextStyle title({Color? color}) =>
      _ui(size: 18, weight: FontWeight.w700, color: color);

  static TextStyle body({Color? color}) =>
      _ui(size: 13.5, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle bodyStrong({Color? color}) =>
      _ui(size: 14.5, weight: FontWeight.w700, color: color, letterSpacing: 0.2);

  static TextStyle label({Color? color}) => _ui(
        size: 11,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 1,
        height: 1.2,
      );

  static TextStyle caption({Color? color}) =>
      _ui(size: 12, weight: FontWeight.w500, color: color, height: 1.3);

  /// Única familia numérica del sistema — obligatoria para todo BB/%/EV/
  /// frecuencia/saldo/contador (`FLOPLY_ANTI_GENERIC.md` regla 12). Home
  /// solo la usa hoy para el % de progreso — el resto de las cifras siguen
  /// embebidas en oraciones (`academyLessonsDone`) y se dejan en Public
  /// Sans hasta que valga la pena separar dígitos de prosa con RichText
  /// (ver `docs/design/FLOPLY_PHASE_2_HOME.md` §N, pendiente documentado).
  ///
  /// Usa IBM Plex Mono SemiBold (w600) — para las constantes reutilizables de
  /// [SvMonoStyles] con más granularidad de peso, ver
  /// `lib/theme/sala_verde/sala_verde_typography.dart`.
  static TextStyle numeric({double size = 14, Color? color}) => TextStyle(
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.w600,
        fontSize: size,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? SalaVerdeColors.textPrimary,
      );

  /// Reescribe [base] para vivir sobre `surfaceReading` (marfil) — único
  /// lugar del sistema donde el texto usa `ink*` en vez de `text*`. Fase 3,
  /// primer uso en producción.
  static TextStyle onReading(TextStyle base, {bool secondary = false}) {
    return base.copyWith(
      color: secondary ? SalaVerdeColors.inkSecondary : SalaVerdeColors.inkPrimary,
    );
  }
}

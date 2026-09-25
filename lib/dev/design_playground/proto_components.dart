/// PROTOTIPO — Fase 1. Componentes fundamentales de "Sala Verde" usados
/// por las 3 pantallas de prueba (Home / Academia-teoría /
/// Laboratorio-ejercicio). Ver `docs/design/FLOPLY_COMPONENTS.md` — cada
/// widget de acá es la versión mínima-jugable de un componente ya
/// documentado ahí, no uno nuevo inventado para el prototipo.
///
/// Deliberadamente NO se crean variantes por pantalla (nada de
/// `HomeCard`/`AcademyCard`/`LabCard`): las tres pantallas comparten estos
/// mismos 9 widgets, solo cambiando color de acento y contenido — es en sí
/// mismo la prueba de que el sistema es pequeño y expresivo (Fase 1,
/// "COMPONENTES" del prompt maestro).
library;

import 'package:flutter/material.dart';

import '../../widgets/pressable_scale.dart';
import 'proto_tokens.dart';

/// `AppBar` / Section Header — ver `FLOPLY_COMPONENTS.md` "AppBar / Section
/// Header". Ícono acompañante (nunca protagonista) + headline + caption.
///
/// `accent` pinta el ÍCONO — pasar siempre una variante `*Bright`
/// (`feltGreenBright`/`steelBlueBright`/`graphiteSteelBright`) cuando el
/// acento es de temperatura de sección: los valores base están calibrados
/// para superficie/relleno y no llegan a 3:1 contra `background` (ver
/// `proto_tokens.dart` y `FLOPLY_VISUAL_STRESS_TEST.md` §J).
class ProtoSectionHeader extends StatelessWidget {
  const ProtoSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = ProtoColor.brass,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 26, color: accent),
        const SizedBox(width: ProtoSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ProtoType.headline),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: ProtoType.caption),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// `component.card.panel` — agrupa contenido de solo lectura. Plano,
/// sin sombra (nivel 0): se distingue por color de superficie, no por
/// elevación (ver `FLOPLY_DESIGN_LANGUAGE.md` §5.5).
class ProtoSurfacePanel extends StatelessWidget {
  const ProtoSurfacePanel({
    super.key,
    required this.child,
    this.color = ProtoColor.surface,
    this.padding = const EdgeInsets.all(ProtoSpace.lg),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ProtoRadius.panel),
        border: Border.all(color: ProtoColor.borderSubtle),
      ),
      child: child,
    );
  }
}

/// `component.card.tappable` — entidad tocable (lección, ejercicio,
/// destino de Home). Elevación nivel 1: sombra de contacto corta, no
/// glow ni blur — "esto se puede levantar/tocar".
class ProtoTappableCard extends StatelessWidget {
  const ProtoTappableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(ProtoSpace.lg),
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: ProtoColor.surfaceElevated,
          borderRadius: BorderRadius.circular(ProtoRadius.control),
          boxShadow: ProtoElevation.level1,
        ),
        child: child,
      ),
    );
  }
}

/// `component.card.reading` — superficie "papel" para teoría/prosa larga.
/// Deliberadamente sin borde de acento ni textura: el "presupuesto de
/// materialidad" (Fase 0.5) exige que esta superficie quede plana porque
/// se lee cientos de veces a lo largo del currículo.
class ProtoReadingCard extends StatelessWidget {
  const ProtoReadingCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ProtoSpace.xl),
      decoration: BoxDecoration(
        color: ProtoColor.surfaceReading,
        borderRadius: BorderRadius.circular(ProtoRadius.panel),
      ),
      child: child,
    );
  }
}

/// Botón primario. Fondo `brass` por defecto (el único uso de superficie
/// en ese color en la pantalla que lo contenga — ver regla de escasez) o
/// un acento de sección si la acción es específica de esa área.
class ProtoButtonPrimary extends StatelessWidget {
  const ProtoButtonPrimary({
    super.key,
    required this.label,
    required this.onTap,
    this.accent = ProtoColor.brass,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final Color accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accent : ProtoColor.disabled;

    // Hallazgo real de la Fase 1.5 (ver FLOPLY_VISUAL_STRESS_TEST.md §J):
    // este botón asumía texto oscuro fijo, correcto para `brass` (claro)
    // pero midiendo solo 3.54:1 con `steelBlue` de relleno (falla AA para
    // texto de botón).
    //
    // **Corrección (Fase 2):** la primera versión de este fix comparaba
    // `color.computeLuminance() > 0.4` — un umbral adivinado. `brass` mide
    // 0.36 de luminancia (por debajo del umbral), así que ese atajo elegía
    // `textPrimary` sobre `brass` (2.16:1, FALLA) en vez de `background`
    // (7.63:1, la pareja correcta) — lo detectó el test de accesibilidad
    // real al migrar Home a producción (`SvButtonPrimary`, el equivalente
    // productivo de este widget). Ahora se comparan los 2 contrastes reales
    // y gana el que mida más, sin umbral fijo.
    double contrast(Color a, Color b) {
      final l1 = a.computeLuminance();
      final l2 = b.computeLuminance();
      final brighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (brighter + 0.05) / (darker + 0.05);
    }

    final textColor = contrast(color, ProtoColor.background) >= contrast(color, ProtoColor.textPrimary)
        ? ProtoColor.background
        : ProtoColor.textPrimary;

    return PressableScale(
      onTap: enabled ? (onTap ?? () {}) : () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(ProtoRadius.control),
          boxShadow: enabled ? ProtoElevation.level1 : null,
        ),
        child: Text(
          label,
          style: ProtoType.bodyStrong.copyWith(
            color: textColor,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Botón secundario — sin relleno, borde sutil. Para "volver"/"cancelar"
/// junto a un primario.
class ProtoButtonSecondary extends StatelessWidget {
  const ProtoButtonSecondary({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return PressableScale(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ProtoRadius.control),
          border: Border.all(
            color: enabled ? ProtoColor.borderSubtle : ProtoColor.disabled,
          ),
        ),
        child: Text(
          label,
          style: ProtoType.bodyStrong.copyWith(
            color: enabled ? ProtoColor.textPrimary : ProtoColor.disabled,
          ),
        ),
      ),
    );
  }
}

/// `component.chip.numeric` — BB/%/EV/frecuencia inline. Nunca envuelve el
/// dato protagonista único de una pantalla (ahí va `numericDisplay` suelto).
///
/// El fondo del chip es siempre `surfaceElevated` (oscuro) — si `accent`
/// pinta el VALOR, tiene que ser un color que ya rinda ≥4.5:1 ahí. Los 3
/// colores de temperatura de sección en su forma base NO cumplen eso
/// (ver `proto_tokens.dart`): usar sus variantes `*Bright`.
class ProtoChipNumeric extends StatelessWidget {
  const ProtoChipNumeric({
    super.key,
    required this.value,
    this.label,
    this.accent = ProtoColor.textPrimary,
  });

  final String value;
  final String? label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ProtoSpace.sm, vertical: 5),
      decoration: BoxDecoration(
        color: ProtoColor.surfaceElevated,
        borderRadius: BorderRadius.circular(ProtoRadius.sharp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            // Flexible + ellipsis, no Text suelto: un label real y largo
            // ("EQUITY NECESARIA", `AppStrings.potOddsRequiredEquityLabel`)
            // desbordaba 10px a 300dp — hallazgo real de la Fase 1.5 (ver
            // FLOPLY_VISUAL_STRESS_TEST.md §J). El VALOR numérico nunca se
            // trunca (es la firma del sistema); el label sí puede.
            Flexible(
              child: Text(
                label!,
                style: ProtoType.caption,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: ProtoSpace.xs),
          ],
          Text(value, style: ProtoType.numericInline.copyWith(color: accent)),
        ],
      ),
    );
  }
}

/// Familia **Status Indicator**, variante pill — evaluación puntual
/// (correcto/aceptable/incorrecto). La variante círculo (progresión de
/// nivel/lección) no se usa en esta fase — no hay pantalla de mapa entre
/// las 3 pruebas — y por eso no se prototipa (regla del prompt: no crear
/// componentes sin necesidad real en esta fase).
class ProtoChipStatus extends StatelessWidget {
  const ProtoChipStatus({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ProtoSpace.md, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(ProtoRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: ProtoType.label.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// `component.callout.accent` — la ÚNICA implementación de "regla de
/// acento + label + cuerpo" del sistema (ver nota de consolidación en
/// `FLOPLY_COMPONENTS.md`: objective pill, idea clave y feedback panel son
/// la misma base). Regla vertical de color, no una caja completa con
/// borde — deliberadamente más liviano que el patrón "card con borde"
/// que hoy se repite 6 veces en el código real.
class ProtoCalloutAccent extends StatelessWidget {
  const ProtoCalloutAccent({
    super.key,
    required this.eyebrow,
    required this.body,
    required this.color,
    this.icon,
    this.onReading = false,
  });

  final String eyebrow;
  final String body;
  final Color color;
  final IconData? icon;

  /// Si vive dentro de un `ProtoReadingCard` (marfil), el cuerpo usa
  /// `ink*` en vez de `text*`.
  final bool onReading;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = onReading
        ? ProtoType.onReading(ProtoType.body, secondary: false)
        : ProtoType.body;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 3, color: color),
          const SizedBox(width: ProtoSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      eyebrow,
                      style: ProtoType.label.copyWith(color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body, style: bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `component.progress.linear` — reemplaza las 4 barras duplicadas del
/// código real. Anima con `motion.duration.reveal`, nunca salta.
class ProtoProgressLinear extends StatelessWidget {
  const ProtoProgressLinear({
    super.key,
    required this.value,
    this.color = ProtoColor.brass,
    this.height = 6,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ProtoRadius.sharp),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Hallazgo real de Fase 2 (verificación en navegador real,
            // ver FLOPLY_PHASE_2_HOME.md §K): surfaceElevated como track
            // es invisible cuando la barra vive sobre una card que ya usa
            // surfaceElevated de fondo (ProtoTappableCard) — a 0% no se
            // veía nada. borderSubtle es un paso más claro, visible.
            Container(color: ProtoColor.borderSubtle),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: ProtoMotion.reveal,
              curve: ProtoMotion.settleCurve,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Componentes de producción de "Sala Verde" — promovidos desde
/// `lib/dev/design_playground/proto_components.dart` tras la Fase 1.5
/// (stress test) y la Fase 1.75 (cierre de reglas). Ver
/// `docs/design/FLOPLY_COMPONENTS.md` ("Estado para producción") para la
/// auditoría componente por componente.
///
/// Fase 2 (Home) promovió `SvTappableCard`, `SvButtonPrimary`,
/// `SvChipNumeric`/`SvChipNumericGroup`, `SvProgressLinear`. Fase 3
/// (Academia — mapa + teoría piloto) agrega `SvButtonSecondary`,
/// `SvCalloutAccent`, `SvReadingCard` y `SvSectionHeader` (este último con
/// guardrails explícitos, ver su doc-comment — Academia es el primer
/// consumidor real del patrón ícono+título+subtítulo).
library;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../pressable_scale.dart';

/// `component.card.panel` — agrupa contenido relacionado sin implicar que
/// se puede tocar. Plano, sin sombra (nivel 0): se distingue por color de
/// superficie, no por elevación. Fase 3: primer uso en producción (tira de
/// progreso y cards de nivel del mapa de Academia — la card en sí no es
/// tocable, solo cada fila de lección adentro).
class SvSurfacePanel extends StatelessWidget {
  const SvSurfacePanel({
    super.key,
    required this.child,
    this.borderColor = SalaVerdeColors.borderSubtle,
    this.padding = const EdgeInsets.all(SalaVerdeSpace.lg),
  });

  final Widget child;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

/// `component.card.tappable` — entidad tocable con sombra de contacto
/// (nivel 1). Reutiliza `PressableScale` real, sin copia.
class SvTappableCard extends StatelessWidget {
  const SvTappableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(SalaVerdeSpace.lg),
    this.opacity = 1.0,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  /// Único uso: el estado `muted` de una card secundaria (p. ej. Coach,
  /// "próximamente") — opacidad reducida del conjunto, no solo del texto,
  /// porque acá no hay información que el usuario deba poder seguir
  /// leyendo (a diferencia de un candado, donde sí — ver
  /// `FLOPLY_DESIGN_LANGUAGE.md` §5.1, regla de `disabled`).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        boxShadow: SalaVerdeElevation.level1,
      ),
      child: child,
    );
    return PressableScale(
      onTap: onTap,
      child: opacity == 1.0 ? card : Opacity(opacity: opacity, child: card),
    );
  }
}

/// Contraste WCAG real entre dos colores, a partir de su luminancia
/// relativa (`Color.computeLuminance()` ya hace la corrección de gamma
/// sRGB) — sin esto, un umbral de luminancia "a ojo" puede clasificar mal
/// un color intermedio (ver el bug real que corrigió esta función).
double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final brighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (brighter + 0.05) / (darker + 0.05);
}

/// Botón primario. El color de texto se elige comparando el contraste
/// real contra las dos opciones (`background` vs. `textPrimary`) y
/// quedándose con la que gane — no un umbral de luminancia fijo.
///
/// **Hallazgo real (Fase 2):** la primera versión de este widget (y su
/// equivalente de playground, `ProtoButtonPrimary`) usaba
/// `accent.computeLuminance() > 0.4` como atajo. `brass` mide 0.36 de
/// luminancia — por debajo del umbral — así que el atajo elegía
/// `textPrimary` (2.16:1 contra `brass`, FALLA) en vez de `background`
/// (7.63:1, la pareja correcta, ya verificada en Fase 1.5). Lo detectó
/// `test/accessibility/core_screens_accessibility_test.dart` al migrar
/// Home a producción — un umbral adivinado no es lo mismo que medir.
class SvButtonPrimary extends StatelessWidget {
  const SvButtonPrimary({
    super.key,
    required this.label,
    required this.onTap,
    this.accent = SalaVerdeColors.brass,
  });

  final String label;

  /// `null` lo deja deshabilitado (opacidad reducida, sin acción) — Fase 5
  /// lo necesitó para el botón CONFIRMAR de `ExerciseView`
  /// (`LessonPrimaryButton`, que reemplaza, ya soportaba esto).
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final contrastWithDark = _contrastRatio(accent, SalaVerdeColors.background);
    final contrastWithLight = _contrastRatio(accent, SalaVerdeColors.textPrimary);
    final textColor = contrastWithDark >= contrastWithLight
        ? SalaVerdeColors.background
        : SalaVerdeColors.textPrimary;
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: PressableScale(
        onTap: onTap ?? () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
            boxShadow: SalaVerdeElevation.level1,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: SalaVerdeType.bodyStrong(color: textColor),
          ),
        ),
      ),
    );
  }
}

/// `component.chip.numeric` — BB/%/EV/frecuencia inline. El label puede
/// truncarse (`Flexible` + ellipsis); el valor numérico NUNCA se corta —
/// es la firma tipográfica del sistema.
///
/// Este widget solo, usado directo dentro de un `Row`, es exactamente lo
/// que produjo el overflow real de la Fase 1.5 (`AppStrings.
/// potOddsRequiredEquityLabel`, 300dp). Por eso el uso recomendado —y el
/// único que expone el sistema de producción— es a través de
/// [SvChipNumericGroup], no de este widget suelto en un `Row`.
class SvChipNumeric extends StatelessWidget {
  const SvChipNumeric({super.key, required this.value, this.label, this.accent});

  final String value;
  final String? label;

  /// Debe ser una variante `*Bright`/semántica ya segura para texto sobre
  /// `surfaceElevated` (ver `FLOPLY_DESIGN_LANGUAGE.md` "Principio de
  /// contraste por contexto de uso") — nunca un color de relleno base.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SalaVerdeSpace.sm, vertical: 5),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.sharp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Flexible(
              child: Text(
                label!,
                style: SalaVerdeType.caption(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: SalaVerdeSpace.xs),
          ],
          Text(value, style: SalaVerdeType.numeric(color: accent)),
        ],
      ),
    );
  }
}

/// Guardrail de la Fase 1.75/2 (`docs/design/FLOPLY_COMPONENTS.md`,
/// `ProtoChipNumeric` — estado B): el bug real de la Fase 1.5 fue posible
/// porque nada impedía poner 2+ `chip.numeric` en un `Row` rígido. Este
/// wrapper hace que la forma correcta (`Wrap`) sea la única disponible en
/// el sistema de producción — no existe una versión "en Row" que un
/// desarrollador pueda elegir por error.
class SvChipNumericGroup extends StatelessWidget {
  const SvChipNumericGroup({super.key, required this.chips});

  final List<SvChipNumeric> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SalaVerdeSpace.sm,
      runSpacing: SalaVerdeSpace.sm,
      children: chips,
    );
  }
}

/// `component.progress.linear` — anima con `emphasis` (320ms), nunca
/// salta de valor.
///
/// **Hallazgo real (Fase 2, verificación en navegador real — ver
/// `FLOPLY_PHASE_2_HOME.md` §K):** el track usaba `surfaceElevated`, el
/// mismo color que la card donde vive (`_HeroShell` de Home) — a 0%
/// de progreso (usuario nuevo) la barra quedaba invisible, no solo vacía.
/// El track ahora usa `borderSubtle` (un paso más claro), visible incluso
/// sin relleno.
class SvProgressLinear extends StatelessWidget {
  const SvProgressLinear({
    super.key,
    required this.value,
    this.color = SalaVerdeColors.brass,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SalaVerdeRadius.sharp),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: SalaVerdeColors.borderSubtle),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: SalaVerdeMotion.emphasis,
              curve: SalaVerdeMotion.settleCurve,
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

/// Botón secundario — sin relleno, borde sutil. Para "volver"/"cancelar"
/// junto a un primario. Deshabilitado si `onTap` es `null`.
class SvButtonSecondary extends StatelessWidget {
  const SvButtonSecondary({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return PressableScale(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          border: Border.all(
            color: enabled ? SalaVerdeColors.borderSubtle : SalaVerdeColors.textMuted,
          ),
        ),
        child: Text(
          label,
          style: SalaVerdeType.bodyStrong(
            color: enabled ? SalaVerdeColors.textPrimary : SalaVerdeColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// `component.callout.accent` — la única implementación de "regla de
/// acento + label + cuerpo" del sistema (objetivo, idea clave, feedback —
/// ver `FLOPLY_COMPONENTS.md` "Answer States / Feedback Panels — también
/// es component.callout.accent"). Regla vertical de color, no una caja
/// completa con borde — deliberadamente más liviana que el patrón "card
/// con borde de acento" que la auditoría original encontró repetido 6
/// veces en el código real de Academia.
class SvCalloutAccent extends StatelessWidget {
  const SvCalloutAccent({
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

  /// Si vive dentro de un [SvReadingCard] (marfil), el cuerpo usa `ink*`
  /// en vez de `text*` — ver `SalaVerdeType.onReading`.
  final bool onReading;

  @override
  Widget build(BuildContext context) {
    final bodyStyle =
        onReading ? SalaVerdeType.onReading(SalaVerdeType.body()) : SalaVerdeType.body();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 3, color: color),
          const SizedBox(width: SalaVerdeSpace.md),
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
                    Flexible(
                      child: Text(
                        eyebrow,
                        style: SalaVerdeType.label(color: color),
                        overflow: TextOverflow.ellipsis,
                      ),
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

/// `component.card.reading` — superficie "papel" para teoría/prosa larga.
/// Deliberadamente sin borde de acento ni textura: el "presupuesto de
/// materialidad" (Fase 0.5) exige que esta superficie quede plana porque
/// se lee cientos de veces a lo largo del currículo. Fase 3: primer uso en
/// producción (326 teorías la consumen a través de `WrittenTheoryView`).
class SvReadingCard extends StatelessWidget {
  const SvReadingCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SalaVerdeSpace.xl),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceReading,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
      ),
      child: child,
    );
  }
}

/// `component.progress.item` — barra "actual / total" de los ítems de un
/// ejercicio (Fase 5). Mismo patrón que el `_Progress` privado de
/// `written_theory_view.dart`/`bankroll_screen.dart` (Fases 3/4), pero acá
/// se promueve a compartido porque `ExerciseView` y `FeedbackView` lo
/// necesitan con forma idéntica — la 3ª/4ª repetición del mismo patrón ya
/// justifica un componente en vez de otra copia privada (criterio de la
/// Sección 20 del prompt de Fase 5). No reemplaza a `LessonItemProgress`
/// de `lesson_widgets.dart`: ese sigue en uso por teoría-mentor/visual,
/// fuera de alcance de esta fase (ver `FLOPLY_PHASE_5_...md`).
class SvItemProgress extends StatelessWidget {
  const SvItemProgress({
    super.key,
    required this.current,
    required this.total,
    this.color = SalaVerdeColors.feltGreenBright,
  });

  final int current;
  final int total;

  /// Temperatura de la sección — `feltGreenBright` (Academia, default) o
  /// `steelBlueBright` (Laboratorio, Fase 7).
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: SvProgressLinear(
            value: ratio.toDouble(),
            color: color,
          ),
        ),
        const SizedBox(width: SalaVerdeSpace.md),
        Text(
          '$current / $total',
          style: SalaVerdeType.numeric(size: 12, color: SalaVerdeColors.textMuted),
        ),
      ],
    );
  }
}

/// `component.nav.lesson` — controles ATRÁS / CONTINUAR de un recorrido de
/// lectura paso a paso (teoría de Academia, Bankroll). Promovido en la
/// Fase 4 desde `_TheoryNavControls`, privado de `written_theory_view.dart`
/// (Fase 3) — en ese momento tenía un solo consumidor real y no se
/// justificaba compartirlo; con Bankroll como segundo consumidor real, sí.
/// Deliberadamente NO es `LessonNavControls` de `lesson_widgets.dart`: ese
/// sigue siendo compartido con exercise/feedback/result (fuera de alcance).
class SvLessonNavControls extends StatelessWidget {
  const SvLessonNavControls({
    super.key,
    required this.canGoBack,
    required this.buttonLabel,
    required this.onBack,
    required this.onNext,
    this.counter,
  });

  final bool canGoBack;
  final String buttonLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  /// Texto opcional entre los dos botones (p. ej. "3 / 7") — Fase 6,
  /// `InteractiveTableLesson` es el 3er consumidor real y el primero que
  /// lo necesita (`written_theory_view.dart`/`bankroll_screen.dart` ya
  /// muestran su propio contador arriba, vía `SvItemProgress`/`_Progress`).
  /// `null` lo oculta.
  final String? counter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: canGoBack
              ? SvButtonSecondary(label: AppStrings.academyBack, onTap: onBack)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: SalaVerdeSpace.sm),
        if (counter != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SalaVerdeSpace.sm,
              vertical: SalaVerdeSpace.xs,
            ),
            decoration: BoxDecoration(
              color: SalaVerdeColors.surfaceElevated,
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
            ),
            child: Text(
              counter!,
              style: SalaVerdeType.numeric(size: 12, color: SalaVerdeColors.textMuted),
            ),
          ),
          const SizedBox(width: SalaVerdeSpace.sm),
        ],
        Expanded(child: SvButtonPrimary(label: buttonLabel, onTap: onNext)),
      ],
    );
  }
}

/// `AppBar` / Section Header — ícono acompañante (nunca protagonista) +
/// título + subtítulo opcional. Primer consumidor real: el encabezado del
/// mapa de Academia (`level_map.dart`, Fase 3).
///
/// **Guardrails (Fase 1.75/Fase 3, `FLOPLY_COMPONENTS.md` — `
/// ProtoSectionHeader` estaba en estado B por esto):** la API es
/// deliberadamente angosta —`variant` en vez de un `Color accent` libre—
/// para que no se puedan colar colores/tamaños/sombras arbitrarios. Cada
/// [SvSectionHeaderVariant] ya resuelve, internamente, la variante de
/// contraste correcta (`*Bright`) — quien use el componente no puede
/// pasar por error un color de relleno base que falle contraste como
/// texto/ícono (el bug real que motivó esto en `SvButtonPrimary`/
/// `SvProgressLinear`, ver `FLOPLY_PHASE_2_HOME.md`/`FLOPLY_PHASE_3_ACADEMIA.md`).
enum SvSectionHeaderVariant {
  /// Temperatura de Academia (`feltGreenBright`).
  academy(SalaVerdeColors.feltGreenBright),

  /// Temperatura de Laboratorio (`steelBlueBright`).
  laboratory(SalaVerdeColors.steelBlueBright),

  /// Temperatura de Tools (`graphiteSteelBright`).
  tools(SalaVerdeColors.graphiteSteelBright),

  /// Metal de marca — usar como máximo una vez por pantalla, igual que
  /// cualquier otro uso de `brass` (ver `FLOPLY_ANTI_GENERIC.md` 0.2).
  brand(SalaVerdeColors.brassBright);

  const SvSectionHeaderVariant(this.accent);
  final Color accent;
}

class SvSectionHeader extends StatelessWidget {
  const SvSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.variant,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final SvSectionHeaderVariant variant;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 26, color: variant.accent),
        const SizedBox(width: SalaVerdeSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SalaVerdeType.headline()),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: SalaVerdeType.caption()),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

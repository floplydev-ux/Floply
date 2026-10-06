import 'package:flutter/material.dart';

import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';

/// Componentes compartidos por TODAS las calculadoras de Tools (Grupo 2:
/// profesionalización de Tools) — migrados de `AppColors` (violeta/gold/
/// diamond-blue, un color de marca distinto por herramienta) a Sala
/// Verde, con un único acento compartido (`graphiteSteelBright`, la
/// temperatura de Tools ya definida en `SvSectionHeaderVariant.tools`) en
/// vez de un arcoíris de colores por pantalla — esa es la consistencia
/// que pide la sección 4: misma jerarquía de encabezados, mismo
/// tratamiento de inputs/botones/resultados en las 6 herramientas.
///
/// Los colores semánticos (`SalaVerdeColors.success`/`warning`/`error`)
/// siguen usándose, pero solo para lo que de verdad es semántico (EV
/// positivo/negativo, combo bloqueado) — nunca como "color de marca" de
/// una herramienta puntual.
const Color kToolAccent = SalaVerdeColors.graphiteSteelBright;

/// Encabezado compartido por las pantallas de una herramienta puntual —
/// ícono + título + subtítulo + volver.
class ToolHeader extends StatelessWidget {
  const ToolHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.accentColor = kToolAccent,
    this.trailing,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  /// El ícono ⓘ de ayuda contextual (Grupo 3) se cablea acá — este
  /// header ya reserva el lugar para no tener que rehacer el layout de
  /// las 6 pantallas cuando llegue ese grupo.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SalaVerdeColors.surfaceElevated,
              border: Border.all(color: SalaVerdeColors.borderSubtle),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: SalaVerdeColors.textSecondary, size: 18),
          ),
        ),
        const SizedBox(width: SalaVerdeSpace.md),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.16),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: SalaVerdeSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SalaVerdeType.title()),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Tarjeta contenedora genérica (fondo + borde) para agrupar inputs o una
/// sección de resultado.
class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SalaVerdeSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
        color: SalaVerdeColors.surface,
        border: Border.all(color: borderColor ?? SalaVerdeColors.borderSubtle),
      ),
      child: child,
    );
  }
}

/// Encabezado de una sección de resultado ("RESULTADO PRINCIPAL", "DATOS
/// UTILIZADOS", "INFORMACIÓN COMPLEMENTARIA" — sección 5): separa
/// visualmente qué es el número que importa de qué es contexto, en vez de
/// que todo compita al mismo nivel dentro de la misma tarjeta.
class ToolSectionLabel extends StatelessWidget {
  const ToolSectionLabel(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: SalaVerdeType.label(color: color ?? SalaVerdeColors.textMuted),
    );
  }
}

/// Campo numérico con label + sufijo — mismo estilo para cualquier input
/// de cualquier calculadora. El valor usa IBM Plex Mono (cifras
/// tabulares): es un número que el usuario va a comparar con otros, no
/// prosa.
class ToolNumberField extends StatelessWidget {
  const ToolNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffixText,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: SalaVerdeType.numeric(size: 16),
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffixText,
            suffixStyle: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
            filled: true,
            fillColor: SalaVerdeColors.surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              borderSide: const BorderSide(color: SalaVerdeColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              borderSide: const BorderSide(color: SalaVerdeColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              borderSide: const BorderSide(color: kToolAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo de texto libre con label + hint — para notación de rango
/// (`77+,ATs+`) u otro texto que no sea ni un número ni una carta
/// puntual (esas dos usan [ToolNumberField]/`CardGroupField`).
class ToolTextField extends StatelessWidget {
  const ToolTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          textCapitalization: TextCapitalization.none,
          style: SalaVerdeType.bodyStrong().copyWith(letterSpacing: 0.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: SalaVerdeType.body(color: SalaVerdeColors.textMuted),
            filled: true,
            fillColor: SalaVerdeColors.surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              borderSide: const BorderSide(color: SalaVerdeColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              borderSide: const BorderSide(color: SalaVerdeColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              borderSide: const BorderSide(color: kToolAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de error — entrada inválida o sin datos suficientes. Mensaje
/// siempre en lenguaje humano (nunca "Invalid input"): qué falta o qué
/// hay que corregir, en términos de póker — ver sección 7.
class ToolErrorCard extends StatelessWidget {
  const ToolErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SalaVerdeSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        color: SalaVerdeColors.error.withValues(alpha: 0.12),
        border: Border.all(color: SalaVerdeColors.errorBright.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: SalaVerdeColors.errorBright),
          const SizedBox(width: SalaVerdeSpace.sm),
          Expanded(
            child: Text(
              message,
              style: SalaVerdeType.caption(color: SalaVerdeColors.errorBright)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso informativo (no un error) — mismo contenedor que
/// [ToolErrorCard] pero en tono ámbar, para lo que no bloquea el cálculo
/// pero conviene saber (p. ej. una rama del modelo que quedó afuera).
class ToolWarningCard extends StatelessWidget {
  const ToolWarningCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SalaVerdeSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        color: SalaVerdeColors.warning.withValues(alpha: 0.12),
        border: Border.all(color: SalaVerdeColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: SalaVerdeColors.warning),
          const SizedBox(width: SalaVerdeSpace.sm),
          Expanded(
            child: Text(
              message,
              style: SalaVerdeType.caption(color: SalaVerdeColors.warning)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío/inicial — "todavía no hiciste lo necesario para ver un
/// resultado" (sección 6), nunca una tarjeta de resultado a medio
/// llenar. Mismo lugar en el layout donde iría el resultado, para que la
/// pantalla no "salte" de tamaño al completarse.
class ToolEmptyState extends StatelessWidget {
  const ToolEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.touch_app_rounded,
    this.title,
  });

  final String message;
  final IconData icon;

  /// Encabezado opcional, más prominente que [message] — para el caso
  /// (Range Explorer/BB) donde el estado vacío necesita un hecho corto
  /// ("La BB no abre") ANTES de la explicación, no las dos frases al
  /// mismo nivel visual.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SalaVerdeSpace.lg,
        vertical: SalaVerdeSpace.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
        border: Border.all(color: SalaVerdeColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: SalaVerdeColors.textMuted),
          const SizedBox(height: SalaVerdeSpace.sm),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.textSecondary),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Un valor de resultado con su label — [big] para el resultado
/// PRINCIPAL de la pantalla (uno solo por tarjeta), tamaño normal para
/// los datos que lo acompañan. Siempre en IBM Plex Mono: son cifras que
/// se leen y se comparan, no texto corrido.
class ToolResultStat extends StatelessWidget {
  const ToolResultStat({
    super.key,
    required this.label,
    required this.value,
    this.big = false,
    this.color = SalaVerdeColors.textPrimary,
  });

  final String label;
  final String value;
  final bool big;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: SalaVerdeType.label(color: SalaVerdeColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: SalaVerdeType.numeric(size: big ? 28 : 17, color: color)),
      ],
    );
  }
}

/// Selector de modo compartido (antes `_ModeChip`, duplicado en Equity y
/// EV) — misma pastilla en cualquier herramienta que tenga más de un modo
/// de cálculo.
class ToolModeChip extends StatelessWidget {
  const ToolModeChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
          color: active
              ? kToolAccent.withValues(alpha: 0.16)
              : SalaVerdeColors.surfaceElevated,
          border: Border.all(
            color: active ? kToolAccent : SalaVerdeColors.borderSubtle,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: SalaVerdeType.caption(
            color: active ? kToolAccent : SalaVerdeColors.textSecondary,
          ).copyWith(fontWeight: active ? FontWeight.w800 : FontWeight.w600),
        ),
      ),
    );
  }
}

/// Botón "Calcular" compartido (antes `_CalculateButton`, duplicado en
/// Equity y EV) — para los modos que no recalculan en vivo.
class ToolCalculateButton extends StatelessWidget {
  const ToolCalculateButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: loading ? () {} : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          color: kToolAccent.withValues(alpha: loading ? 0.4 : 1),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(SalaVerdeColors.background),
                ),
              )
            : Text(
                label,
                style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.background),
              ),
      ),
    );
  }
}

/// Pastilla de estado corta (p. ej. "+EV" / "Break-even" / "-EV") — un
/// solo lugar donde se pinta ese patrón, en vez de uno por pantalla.
class ToolStatusPill extends StatelessWidget {
  const ToolStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
      ),
      child: Text(
        label,
        style: SalaVerdeType.caption(color: color).copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Formatea un double sin decimales inútiles (`10` en vez de `10.0`, pero
/// `10.5` cuando hace falta) — mismo criterio en toda Tools.
String formatToolNumber(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

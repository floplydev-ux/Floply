import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';

/// Encabezado compartido por las pantallas de una herramienta puntual
/// (Pot Odds, EV, ...) — ícono + título + subtítulo + volver. Extraído
/// de `pot_odds_calculator_screen.dart` para no repetirlo en cada
/// calculadora nueva.
class ToolHeader extends StatelessWidget {
  const ToolHeader({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

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
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textSecondary, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.18),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta contenedora genérica (fondo + borde) para agrupar inputs o
/// una sección de resultado, con el mismo lenguaje visual que ya usa
/// `StatsScreen`.
class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.borderColor,
  });

  final Widget child;
  final List<Color>? gradientColors;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: gradientColors == null ? AppColors.surface : null,
        gradient: gradientColors == null
            ? null
            : LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(color: borderColor ?? AppColors.surfaceBorder),
      ),
      child: child,
    );
  }
}

/// Campo numérico con label + sufijo — mismo estilo para cualquier
/// input de cualquier calculadora.
class ToolNumberField extends StatelessWidget {
  const ToolNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffixText,
    this.accentColor = AppColors.diamondBlue,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? suffixText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo de texto libre con label + hint — para notación de cartas
/// (`AhKd`) u otro texto que no sea un número. Mismo lenguaje visual que
/// [ToolNumberField], sin forzar teclado numérico.
class ToolTextField extends StatelessWidget {
  const ToolTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.accentColor = AppColors.diamondBlue,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? hintText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          textCapitalization: TextCapitalization.none,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de error genérica (entrada inválida) — mismo estilo en toda
/// Tools.
class ToolErrorCard extends StatelessWidget {
  const ToolErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.danger.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.danger,
        ),
      ),
    );
  }
}

/// Un valor de resultado con su label — reutilizado por cualquier
/// calculadora (pot odds, EV, ...).
class ToolResultStat extends StatelessWidget {
  const ToolResultStat({
    super.key,
    required this.label,
    required this.value,
    this.big = false,
    this.color = AppColors.diamondBlue,
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 26 : 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Formatea un double sin decimales inútiles (`10` en vez de `10.0`,
/// pero `10.5` cuando hace falta) — mismo criterio en toda Tools.
String formatToolNumber(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

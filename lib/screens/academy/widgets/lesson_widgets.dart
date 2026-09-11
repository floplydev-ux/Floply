import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable_scale.dart';

/// Widgets compartidos por las vistas del recorrido de un lesson
/// (`theory_view` / `exercise_view` / `feedback_view` / `lesson_result_view`).
///
/// No son de uso general: viven acá para no duplicarlos entre las vistas
/// de fase y para que `lesson_flow.dart` quede como un router fino.

/// Encabezado del recorrido: botón volver + título + subtítulo de fase.
class LessonFlowHeader extends StatelessWidget {
  const LessonFlowHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.violetSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra de progreso "n / total" de los ítems de un lesson.
class LessonItemProgress extends StatelessWidget {
  const LessonItemProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: ratio.toDouble(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.violetBright,
                            AppColors.violetPrimary
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$current / $total',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Botón primario (violeta) del recorrido. `onTap` nulo lo deja deshabilitado.
class LessonPrimaryButton extends StatelessWidget {
  const LessonPrimaryButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: PressableScale(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: AppColors.violetGradient),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Controles de avance ATRÁS / [buttonLabel] de un recorrido paso a paso
/// (guion de mesa, fichas de teoría redactada, experiencia visual). Antes
/// vivía casi idéntico —y por duplicado, con parámetros muertos en algún
/// caso— en cada widget de fase; ahora es un único componente parametrizado
/// por texto, sin conocer si "el último paso" significa practicar, ver la
/// teoría u otra cosa.
class LessonNavControls extends StatelessWidget {
  const LessonNavControls({
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

  /// Texto opcional entre los dos botones (p. ej. "3 / 7"). `null` lo oculta.
  final String? counter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: canGoBack
              ? PressableScale(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: const Text(
                      AppStrings.academyBack,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        if (counter != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              counter!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: PressableScale(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: AppColors.violetGradient),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón secundario (fondo neutro) del recorrido.
class LessonSecondaryButton extends StatelessWidget {
  const LessonSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

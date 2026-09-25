import 'package:flutter/material.dart';

import '../engine/concepts/mastery_bucket.dart';
import '../theme/app_colors.dart';

/// Una fila de "dominio por concepto": nombre + barra + porcentaje.
///
/// Extraído de `laboratory/widgets/session_summary.dart` (donde vivía
/// como `_ConceptBar`, privado) para que la pantalla de Estadísticas
/// pueda mostrar el mismo dominio por concepto sin duplicar el widget —
/// ambas leen el mismo [MasteryBucket] que ya arma `masteryBuckets`.
class ConceptMasteryBar extends StatelessWidget {
  const ConceptMasteryBar({super.key, required this.bucket});

  final MasteryBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bucket.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${(bucket.mastery * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(color: AppColors.surfaceElevated),
                FractionallySizedBox(
                  widthFactor: bucket.mastery.clamp(0.0, 1.0),
                  child: Container(
                    color: bucket.mastery >= 0.8
                        ? AppColors.neonGreen
                        : bucket.mastery >= 0.5
                            ? AppColors.gold
                            : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

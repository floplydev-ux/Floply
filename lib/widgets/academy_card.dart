import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/user_progress.dart';
import '../theme/app_colors.dart';
import 'pressable_scale.dart';

/// Tarjeta de acceso principal a la Academia (acento violeta).
///
/// Es, junto con [LaboratoryCard], la sección más importante de la Home:
/// debe ser grande, llamativa y transmitir progreso. [onContinue] navega
/// a la pestaña Academia (hoy un placeholder, mañana la pantalla real).
class AcademyCard extends StatelessWidget {
  const AcademyCard({super.key, required this.progress, required this.onContinue});

  final UserProgress progress;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF241249), Color(0xFF120A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetPrimary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                _IconBadge(
                  icon: Icons.school_rounded,
                  color: AppColors.violetBright,
                ),
                SizedBox(width: 10),
                Text(
                  AppStrings.academyTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Text(
              AppStrings.academyDescription,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: _MountainPathIllustration(progress: progress.academyProgress),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            AppStrings.yourProgressLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            '${(progress.academyProgress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.violetSoft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.academyLevelOf(
                          progress.academyLevel,
                          progress.academyMaxLevel,
                        ),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 8,
                          child: Stack(
                            children: [
                              Container(color: AppColors.surfaceElevated),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress.academyProgress),
                                duration: const Duration(milliseconds: 1100),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppColors.violetGradient,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PressableScale(
                    onTap: onContinue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppColors.violetBright, AppColors.violetPrimary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violetPrimary.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        AppStrings.continueLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

/// Ilustración estilizada de una montaña con un camino que asciende hacia
/// una bandera, representando el avance del usuario dentro de la Academia.
class _MountainPathIllustration extends StatelessWidget {
  const _MountainPathIllustration({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MountainPathPainter(progress: progress),
      child: const SizedBox.expand(),
    );
  }
}

class _MountainPathPainter extends CustomPainter {
  _MountainPathPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Silueta de montaña.
    final mountainPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.violetDeep.withValues(alpha: 0.9),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final mountain = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.12, h * 0.55)
      ..lineTo(w * 0.32, h * 0.72)
      ..lineTo(w * 0.55, h * 0.18)
      ..lineTo(w * 0.78, h * 0.6)
      ..lineTo(w, h * 0.4)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mountain, mountainPaint);

    // Camino ascendente en zigzag, en violeta brillante.
    final pathPoints = [
      Offset(w * 0.10, h * 0.95),
      Offset(w * 0.30, h * 0.78),
      Offset(w * 0.20, h * 0.58),
      Offset(w * 0.42, h * 0.45),
      Offset(w * 0.34, h * 0.30),
      Offset(w * 0.55, h * 0.18),
    ];

    final trail = Path()..moveTo(pathPoints.first.dx, pathPoints.first.dy);
    for (final point in pathPoints.skip(1)) {
      trail.lineTo(point.dx, point.dy);
    }

    final glowPaint = Paint()
      ..color = AppColors.violetBright.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(trail, glowPaint);

    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trail, trailPaint);

    // Marcador de posición actual sobre el camino, según el progreso.
    final markerIndex = (pathPoints.length - 1) * progress;
    final maxSegment = pathPoints.length - 2;
    int segment = markerIndex.floor();
    if (segment < 0) segment = 0;
    if (segment > maxSegment) segment = maxSegment;
    final t = markerIndex - segment;
    final markerPos = Offset.lerp(pathPoints[segment], pathPoints[segment + 1], t)!;

    canvas.drawCircle(
      markerPos,
      7,
      Paint()..color = AppColors.violetBright.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(markerPos, 4.5, Paint()..color = Colors.white);

    // Bandera en la cima.
    final flagBase = pathPoints.last;
    final flagPolePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2;
    canvas.drawLine(
      flagBase,
      Offset(flagBase.dx, flagBase.dy - 22),
      flagPolePaint,
    );
    final flagPaint = Paint()..color = AppColors.gold;
    final flag = Path()
      ..moveTo(flagBase.dx, flagBase.dy - 22)
      ..lineTo(flagBase.dx + 16, flagBase.dy - 17)
      ..lineTo(flagBase.dx, flagBase.dy - 12)
      ..close();
    canvas.drawPath(flag, flagPaint);
  }

  @override
  bool shouldRepaint(covariant _MountainPathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

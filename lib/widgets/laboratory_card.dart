import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/user_progress.dart';
import '../theme/app_colors.dart';
import 'pressable_scale.dart';

/// Tarjeta de acceso principal al Laboratorio (acento verde neón).
///
/// [onPracticeNow] navega a la pestaña Laboratorio (hoy un placeholder,
/// mañana la pantalla real de ejercicios).
class LaboratoryCard extends StatelessWidget {
  const LaboratoryCard({super.key, required this.progress, required this.onPracticeNow});

  final UserProgress progress;
  final VoidCallback onPracticeNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2A20), Color(0xFF081712)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonGreen.withOpacity(0.18),
                  ),
                  child: const Icon(Icons.science_rounded, color: AppColors.neonGreenBright, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  AppStrings.laboratoryTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Text(
              AppStrings.laboratoryDescription,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: _PokerTableIllustration(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.lastSessionLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              progress.lastLabSessionName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${progress.lastLabSessionAccuracy}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neonGreenBright,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PressableScale(
                    onTap: onPracticeNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppColors.neonGreenBright, AppColors.neonGreen],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonGreen.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        AppStrings.practiceNowLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.6,
                          color: Colors.black,
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

/// Ilustración estilizada de una mesa de póker con fichas y dos cartas,
/// con un halo verde de fondo.
class _PokerTableIllustration extends StatelessWidget {
  const _PokerTableIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.neonGreen.withOpacity(0.28),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          bottom: 18,
          child: _ChipStack(colors: const [AppColors.neonGreenDeep, AppColors.neonGreen]),
        ),
        Positioned(
          right: 24,
          bottom: 18,
          child: _ChipStack(colors: const [AppColors.violetDeep, AppColors.violetBright]),
        ),
        Transform.rotate(
          angle: -0.18,
          child: const _PlayingCard(rank: 'A', suit: '♠'),
        ),
        Transform.translate(
          offset: const Offset(30, 6),
          child: Transform.rotate(
            angle: 0.16,
            child: const _PlayingCard(rank: 'K', suit: '♠'),
          ),
        ),
      ],
    );
  }
}

class _ChipStack extends StatelessWidget {
  const _ChipStack({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 44,
      child: Stack(
        children: List.generate(3, (i) {
          return Positioned(
            bottom: i * 7.0,
            child: Container(
              width: 30,
              height: 12,
              decoration: BoxDecoration(
                color: colors[i.isEven ? 0 : 1],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PlayingCard extends StatelessWidget {
  const _PlayingCard({required this.rank, required this.suit});

  final String rank;
  final String suit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 78,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rank,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.black87,
              height: 1,
            ),
          ),
          Text(
            suit,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.black87,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

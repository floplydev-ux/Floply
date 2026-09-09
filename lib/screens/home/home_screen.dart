import 'package:flutter/material.dart';

import '../../models/user_progress.dart';
import '../../theme/app_colors.dart';
import '../../widgets/academy_card.dart';
import '../../widgets/laboratory_card.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/stats_section.dart';
import '../../widgets/user_header.dart';
import '../../widgets/weekly_challenge_card.dart';

/// Pantalla principal (Home/Dashboard).
///
/// Compone todas las secciones de la Home a partir de un único
/// [UserProgress] mock, y agrega una aparición suave y escalonada de cada
/// sección al entrar a la pantalla. La navegación inferior vive en
/// [AppShell], no acá: esta pantalla solo recibe callbacks para pedir que
/// se cambie de pestaña cuando tocan "CONTINUAR" o "PRACTICAR AHORA".
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onGoToAcademy,
    required this.onGoToLaboratory,
  });

  final VoidCallback onGoToAcademy;
  final VoidCallback onGoToLaboratory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final UserProgress _progress;

  @override
  void initState() {
    super.initState();
    _progress = UserProgress.mock();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Devuelve [child] envuelto en una animación de aparición (fade + leve
  /// desplazamiento hacia arriba), con un retraso relativo definido por
  /// [start]/[end] dentro de la duración total de [_entranceController].
  Widget _reveal({required double start, required double end, required Widget child}) {
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        return Opacity(
          opacity: curved.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 480 ? 24.0 : 18.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _reveal(
                      start: 0.0,
                      end: 0.55,
                      child: UserHeader(progress: _progress),
                    ),
                    const SizedBox(height: 22),
                    _reveal(
                      start: 0.05,
                      end: 0.6,
                      child: ProgressStreakSection(progress: _progress),
                    ),
                    const SizedBox(height: 22),
                    _reveal(
                      start: 0.1,
                      end: 0.7,
                      child: LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final isWide = cardConstraints.maxWidth >= 560;
                          final academy = AcademyCard(
                            progress: _progress,
                            onContinue: widget.onGoToAcademy,
                          );
                          final lab = LaboratoryCard(
                            progress: _progress,
                            onPracticeNow: widget.onGoToLaboratory,
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: academy),
                                const SizedBox(width: 16),
                                Expanded(child: lab),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              academy,
                              const SizedBox(height: 16),
                              lab,
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    _reveal(
                      start: 0.2,
                      end: 0.8,
                      child: StatsSection(progress: _progress),
                    ),
                    const SizedBox(height: 22),
                    _reveal(
                      start: 0.3,
                      end: 0.9,
                      child: WeeklyChallengeCard(progress: _progress),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

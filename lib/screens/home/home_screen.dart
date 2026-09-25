import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../models/nav_destination.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../academy/academy_controller.dart';
import '../bankroll/bankroll_screen.dart';
import '../placeholder/coming_soon_screen.dart';
import '../tools/tools_screen.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/home_header.dart';
import 'widgets/practice_room_card.dart';
import 'widgets/sv_home_link_card.dart';

/// Pantalla principal (Home).
///
/// Es un compositor puro: no calcula progreso, no decide desbloqueos, no
/// sabe cómo se arma un stack de fichas. Todo eso vive donde ya vivía
/// (`AcademyController`/`AcademyEngine`, `BankrollScreen`, etc.) — acá solo
/// se arma el orden de las secciones y se cablean los CTAs a la navegación
/// real de [AppShell].
///
/// La Academia es el corazón del producto: [ContinueLearningCard] es lo
/// primero visible sin hacer scroll, y lee el mismo [AcademyController]
/// que usa la pantalla de Academia (compartido desde `AppShell`), así que
/// "Continuar" abre la lección real, no solo cambia de pestaña.
///
/// **Fase 2 — primera migración a "Sala Verde" en producción** (ver
/// `docs/design/FLOPLY_PHASE_2_HOME.md`). Mismo árbol de widgets, mismo
/// orden de secciones, mismos callbacks/navegación, misma animación de
/// entrada escalonada — solo cambia la capa visual:
/// - Fondo plano (`SalaVerdeColors.background`), no el degradé de dos
///   colores de antes (`FLOPLY_ANTI_GENERIC.md` regla 5: sin gradientes
///   decorativos sin función física).
/// - Bankroll/Tools/Coach migran de `HomeLinkCard` (compartido con
///   `ToolsScreen`, fuera de alcance) a [SvHomeLinkCard], scoped a Home.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.academyController,
    required this.onGoToAcademy,
    required this.onGoToLaboratory,
    required this.onGoToProfile,
  });

  final AcademyController academyController;
  final VoidCallback onGoToAcademy;
  final VoidCallback onGoToLaboratory;
  final VoidCallback onGoToProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// [child] envuelto en una aparición suave (fade + leve desplazamiento
  /// hacia arriba), escalonada según [start]/[end] dentro de la duración
  /// total de [_entranceController].
  Widget _reveal(
      {required double start, required double end, required Widget child}) {
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
            offset: Offset(0, (1 - curved.value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  void _openBankroll() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BankrollScreen()),
    );
  }

  void _openTools() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ToolsScreen()),
    );
  }

  void _openComingSoon(NavDestination destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ComingSoonScreen(destination: destination)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 480 ? 24.0 : 18.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 18, horizontalPadding, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _reveal(
                    start: 0.0,
                    end: 0.5,
                    child: HomeHeader(
                      name: AppUser.current.firstName,
                      photoUrl: AppUser.current.photoUrl,
                      onOpenProfile: widget.onGoToProfile,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _reveal(
                    start: 0.05,
                    end: 0.6,
                    child: ContinueLearningCard(
                      controller: widget.academyController,
                      onGoToAcademy: widget.onGoToAcademy,
                      onGoToPractice: widget.onGoToLaboratory,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _reveal(
                    start: 0.12,
                    end: 0.65,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Text(
                        AppStrings.homeMoreLabel,
                        style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary),
                      ),
                    ),
                  ),
                  _reveal(
                    start: 0.15,
                    end: 0.7,
                    child: PracticeRoomCard(
                        onPracticeNow: widget.onGoToLaboratory),
                  ),
                  const SizedBox(height: 24),
                  _reveal(
                    start: 0.2,
                    end: 0.8,
                    child: SvHomeLinkCard(
                      icon: Icons.savings_rounded,
                      title: AppStrings.bankrollTitle,
                      description: AppStrings.bankrollDescription,
                      accentColor: SalaVerdeColors.brass,
                      onTap: _openBankroll,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _reveal(
                    start: 0.25,
                    end: 0.85,
                    child: SvHomeLinkCard(
                      icon: kToolsDestination.icon,
                      title: AppStrings.toolsTitle,
                      description: AppStrings.toolsDescription,
                      accentColor: SalaVerdeColors.graphiteSteelBright,
                      onTap: _openTools,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _reveal(
                    start: 0.3,
                    end: 0.9,
                    child: SvHomeLinkCard(
                      icon: kCoachDestination.icon,
                      title: AppStrings.coachTitle,
                      description: AppStrings.coachDescription,
                      accentColor: SalaVerdeColors.textMuted,
                      onTap: () => _openComingSoon(kCoachDestination),
                      muted: true,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

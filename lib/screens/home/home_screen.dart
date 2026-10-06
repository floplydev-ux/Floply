import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../services/ads/admob_rewarded_ad_service.dart';
import '../../services/economy/economy_access_service.dart';
import '../../services/economy/floply_coins_service.dart';
import '../../services/economy/training_quota_service.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/user_avatar.dart';
import '../academy/academy_controller.dart';
import '../bankroll/bankroll_screen.dart';
import '../profile/settings_screen.dart';
import '../tools/tools_screen.dart';
import 'widgets/academy_lab_cards_row.dart';
import 'widgets/coin_info_sheet.dart';
import 'widgets/coin_usage_sheet.dart';
import 'widgets/home_coach_banner.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_tools_banner.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/sv_home_link_card.dart';

/// Pantalla principal (Home) — v3, composición sobre una escena de fondo
/// única con Academia + Campo de Entrenamiento uno al lado del otro.
///
/// Sigue siendo un compositor puro: no calcula progreso, no decide
/// desbloqueos — todo eso vive donde ya vivía ([AcademyController]/
/// `AcademyEngine`, `BankrollScreen`, etc.). Este archivo solo arma el
/// orden de las secciones y cablea los CTAs a la navegación real de
/// `AppShell`.
///
/// **Qué cambió respecto de la v2**: [HomeHero] usa el nuevo fondo general
/// de FLOPly (sin logo superior — la escena ya trae la identidad de marca)
/// con una transición más gradual a negro; Academia y Campo de
/// Entrenamiento siguen lado a lado en [AcademyLabCardsRow] (esa fila no
/// cambió); Herramientas pasa a ser un único bloque grande con foto real
/// de fondo ([HomeToolsBanner] — la vidriera de accesos individuales que
/// vivía debajo se eliminó, esa selección ya vive en `ToolsScreen`); Coach
/// pasa de link card chica a bloque grande con el mismo formato
/// ([HomeCoachBanner], sin foto todavía); el progreso ("TU PROGRESO") se
/// sacó del Home — la misma sección ([HomeProgressSection]) ahora vive en
/// `ProfileScreen`, sin duplicar lógica. La navegación inferior real
/// (`AppBottomNavigation`, en `AppShell`) no se toca — sigue siendo
/// Inicio/Academia/Campo de Entrenamiento/Estadísticas/Perfil.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.academyController,
    this.coins,
    this.training,
    this.economyAccess,
    this.premium,
    this.authController,
    required this.onGoToAcademy,
    required this.onGoToLaboratory,
    required this.onGoToProfile,
    required this.onGoToCoach,
  });

  final AcademyController academyController;

  /// Economía: instancia compartida creada por `AppShell`, o `null` para
  /// instancias propias (tests/call sites sin economía real).
  final FloplyCoinsService? coins;
  final TrainingQuotaService? training;
  final EconomyAccessService? economyAccess;

  /// Estado Premium real — `null` usa [StubPremiumService] (tests/standalone).
  final PremiumService? premium;

  /// Solo para abrir `SettingsScreen` desde `HomeTopBar`. `null` deja el
  /// botón sin acción (tests/call sites sin auth real).
  final AuthController? authController;

  final VoidCallback onGoToAcademy;
  final VoidCallback onGoToLaboratory;
  final VoidCallback onGoToProfile;
  final VoidCallback onGoToCoach;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeProfileHero extends StatelessWidget {
  const _HomeProfileHero({
    required this.controller,
    required this.onTap,
    required this.screenWidth,
    required this.leftPadding,
  });

  final AcademyController controller;
  final VoidCallback onTap;
  final double screenWidth;
  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    final user = AppUser.current;
    final isCompleted = controller.currentLessonView == null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 96,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(leftPadding, 0, 0, 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.58),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xCCD7B56D),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: UserAvatar(
                          displayName: user.displayName,
                          photoUrl: user.photoUrl,
                          size: 58,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.displayName.trim().isEmpty
                                  ? 'Jugador'
                                  : user.displayName
                                      .trim()
                                      .split(RegExp(r'\s+'))
                                      .first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: Color(0x88000000),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            if (!controller.loading && !isCompleted)
                              AnimatedBuilder(
                                animation: controller,
                                builder: (context, _) => Text(
                                  AppStrings.academyLevelOf(
                                    controller.snapshot.currentLevelNumber,
                                    13,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xCCD7B56D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!controller.loading && !isCompleted) ...[
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final pct = controller.snapshot.percent;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0x99000000),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: const Color(0x33D7B56D),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFFD7B56D),
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '${(pct * 100).round()}%',
                                style: const TextStyle(
                                  color: Color(0xCCD7B56D),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // HomeTopBar total height: vertical padding (8×2) + tallest module (48).
  static const double _kTopBarHeight = 64.0;

  late final AnimationController _entranceController;

  late final FloplyCoinsService _coins = widget.coins ?? FloplyCoinsService();
  late final TrainingQuotaService _training =
      widget.training ?? TrainingQuotaService();
  bool get _ownsEconomy => widget.coins == null;

  late final PremiumService _premiumService =
      widget.premium ?? StubPremiumService();

  late final EconomyAccessService _economyAccess = widget.economyAccess ??
      EconomyAccessService(
        coins: _coins,
        training: _training,
        premium: _premiumService,
        ads: AdMobRewardedAdService(coins: _coins),
      );

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    if (_coins.loading) _coins.load();
    if (_training.loading) _training.load();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    if (_ownsEconomy) {
      _coins.dispose();
      _training.dispose();
    }
    super.dispose();
  }

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

  Future<void> _openTools() async {
    final proceed = await CoinUsageSheet.maybeShow(
      context,
      CoinUsageContext.tools,
    );
    if (!proceed || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ToolsScreen(
          access: _economyAccess,
          coins: _coins,
        ),
      ),
    );
  }

  Future<void> _openLaboratory() async {
    final proceed = await CoinUsageSheet.maybeShow(
      context,
      CoinUsageContext.training,
    );
    if (!proceed || !mounted) return;
    widget.onGoToLaboratory();
  }

  void _openSettings() {
    final authController = widget.authController;
    if (authController == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(controller: authController)),
    );
  }

  void _openCoinInfo() {
    CoinInfoSheet.show(
      context,
      CoinInfoType.floplyCoins,
      access: _economyAccess,
    );
  }

  void _openTrainingInfo() {
    CoinInfoSheet.show(context, CoinInfoType.trainingQuota);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final topBarOffset = topPadding + _kTopBarHeight;
    const profileHeroHeight = 96.0;
    final horizontalPadding = screenWidth >= 480 ? 24.0 : 18.0;

    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: HomeHero()),
          // Banners scrollables — se desvanecen al cruzar la línea del perfil
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                final stickyBottom = topBarOffset + profileHeroHeight;
                final fadeStart = stickyBottom - 30.0;
                final fadeEnd = stickyBottom + 60.0;
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [
                    (fadeStart / bounds.height).clamp(0.0, 1.0),
                    (fadeEnd / bounds.height).clamp(0.0, 1.0),
                  ],
                  colors: const [Colors.transparent, Colors.white],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 28 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: topBarOffset + profileHeroHeight + 30),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          horizontalPadding, 0, horizontalPadding, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _reveal(
                            start: 0.08,
                            end: 0.6,
                            child: AcademyLabCardsRow(
                              controller: widget.academyController,
                              onGoToAcademy: widget.onGoToAcademy,
                              onGoToLaboratory: _openLaboratory,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _reveal(
                            start: 0.12,
                            end: 0.65,
                            child: HomeToolsBanner(onTap: _openTools),
                          ),
                          const SizedBox(height: 16),
                          _reveal(
                            start: 0.16,
                            end: 0.7,
                            child: HomeCoachBanner(onTap: widget.onGoToCoach),
                          ),
                          const SizedBox(height: 22),
                          _reveal(
                            start: 0.22,
                            end: 0.78,
                            child: SvHomeLinkCard(
                              icon: Icons.savings_rounded,
                              title: AppStrings.bankrollTitle,
                              description: AppStrings.bankrollDescription,
                              accentColor: SalaVerdeColors.brass,
                              onTap: _openBankroll,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Perfil fijo — no se desplaza con el scroll
          Positioned(
            top: topBarOffset,
            left: 0,
            right: 0,
            height: profileHeroHeight,
            child: _HomeProfileHero(
              controller: widget.academyController,
              onTap: widget.onGoToProfile,
              screenWidth: screenWidth,
              leftPadding: horizontalPadding,
            ),
          ),
          // Top bar fija
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: HomeTopBar(
                coins: _coins,
                training: _training,
                onOpenSettings: _openSettings,
                onTapCoins: _openCoinInfo,
                onTapTraining: _openTrainingInfo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

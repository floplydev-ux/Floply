import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../engine/academy/academy_store.dart';
import '../../engine/coach/hand_table_controller.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_prefs.dart';
import '../../models/nav_destination.dart';
import '../../services/ads/admob_rewarded_ad_service.dart';
import '../../services/economy/economy_access_service.dart';
import '../../services/economy/floply_coins_service.dart';
import '../../services/economy/training_quota_service.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/bottom_navigation.dart';
import '../academy/academy_controller.dart';
import '../academy/academy_screen.dart';
import '../coach/coach_table_screen.dart';
import '../home/home_screen.dart';
import '../premium/widgets/premium_gate.dart';
import '../home/widgets/coin_usage_sheet.dart';
import '../laboratory/laboratory_screen.dart';
import '../profile/profile_screen.dart';

/// Índices de las 5 pestañas, en el mismo orden que [kNavDestinations].
const int kTabHome = 0;
const int kTabAcademy = 1;
const int kTabLaboratory = 2;
const int kTabCoach = 3;
const int kTabProfile = 4;

/// Contenedor raíz de la navegación por pestañas.
///
/// Mantiene qué pestaña está activa y arma la [AppBottomNavigation] junto
/// con el contenido correspondiente. Usa [IndexedStack] para que cada
/// pestaña conserve su estado (scroll, animaciones, etc.) al cambiar entre
/// ellas.
///
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.academyStore,
    required this.authController,
    required this.premium,
  });

  /// El `AcademyStore` que corresponde al estado de sesión actual — local
  /// puro en invitado, sincronizado con la nube autenticado. Lo decide
  /// `AuthGate`, antes de construir este widget; `AppShell` (y todo lo de
  /// adentro) nunca sabe cuál de los dos es.
  final AcademyStore academyStore;

  /// Para el tab Perfil (`ProfileScreen`) — `AppShell` no conoce Firebase
  /// ni ningún detalle de autenticación, solo reenvía el controller.
  final AuthController authController;

  /// Estado Premium real — creado UNA SOLA VEZ en `_PokerTrainerAppState`
  /// y pasado acá por constructor para sobrevivir las recreaciones de
  /// `AppShell` que ocurren en cada transición de auth.
  final PremiumService premium;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = kTabHome;

  /// Compartido con [AcademyScreen]: así "Continuar" en Home abre la
  /// lección real (`openLesson`) y, al cambiar de pestaña, la Academia ya
  /// aparece ahí en vez de en el mapa.
  late final AcademyController _academyController =
      AcademyController(store: widget.academyStore);

  /// Economía (integración con el producto real) — única instancia
  /// compartida para toda la app, mismo patrón que [_academyController]:
  /// se crea una sola vez acá y se reenvía por constructor a cada
  /// pestaña/pantalla que la necesite (Home, Laboratorio, Perfil, y de
  /// ahí a Tools/Coach al navegar) — ninguna pantalla crea la suya.
  late final FloplyCoinsService _coins = FloplyCoinsService();
  late final TrainingQuotaService _training = TrainingQuotaService();
  late final EconomyAccessService _economyAccess = EconomyAccessService(
    coins: _coins,
    training: _training,
    premium: widget.premium,
    ads: AdMobRewardedAdService(coins: _coins),
  );

  /// Sesión de Coach — persiste entre visitas para ofrecer "Continuar".
  /// Se dispone junto con AppShell al hacer logout/reinicio.
  HandTableController? _coachController;

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  /// Abre Coach como ruta pusheada — nunca como un tab directo del
  /// IndexedStack, para que el back button de [CoachTableScreen] siempre
  /// pueda hacer Navigator.pop() sin colapsar el AppShell.
  ///
  /// La verificación Premium ocurre ANTES de inicializar cualquier parte
  /// del motor (HandTableController, bots, sesión, flag en disco) —
  /// usuarios FREE solo ven la pantalla de bloqueo de PremiumGate.
  Future<void> _openCoach() async {
    // Guard Premium: si no es Premium, navegar directo al bloqueo sin
    // crear HandTableController ni marcar ninguna sesión activa.
    // (isPremium == false mientras RC todavía carga — PremiumGate maneja
    // el estado de carga con su spinner propio.)
    if (!widget.premium.isPremium) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PremiumGate(
            premium: widget.premium,
            builder: (_) => const CoachTableScreen(),
          ),
        ),
      );
      return;
    }

    // Confirmado Premium — gestión de sesión anterior.
    final hadSessionOnDisk = await AppPrefs.coachSessionActive;
    if (!mounted) return;

    final hasPreviousSession = _coachController != null || hadSessionOnDisk;
    if (hasPreviousSession) {
      final proceed = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: SalaVerdeColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
          ),
          title: Text(
            AppStrings.coachSessionTitle,
            style: SalaVerdeType.bodyStrong(),
          ),
          content: Text(
            AppStrings.coachSessionBody,
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('new'),
              child: Text(
                AppStrings.coachSessionNew,
                style: SalaVerdeType.label(color: SalaVerdeColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('continue'),
              child: Text(
                AppStrings.coachSessionContinue,
                style:
                    SalaVerdeType.label(color: SalaVerdeColors.violetBright),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (proceed == null) return;
      if (proceed == 'new') {
        _coachController?.dispose();
        _coachController = null;
        await AppPrefs.setCoachSessionActive(value: false);
      }
    }

    _coachController ??= HandTableController();
    await AppPrefs.setCoachSessionActive(value: true);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PremiumGate(
          premium: widget.premium,
          builder: (_) => CoachTableScreen(controller: _coachController),
        ),
      ),
    );
  }

  /// Tab ENTRENAMIENTO del navbar — muestra el sheet de coins antes de
  /// entrar, igual que el banner del Home. Si el usuario ya marcó
  /// "no volver a mostrar", entra directo.
  Future<void> _openLaboratory() async {
    final proceed = await CoinUsageSheet.maybeShow(
      context,
      CoinUsageContext.training,
    );
    if (!proceed || !mounted) return;
    _goToTab(kTabLaboratory);
  }

  /// "Repasá en Academia" (Laboratorio) — mismo mecanismo real que ya usa
  /// "Continuar" en Home (`AcademyLabCardsRow._continueAcademy`): abrir la
  /// lección puntual en el `AcademyController` compartido y cambiar de
  /// pestaña. Sin esto, Laboratorio no tenía ninguna forma de cruzar a
  /// Academia — el enlace mínimo necesario que pide el pedido, nada de una
  /// navegación cruzada nueva.
  void _reviewInAcademy(String lessonId) {
    _academyController.openLesson(lessonId);
    _goToTab(kTabAcademy);
  }

  @override
  void initState() {
    super.initState();
    // Igual criterio que `AcademyScreen`/`LaboratoryScreen` (ver su
    // `initState`): hidrata una sola vez, acá, no en cada pantalla que
    // las use — las 3 llegan ya con la carga en marcha a Home/
    // Laboratorio/Perfil.
    if (_coins.loading) _coins.load();
    if (_training.loading) _training.load();
    // Precarga el Rewarded Ad de entrada (modo prueba, ver `AdConfig`) —
    // así, si el usuario llega a necesitar "Ver anuncio" ya hay uno
    // listo en vez de esperar la carga recién en ese momento.
    _economyAccess.ads.preload();
  }

  @override
  void dispose() {
    _academyController.dispose();
    _coins.dispose();
    _training.dispose();
    _coachController?.dispose();
    super.dispose();
  }

  /// Maneja el tap del bottom nav: el tab Coach (kTabCoach=3) abre Coach
  /// como ruta pusheada en vez de cambiar el IndexedStack, así el back
  /// button de CoachTableScreen puede hacer Navigator.pop() sin problema.
  void _onNavTap(int index) {
    if (index == kTabCoach) {
      _openCoach();
      return;
    }
    if (index == kTabLaboratory) {
      _openLaboratory();
      return;
    }
    _goToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        academyController: _academyController,
        coins: _coins,
        training: _training,
        economyAccess: _economyAccess,
        authController: widget.authController,
        premium: widget.premium,
        onGoToAcademy: () => _goToTab(kTabAcademy),
        onGoToLaboratory: () => _goToTab(kTabLaboratory),
        onGoToProfile: () => _goToTab(kTabProfile),
        onGoToCoach: _openCoach,
      ),
      AcademyScreen(controller: _academyController, premium: widget.premium),
      LaboratoryScreen(
        onReviewInAcademy: _reviewInAcademy,
        coins: _coins,
        training: _training,
        economyAccess: _economyAccess,
      ),
      // Coach no vive en el IndexedStack — se abre siempre como ruta
      // pusheada desde _openCoach(). Este slot vacío mantiene el índice
      // kTabCoach=3 sin renderizar nada si alguien llega acá por error.
      const SizedBox.shrink(),
      ProfileScreen(
        authController: widget.authController,
        academyController: _academyController,
        premium: widget.premium,
        onGoToAcademy: () => _goToTab(kTabAcademy),
        onGoToLaboratory: () => _goToTab(kTabLaboratory),
      ),
    ];

    return Scaffold(
      // `extendBody`: la navbar ahora es transparente de verdad
      // (`AppBottomNavigation`) — sin esto, el `body` se recortaría justo
      // arriba de ella y nunca habría nada real detrás que mostrar.
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

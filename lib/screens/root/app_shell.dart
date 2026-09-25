import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/widgets/account_screen.dart';
import '../../engine/academy/academy_store.dart';
import '../../models/nav_destination.dart';
import '../../widgets/bottom_navigation.dart';
import '../academy/academy_controller.dart';
import '../academy/academy_screen.dart';
import '../home/home_screen.dart';
import '../laboratory/laboratory_screen.dart';
import '../stats/stats_screen.dart';

/// Índices de las 5 pestañas, en el mismo orden que [kNavDestinations].
const int kTabHome = 0;
const int kTabAcademy = 1;
const int kTabLaboratory = 2;
const int kTabStats = 3;
const int kTabProfile = 4;

/// Contenedor raíz de la navegación por pestañas.
///
/// Mantiene qué pestaña está activa y arma la [AppBottomNavigation] junto
/// con el contenido correspondiente. Usa [IndexedStack] para que cada
/// pestaña conserve su estado (scroll, animaciones, etc.) al cambiar entre
/// ellas. El día que Academia/Laboratorio/Estadísticas/Perfil tengan
/// implementación real, alcanza con reemplazar el [ComingSoonScreen]
/// correspondiente en [_screens] por la pantalla definitiva.
///
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.academyStore,
    required this.authController,
  });

  /// El `AcademyStore` que corresponde al estado de sesión actual — local
  /// puro en invitado, sincronizado con la nube autenticado. Lo decide
  /// `AuthGate`, antes de construir este widget; `AppShell` (y todo lo de
  /// adentro) nunca sabe cuál de los dos es.
  final AcademyStore academyStore;

  /// Para el tab Perfil (`AccountScreen`) — `AppShell` no conoce Firebase
  /// ni ningún detalle de autenticación, solo reenvía el controller.
  final AuthController authController;

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

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    _academyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        academyController: _academyController,
        onGoToAcademy: () => _goToTab(kTabAcademy),
        onGoToLaboratory: () => _goToTab(kTabLaboratory),
        onGoToProfile: () => _goToTab(kTabProfile),
      ),
      AcademyScreen(controller: _academyController),
      const LaboratoryScreen(),
      StatsScreen(controller: _academyController),
      AccountScreen(controller: widget.authController),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/nav_destination.dart';
import '../../widgets/bottom_navigation.dart';
import '../academy/academy_screen.dart';
import '../home/home_screen.dart';
import '../laboratory/laboratory_screen.dart';
import '../placeholder/coming_soon_screen.dart';

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
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = kTabHome;

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onGoToAcademy: () => _goToTab(kTabAcademy),
        onGoToLaboratory: () => _goToTab(kTabLaboratory),
      ),
      const AcademyScreen(),
      const LaboratoryScreen(),
      ComingSoonScreen(destination: kNavDestinations[kTabStats]),
      ComingSoonScreen(destination: kNavDestinations[kTabProfile]),
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

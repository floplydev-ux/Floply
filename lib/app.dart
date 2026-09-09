import 'package:flutter/material.dart';

import 'screens/root/app_shell.dart';
import 'theme/app_theme.dart';

/// Widget raíz de la aplicación.
///
/// Por ahora solo registra el tema oscuro y apunta directamente a
/// [AppShell] (Home + navegación inferior). Cuando se agregue
/// autenticación, este widget pasará a decidir entre una pantalla de
/// login y [AppShell] según el estado de sesión.
class PokerTrainerApp extends StatelessWidget {
  const PokerTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AppShell(),
    );
  }
}

import 'package:flutter/material.dart';

import '../../screens/root/app_shell.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sala_verde/floply_loading_indicator.dart';
import '../auth_controller.dart';
import '../models/auth_state.dart';
import 'auth_screen.dart';

/// El único widget de toda la app que ramifica sobre el estado global de
/// sesión (Fase 25). Envuelve a `AppShell` — nada de Academia, Bankroll,
/// Home, Practice Room, Tools o Coach sabe que esto existe.
///
///  - [AuthLoading] → splash, nunca la pantalla de login (evita el flash
///    de la Fase 10).
///  - [AuthUnauthenticated] → [AuthScreen].
///  - [AuthGuest] / [AuthAuthenticated] → `AppShell`, con el
///    `AcademyStore` que corresponda (local puro o sincronizado).
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.controller,
    required this.premium,
  });

  final AuthController controller;
  final PremiumService premium;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    widget.controller.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return switch (state) {
          AuthLoading() => const _SplashView(),
          // AuthGuest es un estado legado que no debería ocurrir con el nuevo
          // sistema de cuentas obligatorio — se trata como no autenticado.
          AuthUnauthenticated() ||
          AuthGuest() =>
            AuthScreen(controller: widget.controller),
          AuthAuthenticated(:final user) => AppShell(
              key: ValueKey('auth-${user.id}'),
              academyStore: widget.controller.academyStore,
              authController: widget.controller,
              premium: widget.premium,
            ),
        };
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(child: FloplyLoadingIndicator(size: 72)),
    );
  }
}

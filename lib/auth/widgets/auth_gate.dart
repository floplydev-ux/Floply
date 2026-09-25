import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../screens/root/app_shell.dart';
import '../../theme/app_colors.dart';
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
  const AuthGate({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncAppUser);
    widget.controller.bootstrap();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncAppUser);
    super.dispose();
  }

  /// Home y la mesa de Academia leen [AppUser.current] sin saber que
  /// Firebase existe (ver sus propios comentarios) — este es el único
  /// puente entre la sesión real y ese dato, exactamente donde
  /// `AppUser` ya invitaba a conectarlo. Vive en un listener, no en
  /// `build()`, para no mutar estado global durante el render.
  void _syncAppUser() {
    final state = widget.controller.state;
    if (state is AuthAuthenticated) {
      AppUser.current = AppUser(
        displayName: state.user.displayName,
        photoUrl: state.user.avatarUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return switch (state) {
          AuthLoading() => const _SplashView(),
          AuthUnauthenticated() => AuthScreen(controller: widget.controller),
          AuthGuest() => AppShell(
              key: const ValueKey('guest'),
              academyStore: widget.controller.academyStore,
              authController: widget.controller,
            ),
          AuthAuthenticated(:final user) => AppShell(
              key: ValueKey('auth-${user.id}'),
              academyStore: widget.controller.academyStore,
              authController: widget.controller,
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
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.violetSoft,
          ),
        ),
      ),
    );
  }
}

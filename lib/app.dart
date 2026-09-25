import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/firebase_auth_repository.dart';
import 'auth/widgets/auth_gate.dart';
import 'theme/app_theme.dart';

/// Web client ID (tipo OAuth "Web", `client_type: 3` en
/// `android/app/google-services.json`) del proyecto Firebase floply-e5b45
/// — google_sign_in lo necesita para pedirle a Google un idToken válido,
/// incluso en Android. No es secreto (viaja igual dentro de
/// google-services.json), así que vive acá como constante simple.
const _googleServerClientId =
    '699061332318-jel5uupll4s9931vedqos6qepn3g8v42.apps.googleusercontent.com';

/// Widget raíz de la aplicación.
///
/// Registra el tema oscuro y decide, vía [AuthGate], entre la pantalla de
/// acceso y [AppShell] (Home + navegación inferior) según el estado de
/// sesión — la única capa nueva sobre lo que ya existía.
class PokerTrainerApp extends StatefulWidget {
  const PokerTrainerApp({super.key});

  @override
  State<PokerTrainerApp> createState() => _PokerTrainerAppState();
}

class _PokerTrainerAppState extends State<PokerTrainerApp> {
  late final AuthController _authController = AuthController(
    authRepository: FirebaseAuthRepository(
      googleServerClientId: _googleServerClientId,
    ),
  );

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: AuthGate(controller: _authController),
    );
  }
}

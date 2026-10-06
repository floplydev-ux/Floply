import 'dart:async';

import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/firebase_auth_repository.dart';
import 'auth/widgets/auth_gate.dart';
import 'screens/root/startup_connectivity_gate.dart';
import 'services/connectivity_service.dart';
import 'services/premium/premium_service.dart';
import 'services/premium/promo_aware_premium_service.dart';
import 'services/premium/revenue_cat_premium_service.dart';
import 'services/premium/reviewer_claims_service.dart';
import 'services/promo/promo_code_service.dart';
import 'theme/app_theme.dart';
import 'widgets/offline_banner.dart';

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
  final ConnectivityService _connectivity = ConnectivityService();

  // Servicios de Premium — cuatro capas, todas owned aquí y dispuestas en
  // dispose():
  //  · RevenueCatPremiumService: suscripciones reales vía RC.
  //  · FirebasePromoCodeService: códigos promocionales vía Firestore.
  //  · ReviewerClaimsService: Firebase Custom Claim `reviewerPremium:true`
  //    — exclusivo para la cuenta de Google Play Reviewer, asignado vía
  //    Admin SDK (el cliente nunca puede establecerlo).
  //  · PromoAwarePremiumService: combina los tres en una única fuente de
  //    verdad que la UI escucha.
  final RevenueCatPremiumService _rcPremium = RevenueCatPremiumService();
  final FirebasePromoCodeService _promo = FirebasePromoCodeService();

  // El repositorio se extrae como variable nombrada para pasarlo tanto a
  // AuthController como a ReviewerClaimsService.
  final FirebaseAuthRepository _authRepository = FirebaseAuthRepository(
    googleServerClientId: _googleServerClientId,
  );

  late final ReviewerClaimsService _reviewer =
      ReviewerClaimsService(_authRepository);

  late final PremiumService _premium = PromoAwarePremiumService(
    base: _rcPremium,
    promo: _promo,
    reviewer: _reviewer,
  );

  late final AuthController _authController = AuthController(
    authRepository: _authRepository,
    connectivity: _connectivity,
  );

  @override
  void initState() {
    super.initState();
    // Inicializa el SDK de RevenueCat una sola vez — fire-and-forget: el
    // estado de entitlement se actualiza a través del listener de RC, así
    // que no hay que esperar acá.
    unawaited(_rcPremium.initialize());
    // Sincroniza RC, promos y reviewer claims con Firebase Auth cada vez
    // que cambia el estado de sesión (login/logout).
    _authController.addListener(_onAuthStateChanged);
  }

  /// Sincroniza RevenueCat, el servicio de promos y el reviewer claim con
  /// el UID de Firebase. Llamado cada vez que AuthController notifica un
  /// cambio de estado.
  void _onAuthStateChanged() {
    final uid = _authController.currentUser?.id;
    unawaited(_rcPremium.onUserChanged(uid));
    _promo.onUserChanged(uid);
    unawaited(_reviewer.onUserChanged(uid));
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    // PromoAwarePremiumService: desregistra sus propios listeners internos.
    // _rcPremium, _promo y _reviewer NO son dispuestos por
    // PromoAwarePremiumService — los owned acá los disponemos explícitamente.
    _premium.dispose();
    _rcPremium.dispose();
    _promo.dispose();
    _reviewer.dispose();
    _authController.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floply',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: OfflineBannerOverlay(
        connectivity: _connectivity,
        child: StartupConnectivityGate(
          connectivity: _connectivity,
          child: AuthGate(
            controller: _authController,
            premium: _premium,
          ),
        ),
      ),
    );
  }
}

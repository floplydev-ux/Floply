import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/ads/admob_bootstrap.dart';

Future<void> main() async {
  // PoC Marionette MCP (infraestructura, no producto): binding especial
  // SOLO en debug, para que un agente pueda inspeccionar/tocar la app en
  // ejecución vía MCP. En release corre exactamente como antes — la regla
  // de "single binding" de Marionette exige elegir uno de los dos, nunca
  // ambos.
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check: Play Integrity en producción, Debug provider en desarrollo.
  // El debug token se imprime en la consola la primera vez — registrarlo en
  // Firebase Console > App Check > Apps > FLOPly Android > Debug tokens.
  // En release, Play Integrity no requiere ninguna clave en código: Firebase
  // lo valida directamente a través de Google Play.
  const androidAppCheckProvider =
      kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
  // ignore: deprecated_member_use
  await FirebaseAppCheck.instance.activate(androidProvider: androidAppCheckProvider);

  // FLOPly Coins (Fase 1, ver `services/ads/`): una sola vez, antes de que
  // cualquier `RewardedAdService` intente cargar un anuncio. No-op en Web.
  await initializeMobileAdsSdk();
  runApp(const PokerTrainerApp());
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';

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
  runApp(const PokerTrainerApp());
}

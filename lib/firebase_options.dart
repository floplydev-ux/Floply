// coverage:ignore-file
// Generado por `flutterfire configure` contra el proyecto real
// floply-e5b45 (ver AUTH_SETUP.md). Regenerar con el mismo comando si se
// agregan apps o se rota el proyecto.
//
// Las apiKey de Firebase no son secretas en el sentido estricto (están
// pensadas para ir en el cliente y se protegen con las reglas de
// seguridad de Firestore/App Check, no ocultándolas), pero igual conviene
// no versionar esto si el repo es público, para no revelar de más la
// configuración del proyecto (ver AUTH_SETUP.md, sección "qué no sube a
// Git").

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Config de Firebase por plataforma, del proyecto real floply-e5b45.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma. '
          'Corré `flutterfire configure` para agregarla.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNTHXnB6hbQckyZE7KlU37YW0Eq9EuFBo',
    appId: '1:699061332318:web:5994d191df38d18351c7cf',
    messagingSenderId: '699061332318',
    projectId: 'floply-e5b45',
    authDomain: 'floply-e5b45.firebaseapp.com',
    storageBucket: 'floply-e5b45.firebasestorage.app',
    measurementId: 'G-8VTLFEFYWS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnoA8tGA83-UoGzPQ4Wyur9_gG3FRSXhI',
    appId: '1:699061332318:android:363d7a9917848fae51c7cf',
    messagingSenderId: '699061332318',
    projectId: 'floply-e5b45',
    storageBucket: 'floply-e5b45.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxIECzabkkOtdlo12Rg59jTTI8shbi-Bc',
    appId: '1:699061332318:ios:6bff9a39d88ec4db51c7cf',
    messagingSenderId: '699061332318',
    projectId: 'floply-e5b45',
    storageBucket: 'floply-e5b45.firebasestorage.app',
    iosClientId: '699061332318-t88mpdho4u9k6kf5kut3502tjgi88jck.apps.googleusercontent.com',
    iosBundleId: 'com.floply.app',
  );
}

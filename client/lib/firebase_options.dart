import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'FirebaseOptions no configurado para esta plataforma',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDny_6i0YW_KtkkdZs9N_U-HK3v_gYiY4k',
    authDomain: 'estrategia-ad734.firebaseapp.com',
    projectId: 'estrategia-ad734',
    storageBucket: 'estrategia-ad734.firebasestorage.app',
    messagingSenderId: '272357526071',
    appId: '1:272357526071:web:eb9de60fa271f4e4744db2',
    measurementId: '', // Puedes agregarlo si lo tenés
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDny_6i0YW_KtkkdZs9N_U-HK3v_gYiY4k',
    appId: '1:272357526071:web:eb9de60fa271f4e4744db2',
    messagingSenderId: '272357526071',
    projectId: 'estrategia-ad734',
    storageBucket: 'estrategia-ad734.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDny_6i0YW_KtkkdZs9N_U-HK3v_gYiY4k',
    appId: '1:272357526071:web:eb9de60fa271f4e4744db2',
    messagingSenderId: '272357526071',
    projectId: 'estrategia-ad734',
    storageBucket: 'estrategia-ad734.firebasestorage.app',
    iosBundleId: 'com.tuempresa.estrategia', // ✅ reemplazalo por el real si tenés iOS
  );

  static const FirebaseOptions macos = ios; // Usa el mismo que iOS por ahora
}

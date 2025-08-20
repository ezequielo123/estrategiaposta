// lib/config.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;

const String kProdServer = 'https://estrategiaposta.onrender.com';

String get socketServerUrl {
  // En WEB:
  if (kIsWeb) {
    // En release (Netlify) usa el servidor público; en debug, localhost
    return kReleaseMode ? kProdServer : 'http://localhost:3000';
  }

  // En Android emulador durante debug, usa 10.0.2.2; en release, servidor público
  if (defaultTargetPlatform == TargetPlatform.android) {
    return kReleaseMode ? kProdServer : 'http://10.0.2.2:3000';
  }

  // iOS sim / desktop: debug -> localhost, release -> servidor público
  return kReleaseMode ? kProdServer : 'http://localhost:3000';
}

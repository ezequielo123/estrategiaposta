// lib/config.dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

const String kProdServer = 'https://estrategiaposta.onrender.com';

String get socketServerUrl {
  // while debugging the local server:
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000'; // Android emulator
  return 'http://localhost:3000'; // iOS sim / desktop
}

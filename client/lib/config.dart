// // lib/config.dart
// import 'package:flutter/foundation.dart'
//     show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;

// const String kProdServer = 'https://estrategiaposta.onrender.com';

// String get socketServerUrl {
//   // En WEB:
//   if (kIsWeb) {
//     // En release (Netlify) usa el servidor público; en debug, localhost
//     return kReleaseMode ? kProdServer : 'http://localhost:3000';
//   }

//   // En Android emulador durante debug, usa 10.0.2.2; en release, servidor público
//   if (defaultTargetPlatform == TargetPlatform.android) {
//     return kReleaseMode ? kProdServer : 'http://10.0.2.2:3000';
//   }

//   // iOS sim / desktop: debug -> localhost, release -> servidor público
//   return kReleaseMode ? kProdServer : 'http://localhost:3000';
// }
// lib/config.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, kDebugMode, defaultTargetPlatform, TargetPlatform, debugPrint;

/// 🔒 PRODUCCIÓN (Render)
const String kProdServer = 'https://estrategiaposta.onrender.com';

/// 🧪 Opcional: forzar PROD también en debug (útil si no levantás server local)
const bool kUseProdInDebug = false;

/// 🌐 Overrides por línea de comando (prioridad más alta):
///   flutter run --dart-define=SOCKET_SERVER=https://mi-servidor.com
///   flutter run --dart-define=LAN_SERVER=http://192.168.1.23:3000
const String _kSocketOverride =
    String.fromEnvironment('SOCKET_SERVER', defaultValue: '');
const String _kLanServer =
    String.fromEnvironment('LAN_SERVER', defaultValue: '');

/// 🔧 Defaults cómodos para desarrollo local
const String _kLocalhost = 'http://localhost:3000';
const String _kAndroidEmu = 'http://10.0.2.2:3000'; // Android emulator
const String _kIosSim    = 'http://localhost:3000'; // iOS simulator / macOS

/// URL final para Socket.IO
String get socketServerUrl {
  // 1) Override explícito por --dart-define
  if (_kSocketOverride.isNotEmpty) {
    _logChosen('override', _kSocketOverride);
    return _kSocketOverride;
  }

  // 2) Release o debug forzado a prod
  if (kReleaseMode || (kDebugMode && kUseProdInDebug)) {
    _logChosen(kReleaseMode ? 'release' : 'debug->prod', kProdServer);
    return kProdServer;
  }

  // 3) LAN manual en debug (p.ej. dispositivo físico)
  if (_kLanServer.isNotEmpty && !kIsWeb) {
    _logChosen('lan', _kLanServer);
    return _kLanServer;
  }

  // 4) Plataformas en desarrollo
  if (kIsWeb) {
    // En web debug, suele correr en http://localhost:<port>, así que OK usar http.
    _logChosen('web-debug', _kLocalhost);
    return _kLocalhost;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      _logChosen('android-emulator', _kAndroidEmu);
      return _kAndroidEmu;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      _logChosen('apple-sim/desktop', _kIosSim);
      return _kIosSim;
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      _logChosen('desktop', _kLocalhost);
      return _kLocalhost;
    default:
      _logChosen('fallback', _kLocalhost);
      return _kLocalhost;
  }
}

/// (Opcional) Configs recomendadas para socket_io_client
Map<String, dynamic> socketOptions({
  String path = '/socket.io/',
  Map<String, String>? extraHeaders,
}) {
  return <String, dynamic>{
    'transports': ['websocket'], // evita long-polling y problemas de CORS/proxy
    'autoConnect': true,
    'reconnection': true,
    'reconnectionAttempts': 10,
    'reconnectionDelay': 1000,
    'timeout': 20000,
    'path': path,
    if (extraHeaders != null) 'extraHeaders': extraHeaders,
  };
}

/// Log chiquito para saber qué URL quedó elegida en runtime
void _logChosen(String reason, String url) {
  // Solo loguea en debug para no ensuciar release
  if (kDebugMode) debugPrint('🔌 socketServerUrl[$reason] => $url');
}

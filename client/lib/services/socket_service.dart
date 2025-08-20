// lib/services/socket_service.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';

import '../config.dart'; // Debe exponer socketServerUrl

class SocketService {
  // -------- Singleton --------
  static final SocketService _inst = SocketService._internal();
  factory SocketService() => _inst;
  SocketService._internal();

  IO.Socket? _socket;
  bool _created = false;

  BuildContext? _ctx;
  void registerContext(BuildContext ctx) => _ctx = ctx;

  /// Devuelve el socket (crea si hace falta).
  IO.Socket getSocket() {
    if (_socket == null) _createSocket();
    return _socket!;
  }

  void _createSocket() {
    if (_created) return;

    // En Web permitimos polling como fallback (evita cortes por proxies)
    final transports = kIsWeb ? ['websocket', 'polling'] : ['websocket'];

    _socket = IO.io(
      socketServerUrl,
      IO.OptionBuilder()
          .setTransports(transports)
          .setPath('/socket.io')   // explícito
          .disableAutoConnect()    // conectamos luego de registrar listeners
          .enableReconnection()
          .setReconnectionDelay(800)
          .setReconnectionAttempts(20)
          // NO usar forceNew: genera managers duplicados y desconexiones raras
          .build(),
    );

    // ---- logs básicos / diagnóstico ----
    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected: ${_socket!.id}');
      _setAppSocketId(); // ⬅️ guarda el id en AppState
    });
    // algunos gateways emiten 'connect' además de onConnect
    _socket!.on('connect', (_) => _setAppSocketId());
    // actualiza id en reconexiones
    _socket!.on('reconnect', (_) => _setAppSocketId());

    _socket!.onDisconnect((reason) {
      debugPrint('❌ [Socket] Desconectado: $reason');
    });
    _socket!.onConnectError((e) {
      debugPrint('[Socket] connect_error: $e');
      _snack('Error de conexión');
    });
    _socket!.onError((e) {
      debugPrint('[Socket] error: $e');
    });

    // Errores de dominio (server -> cliente)
    _socket!.on('error_sala', (data) => _snack('Sala: ${data ?? ''}'));
    _socket!.on('error_prediccion', (data) => _snack('Predicción: ${data ?? ''}'));
    _socket!.on('error_jugada', (data) => _snack('Jugada: ${data ?? ''}'));

    _created = true;

    // Conectar al final (listeners ya montados)
    if (!(_socket!.connected)) {
      _socket!.connect();
    }
  }

  // -------- helpers genéricos --------
  void on(String event, void Function(dynamic) handler) => getSocket().on(event, handler);
  void off(String event) => getSocket().off(event);
  void emit(String event, [dynamic data]) => getSocket().emit(event, data);

  // -------- API esperada por tus pantallas (posicionales) --------

  // crearSala(nombre, maxJugadores, onCreada(Map), [onEstadoJugadores(List)])
  void crearSala(
    String nombre,
    int maxJugadores,
    void Function(Map<String, dynamic>) onCreada,
    void Function(List<Map<String, dynamic>>) onEstadoJugadores,
  ) {
    final s = getSocket();

    s.once('sala_creada', (data) {
      final map = (data is Map)
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      onCreada(map);
    });

    s.once('estado_jugadores', (data) {
      final list = (data as List?) ?? const [];
      final jugadores = list
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      onEstadoJugadores(jugadores);
    });

    if (!s.connected) s.connect();
    s.emit('crear_sala', {
      'nombreHost': nombre,
      'maxJugadores': maxJugadores,
    });
  }

  void _setAppSocketId() {
    try {
      final id = _socket?.id ?? '';
      if (id.isEmpty) return;
      if (_ctx == null) return; // si no registraste contexto, salimos
      final app = Provider.of<AppState>(_ctx!, listen: false);
      app.setSocketId(id);
    } catch (_) {
      // no romper la app por temas de contexto
    }
  }


  // unirseSala(nombre, codigo, onUnida(Map), [onEstadoJugadores(List)])
  void unirseSala(String nombre, String codigo,
      [void Function(dynamic)? onUnida,
      void Function(dynamic)? onEstadoJugadores]) {
    final s = getSocket();

    if (onUnida != null) {
      // 🔁 Map: {codigo, jugadores, estado, esHost}
      s.once('sala_unida', (data) => onUnida(data));
    }
    if (onEstadoJugadores != null) {
      // 🔁 List de jugadores
      s.once('estado_jugadores', (data) => onEstadoJugadores(data));
    }

    if (!s.connected) s.connect();
    s.emit('unirse_sala', {
      'codigo': codigo,
      'nombre': nombre,
    });
  }

  void salirSala(String codigo) {
    final s = getSocket();
    if (!s.connected) s.connect();
    s.emit('salir_sala', {'codigo': codigo});
  }

  void iniciarPartida(String codigo) {
    final s = getSocket();
    if (!s.connected) s.connect();
    s.emit('iniciar_partida', {'codigo': codigo});
  }

  void enviarPrediccion(String codigo, int cantidad) {
    final s = getSocket();
    if (!s.connected) s.connect();
    s.emit('enviar_prediccion', {'codigo': codigo, 'cantidad': cantidad});
  }

  void jugarCarta(String codigo, Map<String, dynamic> carta) {
    final s = getSocket();
    if (!s.connected) s.connect();
    s.emit('jugar_carta', {'codigo': codigo, 'carta': carta});
  }

  // Estandarizado con el server
  void enviarMensajeChat(String codigo, String mensaje) {
    final s = getSocket();
    if (!s.connected) s.connect();
    s.emit('enviar_mensaje_chat', {'codigo': codigo, 'mensaje': mensaje});
  }

  void pedirEstado(String codigo) {
    final s = getSocket();
    if (!s.connected) s.connect();
    s.emit('pedir_estado', {'codigo': codigo});
  }

  // Opcionales
  void connect() => getSocket().connect();
  void disconnect() => getSocket().disconnect();

  // ---------- UI helpers ----------
  void _snack(String msg) {
    debugPrint('[SocketService] $msg');
    final ctx = _ctx;
    if (ctx == null) return;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

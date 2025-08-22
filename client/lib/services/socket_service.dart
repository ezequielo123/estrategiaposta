// lib/services/socket_service.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
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

    // Nuevos: feedback y limpieza de última sala si falla
    _socket!.on('error_unirse_sala', (data) {
      _snack('Unirse: ${data ?? ''}');
      try { _appFromCtx().clearLastSession(); } catch (_) {}
    });
    _socket!.on('error_crear_sala', (data) {
      _snack('Crear sala: ${data ?? ''}');
    });

    // 🔔 Turno de jugar → actualiza AppState y (opcional) ping sutil si es tu turno
    _socket!.on('turno_jugar', (data) {
      try {
        // data: { id, nombre } o solo id
        final id = (data is Map && data['id'] != null)
            ? data['id'].toString()
            : data.toString();

        // ✔️ guardar en AppState quién juega ahora
        _appFromCtx().setTurnoJugadorId(id);

        // 🔔 opcional: si es tu turno, podrías disparar un ping
        try {
          final app = _appFromCtx();
          if (app.socketId == id) {
            // TODO: AudioService().pingTurno(); // si tenés un servicio de audio
          }
        } catch (_) {}
      } catch (e) {
        debugPrint('[Socket] turno_jugar parse error: $e');
      }
    });

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

  /// Obtiene AppState desde el contexto registrado (main.dart)
  AppState _appFromCtx() {
    final ctx = _ctx;
    if (ctx == null) {
      throw StateError('SocketService.registerContext(context) debe llamarse en main.dart');
    }
    return ctx.read<AppState>();
  }

  // -------- API esperada por tus pantallas (compat + mejoras) --------

  /// crearSala(nombre, maxJugadores, onCreada(Map), onEstadoJugadores(List))
  /// Ahora SIEMPRE manda también el userId estable (AppState.userId).
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

    // userId + nombre final
    String? userId;
    String nombreFinal = nombre.trim();
    try {
      final app = _appFromCtx();
      userId = app.userId;
      if (nombreFinal.isEmpty) {
        nombreFinal = (app.userName ?? '').trim();
      }
    } catch (_) {
      // si no hay contexto, seguimos solo con el nombre que llegó por parámetro
    }
    if (nombreFinal.isEmpty) nombreFinal = 'Jugador';

    if (!s.connected) s.connect();
    s.emit('crear_sala', {
      'nombreHost': nombreFinal,
      'maxJugadores': maxJugadores,
      'userId': app.userId,   // 👈
    });
  }

  /// Atajo: crear sala usando el usuario persistente (sin pasar nombre).
  void crearSalaAuto({
    int maxJugadores = 5,
    required void Function(Map<String, dynamic>) onCreada,
    required void Function(List<Map<String, dynamic>>) onEstadoJugadores,
  }) {
    final app = _appFromCtx();
    final nombre = (app.userName ?? 'Jugador');
    crearSala(nombre, maxJugadores, onCreada, onEstadoJugadores);
  }

  void _setAppSocketId() {
    try {
      final id = _socket?.id ?? '';
      if (id.isEmpty) return;
      final ctx = _ctx;
      if (ctx == null) return; // si no registraste contexto, salimos
      final app = ctx.read<AppState>();
      app.setSocketId(id);
    } catch (_) {
      // no romper la app por temas de contexto
    }
  }

  // Enviar “cartel de mesa” (emote)
  void enviarCartel(String codigo, String texto, {String? tipo}) {
    final s = getSocket();
    if (!s.connected) s.connect();
    s.emit('gritar_cartel', {
      'codigo': codigo,
      'texto': texto,
      'tipo' : tipo, // ej: 'pasa', 'lleve'
    });
  }

  /// unirseSala(nombre, codigo, [onUnida], [onEstadoJugadores])
  /// Ahora SIEMPRE manda también el userId estable (AppState.userId).
  void unirseSala(
    String nombre,
    String codigo, [
    void Function(dynamic)? onUnida,
    void Function(dynamic)? onEstadoJugadores,
  ]) {
    final s = getSocket();

    if (onUnida != null) {
      // 🔁 Map: {codigo, socketId, estado, esHost}
      s.once('sala_unida', (data) => onUnida(data));
    }
    if (onEstadoJugadores != null) {
      // 🔁 List de jugadores
      s.once('estado_jugadores', (data) => onEstadoJugadores(data));
    }

    // userId + nombre final
    String? userId;
    String nombreFinal = nombre.trim();
    String code = codigo.trim().toUpperCase();
    try {
      final app = _appFromCtx();
      userId = app.userId;
      if (nombreFinal.isEmpty) {
        nombreFinal = (app.userName ?? '').trim();
      }
    } catch (_) {
      // seguimos igual si no hay contexto
    }
    if (nombreFinal.isEmpty) nombreFinal = 'Jugador';

    if (!s.connected) s.connect();
    s.emit('unirse_sala', {
      'codigo': code,
      'nombre': nombreFinal,
      'userId': app.userId,   // 👈
    });
  }

  /// Atajo: unirse usando usuario persistente (sin pasar nombre).
  void unirseSalaAuto({
    required String codigo,
    void Function(dynamic)? onUnida,
    void Function(dynamic)? onEstadoJugadores,
  }) {
    final app = _appFromCtx();
    final nombre = (app.userName ?? 'Jugador');
    unirseSala(nombre, codigo, onUnida, onEstadoJugadores);
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

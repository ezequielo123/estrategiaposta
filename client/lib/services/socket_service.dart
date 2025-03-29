import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/app_state.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late final IO.Socket _socket;

  SocketService._internal() {
    _socket = IO.io(
      socketServerUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('[Socket] ✅ Conectado: ${_socket.id}');

      // Guardar socketId en AppState global
      _notifyAppStateSocketId();
    });

    _socket.onDisconnect((_) {
      print('[Socket] ❌ Desconectado');
    });

    _socket.onConnectError((err) {
      print('[Socket] ⚠️ Error de conexión: $err');
    });
  }

  IO.Socket getSocket() => _socket;

  /// 🔒 Registra el socketId en AppState si hay un contexto disponible
  void _notifyAppStateSocketId() {
    // Este método debe ser llamado desde un contexto válido si querés notificar manualmente
    // En widgets podrías llamar a:
    //   SocketService().registerContext(context);
    if (_globalContext != null) {
      final appState = Provider.of<AppState>(_globalContext!, listen: false);
      appState.setSocketId(_socket.id ?? '');
    } else {
      print('[Socket] ⚠️ No hay contexto registrado para AppState');
    }
  }

  /// 🧠 Permite registrar el context global para acceder a AppState
  BuildContext? _globalContext;
  void registerContext(BuildContext context) {
    _globalContext = context;
    _notifyAppStateSocketId(); // actualiza si ya estamos conectados
  }

  // 🔹 Crear sala
  void crearSala(String nombre, Function(Map) onSuccess, [Function(String)? onError]) {
    _socket.emit('crear_sala', {
      'nombreJugador': nombre,
    });

    _socket.once('sala_creada', (data) => onSuccess(data));
    _socket.once('error_crear_sala', (msg) {
      if (onError != null) onError(msg);
    });
  }

  // 🔹 Unirse a sala
  void unirseSala(String nombre, String codigo, Function(Map) onSuccess, [Function(String)? onError]) {
    _socket.emit('unirse_sala', {
      'nombreJugador': nombre,
      'codigo': codigo,
    });

    _socket.once('sala_unida', (data) => onSuccess(data));
    _socket.once('error_unirse_sala', (msg) {
      if (onError != null) onError(msg);
    });
  }

  // 🔹 Iniciar partida
  void iniciarPartida(String codigo) {
    _socket.emit('iniciar_partida', {
      'codigo': codigo,
    });
  }

  // 🔹 Enviar predicción
  void enviarPrediccion(String codigo, int cantidad) {
    _socket.emit('enviar_prediccion', {
      'codigo': codigo,
      'cantidad': cantidad,
    });
  }

  // 🔹 Jugar carta
  void jugarCarta(String codigo, Map<String, dynamic> carta) {
    _socket.emit('jugar_carta', {
      'codigo': codigo,
      'carta': carta,
    });
  }
}

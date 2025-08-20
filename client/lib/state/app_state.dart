import 'package:flutter/material.dart';

/// 📦 AppState
/// Controla el estado global del jugador, sala y chat.
class AppState extends ChangeNotifier {
  // 🎮 Estado del jugador
  String _nombreJugador = '';
  String _codigoSala = '';
  String _socketId = '';
  bool _esHost = false;

  // 💬 Mensajes por jugador (socketId → último mensaje)
  final Map<String, String> _mensajesJugador = {};

  // 📤 Getters
  String get nombreJugador => _nombreJugador;
  String get codigoSala => _codigoSala;
  String get socketId => _socketId;
  bool get esHost => _esHost;
  Map<String, String> get mensajesJugador => _mensajesJugador;

    // idSocket -> nombre visible
  final Map<String, String> _nombresPorSocket = {};
  Map<String, String> get nombresPorSocket => _nombresPorSocket;


  // 🧠 Setters individuales
  void setJugador(String nombre) {
    _nombreJugador = nombre;
    notifyListeners();
  }

  void setCodigoSala(String codigo) {
    _codigoSala = codigo;
    notifyListeners();
  }

  void setSocketId(String id) {
    _socketId = id;
    notifyListeners();
  }

  void setEsHost(bool valor) {
    _esHost = valor;
    notifyListeners();
  }

  void setNombrePorSocket(String socketId, String nombre) {
    _nombresPorSocket[socketId] = nombre;
    notifyListeners();
  }


  /// 🧩 Inicializar estado completo al entrar a sala
  void initFromSala({
    required String nombreJugador,
    required String codigo,
    required String socketId,
    required bool esHost,
  }) {
    _nombreJugador = nombreJugador;
    _codigoSala = codigo;
    _socketId = socketId;
    _esHost = esHost;
    notifyListeners();
  }

  /// 💬 Agregar un mensaje temporal por jugador
  void agregarMensajeJugador(String socketId, String mensaje) {
    _mensajesJugador[socketId] = mensaje;
    notifyListeners();

    // ⏳ Desaparece automáticamente después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (_mensajesJugador[socketId] == mensaje) {
        _mensajesJugador.remove(socketId);
        notifyListeners();
      }
    });
  }

  /// 🔄 Reset completo de estado global
  void reset() {
    _nombreJugador = '';
    _codigoSala = '';
    _socketId = '';
    _esHost = false;
    _nombresPorSocket.clear();
    _mensajesJugador.clear();
    notifyListeners();
  }
}

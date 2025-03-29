import 'package:flutter/material.dart';

/// 📦 AppState
/// Controla el estado global del jugador, sala y chat.
class AppState extends ChangeNotifier {
  // 🎮 Estado del jugador
  String _nombreJugador = '';
  String _codigoSala = '';
  String _socketId = '';

  // 💬 Mensajes por jugador (socketId → último mensaje)
  final Map<String, String> _mensajesJugador = {};

  // 📤 Getters
  String get nombreJugador => _nombreJugador;
  String get codigoSala => _codigoSala;
  String get socketId => _socketId;
  Map<String, String> get mensajesJugador => _mensajesJugador;

  // 🧠 Setters con notify
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

  /// 💬 Agregar un mensaje temporal por jugador
  void agregarMensajeJugador(String socketId, String mensaje) {
    _mensajesJugador[socketId] = mensaje;
    notifyListeners();

    // ⏳ Desaparece automáticamente después de 5 segundos
    Future.delayed(Duration(seconds: 5), () {
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
    _mensajesJugador.clear();
    notifyListeners();
  }
}

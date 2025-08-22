import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 📦 AppState
/// Controla el estado global del jugador, sala y chat.
/// Ahora incluye usuario persistente: userId + userName.
class AppState extends ChangeNotifier {
  // ───────── Usuario persistente ─────────
  bool _userLoaded = false;
  String? _userId;      // estable (UUID v4) – persiste en disco
  String? _userName;    // nombre visible – persiste en disco

  bool get userLoaded => _userLoaded;
  String? get userId => _userId;
  String? get userName => _userName;

  // ───────── Estado de la sesión actual ─────────
  String _nombreJugador = '';
  String _codigoSala = '';
  String _socketId = '';
  bool _esHost = false;

  // 💬 Mensajes por jugador (socketId → último mensaje)
  final Map<String, String> _mensajesJugador = {};

  // idSocket -> nombre visible en UI
  final Map<String, String> _nombresPorSocket = {};

  // 📤 Getters sesión actual
  String get nombreJugador => _nombreJugador;
  String get codigoSala => _codigoSala;
  String get socketId => _socketId;
  bool get esHost => _esHost;
  Map<String, String> get mensajesJugador => _mensajesJugador;
  Map<String, String> get nombresPorSocket => _nombresPorSocket;

  AppState() {
    _initUser();
  }

  // Carga/crea userId y lee userName desde SharedPreferences
  Future<void> _initUser() async {
    final sp = await SharedPreferences.getInstance();
    _userId = sp.getString('userId');
    _userName = sp.getString('userName');

    if (_userId == null || _userId!.isEmpty) {
      _userId = const Uuid().v4();               // genera id estable
      await sp.setString('userId', _userId!);
    }

    // Sincroniza nombre de sesión con el persistido, si existe
    if ((_userName ?? '').isNotEmpty) {
      _nombreJugador = _userName!;
    }

    _userLoaded = true;
    notifyListeners();
  }

  /// Setea el nombre visible del usuario (y lo persiste)
  Future<void> setUserName(String name) async {
    final sp = await SharedPreferences.getInstance();
    _userName = name.trim();
    await sp.setString('userName', _userName!);

    // también actualiza el nombre en la sesión actual
    _nombreJugador = _userName!;
    notifyListeners();
  }

  /// (Debug) borra usuario y lo regenera
  Future<void> clearUserForDebug() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('userId');
    await sp.remove('userName');
    _userLoaded = false;
    _userId = null;
    _userName = null;
    await _initUser();
  }

  // ───────── Setters sesión actual (compat con código previo) ─────────
  void setJugador(String nombre) {
    _nombreJugador = nombre;
    // si no había userName, guardalo como predeterminado
    if ((_userName ?? '').isEmpty) {
      setUserName(nombre); // persiste y notifica
      return;
    }
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

    // Opcional: si no hay userName persistido, guardalo
    if ((_userName ?? '').isEmpty && nombreJugador.isNotEmpty) {
      setUserName(nombreJugador);
      return;
    }
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

  /// 🔄 Reset completo de estado global (no borra al usuario persistente)
  void reset() {
    _codigoSala = '';
    _socketId = '';
    _esHost = false;
    _nombresPorSocket.clear();
    _mensajesJugador.clear();

    // _nombreJugador lo dejamos con el userName persistido si existe
    _nombreJugador = _userName ?? '';
    notifyListeners();
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> guardarJugador(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jugador', nombre);
  }

  static Future<String?> obtenerJugador() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jugador');
  }
}

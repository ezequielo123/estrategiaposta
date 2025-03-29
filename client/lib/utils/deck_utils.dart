import '../models/carta.dart';
import 'dart:math';

class DeckUtils {
  static final List<String> palos = ['espadas', 'bastos', 'oros', 'copas'];

  /// Crea una baraja española (40 cartas, sin 8 ni 9)
  static List<Carta> crearBaraja() {
    List<Carta> baraja = [];

    for (String palo in palos) {
      for (int numero = 1; numero <= 12; numero++) {
        if (numero == 8 || numero == 9) continue;
        baraja.add(Carta(numero: numero, palo: palo));
      }
    }

    return baraja;
  }

  /// Mezcla una baraja usando Random
  static List<Carta> mezclar(List<Carta> baraja) {
    final random = Random();
    List<Carta> copia = List.from(baraja);
    copia.shuffle(random);
    return copia;
  }

  /// Roba N cartas de la baraja
  static List<Carta> robarCartas(List<Carta> baraja, int cantidad) {
    return baraja.take(cantidad).toList();
  }
}

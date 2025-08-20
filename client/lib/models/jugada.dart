import 'carta.dart';

class Jugada {
  final String jugador;
  final Carta carta;

  Jugada({
    required this.jugador,
    required this.carta,
  });

  factory Jugada.fromJson(Map<String, dynamic> json) {
    return Jugada(
      jugador: json['jugador']?['nombre'] ?? 'Jugador',
      carta: Carta.fromJson(json['carta']),
    );
  }
}

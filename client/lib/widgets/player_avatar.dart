import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  final String nombre;
  final int puntos;
  final bool esJugadorActual;

  const PlayerAvatar({
    super.key,
    required this.nombre,
    required this.puntos,
    required this.esJugadorActual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: esJugadorActual ? Colors.amber : Colors.grey[800],
          child: Text(nombre[0].toUpperCase(), style: TextStyle(fontSize: 20)),
        ),
        Text(nombre, style: TextStyle(fontSize: 12)),
        Text('$puntos pts', style: TextStyle(fontSize: 10)),
      ],
    );
  }
}

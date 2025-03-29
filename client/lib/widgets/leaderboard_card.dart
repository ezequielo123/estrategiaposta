// lib/widgets/leaderboard_card.dart
import 'package:flutter/material.dart';

class LeaderboardCard extends StatelessWidget {
  final int posicion;
  final String nombre;
  final int puntos;

  const LeaderboardCard({
    super.key,
    required this.posicion,
    required this.nombre,
    required this.puntos,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.amber,
        child: Text('$posicion'),
      ),
      title: Text(nombre, style: TextStyle(color: Colors.white)),
      trailing: Text('$puntos pts', style: TextStyle(color: Colors.white70)),
    );
  }
}

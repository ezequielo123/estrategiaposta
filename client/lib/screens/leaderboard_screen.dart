// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_card.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> ranking = [];
  final provider = LeaderboardProvider();

  @override
  void initState() {
    super.initState();
    cargarRanking();
  }

  void cargarRanking() async {
    final top = await provider.obtenerTopJugadores();
    setState(() => ranking = top);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🏆 Ranking Global')),
      body: ListView.builder(
        itemCount: ranking.length,
        itemBuilder: (_, index) {
          final jugador = ranking[index];
          return LeaderboardCard(
            posicion: index + 1,
            nombre: jugador.nombre,
            puntos: jugador.puntos,
          );
        },
      ),
    );
  }
}

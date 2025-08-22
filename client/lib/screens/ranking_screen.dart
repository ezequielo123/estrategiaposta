import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // para formatear fechas

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  Future<List<Map<String, dynamic>>> _getRanking() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('ranking')
        .orderBy('puntos', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'nombre': data['nombre'] ?? 'Desconocido',
        'puntos': data['puntos'] ?? 0,
        'fecha': (data['timestamp'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🏆 Ranking Global'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getRanking(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay partidas registradas',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (_, index) {
              final jugador = data[index];
              final fechaStr = jugador['fecha'] != null
                  ? DateFormat('dd/MM/yyyy – HH:mm').format(jugador['fecha'])
                  : 'Sin fecha';

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.amber,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jugador['nombre'],
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            fechaStr,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${jugador['puntos']} pts',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

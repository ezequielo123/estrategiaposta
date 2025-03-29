// lib/providers/leaderboard_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardProvider {
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'leaderboard';

  Future<List<LeaderboardEntry>> obtenerTopJugadores({int limite = 10}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('puntos', descending: true)
        .limit(limite)
        .get();

    return snapshot.docs
        .map((doc) => LeaderboardEntry.fromMap(doc.data()))
        .toList();
  }

  Future<void> actualizarPuntaje(String nombre, int puntos) async {
    final ref = _firestore.collection(_collection).doc(nombre);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final prev = snapshot.exists ? snapshot.data()?['puntos'] ?? 0 : 0;

      final nuevoPuntaje = puntos > prev ? puntos : prev;
      tx.set(ref, {'nombre': nombre, 'puntos': nuevoPuntaje});
    });
  }
}

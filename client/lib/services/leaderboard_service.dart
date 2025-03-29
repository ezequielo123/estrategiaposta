import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardService {
  final CollectionReference ranking = FirebaseFirestore.instance.collection('ranking');

  Future<void> actualizarPuntaje({
    required String jugadorId,
    required String nombre,
    required int puntos,
  }) async {
    final doc = ranking.doc(jugadorId);

    final snapshot = await doc.get();

    if (snapshot.exists) {
      final datos = snapshot.data() as Map<String, dynamic>;
      final nuevosPuntos = (datos['puntos'] ?? 0) + puntos;
      final partidas = (datos['partidasJugadas'] ?? 0) + 1;

      await doc.update({
        'puntos': nuevosPuntos,
        'partidasJugadas': partidas,
        'actualizado': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.set({
        'nombre': nombre,
        'puntos': puntos,
        'partidasJugadas': 1,
        'actualizado': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> obtenerTopPlayers({int limite = 10}) async {
    final query = await ranking
        .orderBy('puntos', descending: true)
        .limit(limite)
        .get();

    return query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}

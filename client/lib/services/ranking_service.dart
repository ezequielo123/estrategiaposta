import 'package:cloud_firestore/cloud_firestore.dart';

class RankingService {
  static final _ranking = FirebaseFirestore.instance.collection('ranking');

  static Future<void> registrarGanador(String nombre, int puntos) async {
    try {
      await _ranking.add({
        'nombre': nombre,
        'puntos': puntos,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 Error al guardar ranking: $e');
    }
  }
}

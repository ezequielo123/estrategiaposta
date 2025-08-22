import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class RankingService {
  static final _ranking = FirebaseFirestore.instance.collection('ranking');

  static Future<void> registrarGanador(String nombre, int puntos) async {
    // try {
    //   await _ranking.add({
    //     'nombre': nombre,
    //     'puntos': puntos,
    //     'timestamp': FieldValue.serverTimestamp(),
    //   });
    //   debugPrint('🏆 Ganador registrado: $nombre con $puntos pts');
    // } catch (e) {
    //   debugPrint('🔥 Error al guardar ranking: $e');
    // }
    return;
  }
}

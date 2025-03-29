// lib/models/leaderboard_entry.dart

class LeaderboardEntry {
  final String nombre;
  final int puntos;

  LeaderboardEntry({required this.nombre, required this.puntos});

  factory LeaderboardEntry.fromMap(Map<String, dynamic> data) {
    return LeaderboardEntry(
      nombre: data['nombre'] ?? 'Sin nombre',
      puntos: data['puntos'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'puntos': puntos,
    };
  }
}

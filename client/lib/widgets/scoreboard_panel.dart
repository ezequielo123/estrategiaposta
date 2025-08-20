// lib/widgets/scoreboard_panel.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class ScoreboardPanel extends StatelessWidget {
  const ScoreboardPanel({
    super.key,
    required this.jugadores,
    required this.predicciones,
    this.turnoPredId,
    this.segsRestantesPred,
    this.segsTotalesPred = 15,
  });

  final List<Map<String, dynamic>> jugadores;
  final Map<String, int?> predicciones;
  final String? turnoPredId;
  final int? segsRestantesPred;
  final int segsTotalesPred;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black54)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.leaderboard, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('Tablero',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .3,
                      )),
                ],
              ),
              const SizedBox(height: 10),
              ...jugadores.map((j) {
                final id = (j['id'] ?? '').toString();
                final nombre = (j['nombre'] ?? '').toString();
                final puntos = (j['puntos'] as num?)?.toInt() ?? 0;
                final pred = predicciones[id];

                final esTurno = (turnoPredId != null && turnoPredId == id);
                final progress = (esTurno && segsRestantesPred != null && segsTotalesPred > 0)
                    ? (segsRestantesPred! / segsTotalesPred).clamp(0.0, 1.0)
                    : null;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // avatar + anillo de progreso si está prediciendo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white10,
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (progress != null)
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _chip('Pred', pred?.toString() ?? '—', Colors.deepPurple),
                      const SizedBox(width: 6),
                      _chip('Pts', '$puntos', Colors.teal),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.25),
        border: Border.all(color: color.withOpacity(.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

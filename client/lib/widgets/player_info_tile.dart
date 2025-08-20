import 'package:flutter/material.dart';
import '../models/puntaje_jugador.dart';

class PlayerInfoTile extends StatelessWidget {
  final PuntajeJugador jugador;
  final bool esJugadorActual;

  const PlayerInfoTile({
    Key? key,
    required this.jugador,
    this.esJugadorActual = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isCompact = constraints.maxWidth < 200;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: esJugadorActual ? Colors.amberAccent : Colors.white24,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: esJugadorActual ? Colors.amber : Colors.deepPurple,
                child: Text(
                  jugador.nombre[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jugador.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: esJugadorActual ? Colors.amber : Colors.white,
                      ),
                    ),
                    if (jugador.historial.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 2,
                          children: jugador.historial.map((r) {
                            return Icon(
                              r.acerto ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: r.acerto ? Colors.greenAccent : Colors.redAccent,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${jugador.puntos} pts',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

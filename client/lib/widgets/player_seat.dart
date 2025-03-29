import 'package:flutter/material.dart';

class PlayerSeat extends StatelessWidget {
  final String nombre;
  final int puntos;
  final Offset posicion;
  final bool esJugadorActual;
  final String? ultimoMensaje;

  const PlayerSeat({
    super.key,
    required this.nombre,
    required this.puntos,
    required this.posicion,
    this.esJugadorActual = false,
    this.ultimoMensaje,
  });

  @override
  Widget build(BuildContext context) {
    final size = 80.0;

    return Positioned(
      left: posicion.dx,
      top: posicion.dy,
      child: Column(
        children: [
          // 💬 Mensaje de chat flotante (con animación)
          AnimatedOpacity(
            opacity: ultimoMensaje != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: ultimoMensaje != null
                ? Container(
                    constraints: BoxConstraints(maxWidth: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ultimoMensaje!,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 🎭 Avatar con glow animado si es el jugador actual
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurple.shade300,
              border: esJugadorActual
                  ? Border.all(color: Colors.amberAccent, width: 4)
                  : null,
              boxShadow: esJugadorActual
                  ? [
                      BoxShadow(
                        color: Colors.yellowAccent.withOpacity(0.9),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                nombre.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 🔠 Nombre con Tooltip si es largo
          Tooltip(
            message: nombre,
            child: Text(
              nombre.length > 10 ? '${nombre.substring(0, 8)}...' : nombre,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // ⭐️ Puntos
          Text(
            '$puntos pts',
            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

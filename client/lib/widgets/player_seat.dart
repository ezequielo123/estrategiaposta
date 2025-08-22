import 'package:flutter/material.dart';
import './turn_halo.dart';

class PlayerSeat extends StatelessWidget {
  const PlayerSeat({
    super.key,
    required this.nombre,
    required this.puntos,
    required this.posicion,
    required this.esJugadorActual,
    this.ultimoMensaje,

    // Turno de predicción (ya lo tenías)
    this.enTurnoPred = false,
    this.segsRestantesPred,
    this.segsTotalesPred = 15,

    // ⟵ NUEVO: halo cuando es el turno de JUGAR carta
    this.enTurnoJuego = false,
  });

  final String nombre;
  final int puntos;
  final Offset posicion;
  final bool esJugadorActual;
  final String? ultimoMensaje;

  // Predicción
  final bool enTurnoPred;
  final int? segsRestantesPred; // si es null, no se muestra el anillo
  final int segsTotalesPred;    // default 15

  // Juego (nuevo)
  final bool enTurnoJuego;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 64.0;

    // Progreso para anillo (0..1)
    final total = segsTotalesPred <= 0 ? 1 : segsTotalesPred;
    final left = (segsRestantesPred ?? total).clamp(0, total);
    final progress = left / total;

    return Positioned(
      left: posicion.dx,
      top: posicion.dy,
      child: TurnHalo(
        active: enTurnoJuego,        // 🔆 glow sutil cuando le toca jugar
        intensity: 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Avatar base
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: esJugadorActual ? Colors.amber.withOpacity(0.35) : Colors.black26,
                    border: Border.all(
                      color: esJugadorActual ? Colors.amber : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _iniciales(nombre),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                // Anillo de progreso para turno de predicción
                if (enTurnoPred && segsRestantesPred != null)
                  SizedBox(
                    width: avatarSize + 10,
                    height: avatarSize + 10,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.33 ? Colors.lightGreenAccent : Colors.redAccent,
                      ),
                    ),
                  ),

                // Numerito con segundos restantes (predicción)
                if (enTurnoPred && segsRestantesPred != null)
                  Positioned(
                    bottom: -18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '$left s',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),

                // Punto sutil indicando "jugando ahora"
                if (enTurnoJuego)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withOpacity(.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.withOpacity(.5),
                            blurRadius: 12,
                            spreadRadius: 1.5,
                          ),
                        ],
                        border: Border.all(color: Colors.black87, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: avatarSize + 40,
              child: Column(
                children: [
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '$puntos pts',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (ultimoMensaje != null && ultimoMensaje!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        ultimoMensaje!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _iniciales(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/jugada.dart';

class MesaCentral extends StatelessWidget {
  final List<Jugada> jugadas;

  const MesaCentral({super.key, required this.jugadas});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2.2);
    final radius = 100.0;

    return Stack(
      children: [
        // 🟢 Mesa circular
        Positioned(
          left: center.dx - radius,
          top: center.dy - radius,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: Colors.green[800],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),

        // ✨ Jugadas con animación + imagen
        for (int i = 0; i < jugadas.length; i++)
          _buildJugadaAnimada(jugadas[i], i, jugadas.length, center, radius),
      ],
    );
  }

  Widget _buildJugadaAnimada(Jugada jugada, int index, int total, Offset center, double radius) {
    final angle = (2 * pi * index) / total;
    final x = center.dx + radius * cos(angle) - 40;
    final y = center.dy + radius * sin(angle) - 50;

    return Positioned(
      left: x,
      top: y,
      child: _CartaConAnimacion(jugada: jugada),
    );
  }
}

// 🔄 Widget separado con Fade + Imagen
class _CartaConAnimacion extends StatefulWidget {
  final Jugada jugada;

  const _CartaConAnimacion({required this.jugada});

  @override
  State<_CartaConAnimacion> createState() => _CartaConAnimacionState();
}

class _CartaConAnimacionState extends State<_CartaConAnimacion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carta = widget.jugada.carta;
    final String imgPath = 'assets/cartas/${carta.numero}_${carta.palo.toLowerCase()}.jpeg';

    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                imgPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    '${carta.numero}\n${carta.palo}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.jugada.jugador,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/puntaje_jugador.dart';

class ScoreboardWidget extends StatefulWidget {
  final List<PuntajeJugador> puntajes;

  const ScoreboardWidget({Key? key, required this.puntajes}) : super(key: key);

  @override
  State<ScoreboardWidget> createState() => _ScoreboardWidgetState();
}

class _ScoreboardWidgetState extends State<ScoreboardWidget> {
  bool visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.puntajes
              .map((p) => Text(
                    '${p.nombre}: ${p.puntos} pts',
                    style: const TextStyle(color: Colors.white),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RoundTransitionWidget extends StatefulWidget {
  final int ronda;
  final VoidCallback onFinish;

  const RoundTransitionWidget({
    super.key,
    required this.ronda,
    required this.onFinish,
  });

  @override
  State<RoundTransitionWidget> createState() => _RoundTransitionWidgetState();
}

class _RoundTransitionWidgetState extends State<RoundTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Cierra después de 2.5 segundos
    Future.delayed(const Duration(seconds: 2), widget.onFinish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🌀 Ronda ${widget.ronda}',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Iniciando...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

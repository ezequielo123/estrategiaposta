import 'package:flutter/material.dart';

class AnimatedPulseButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  const AnimatedPulseButton({
    super.key,
    required this.enabled,
    required this.onPressed,
    required this.label,
  });

  @override
  State<AnimatedPulseButton> createState() => _AnimatedPulseButtonState();
}

class _AnimatedPulseButtonState extends State<AnimatedPulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.scale(
          scale: 1 + (_controller.value * 0.05),
          child: child,
        );
      },
      child: ElevatedButton.icon(
        onPressed: widget.enabled ? widget.onPressed : null,
        icon: const Icon(Icons.play_arrow),
        label: Text(widget.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
        ),
      ),
    );
  }
}

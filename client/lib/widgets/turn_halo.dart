// lib/widgets/turn_halo.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class TurnHalo extends StatefulWidget {
  final Widget child;
  final bool active;
  final Color color;
  final double intensity; // 0.0..2.0

  const TurnHalo({
    super.key,
    required this.child,
    required this.active,
    this.color = const Color(0xFFFFD54F), // amber[300]
    this.intensity = 1.0,
  });

  @override
  State<TurnHalo> createState() => _TurnHaloState();
}

class _TurnHaloState extends State<TurnHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = (math.sin((_ctrl.value * 2 * math.pi)) + 1) / 2; // 0..1
        final alpha = 0.25 + 0.35 * t;     // opacidad respirando
        final blur = 14.0 + 10.0 * t;      // blur respirando
        final spread = 1.5 + 1.0 * t;      // spread respirando
        final c = widget.color.withOpacity(alpha * (0.9 * widget.intensity));

        return Stack(
          children: [
            // halo exterior
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: c, blurRadius: blur, spreadRadius: spread),
                      BoxShadow(color: c.withOpacity(0.35), blurRadius: blur * 1.4, spreadRadius: spread * .6),
                    ],
                  ),
                ),
              ),
            ),
            // borde sutil
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withOpacity(0.35), width: 1.2),
              ),
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

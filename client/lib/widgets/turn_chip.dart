// lib/widgets/turn_chip.dart
import 'package:flutter/material.dart';

class TurnChip extends StatelessWidget {
  final bool esMiTurno;
  final String texto;

  const TurnChip({
    super.key,
    required this.esMiTurno,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    final bg = esMiTurno ? Colors.amber.withOpacity(0.18) : Colors.white.withOpacity(0.08);
    final fg = esMiTurno ? Colors.amberAccent : Colors.white70;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(0.6)),
          boxShadow: esMiTurno
              ? [BoxShadow(color: Colors.amberAccent.withOpacity(.35), blurRadius: 16, spreadRadius: 1)]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(esMiTurno ? Icons.flash_on_rounded : Icons.schedule_rounded, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, letterSpacing: .2),
            ),
          ],
        ),
      ),
    );
  }
}

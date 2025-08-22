import 'package:flutter/material.dart';

class CartelVM {
  final String id;
  final String texto;
  final String tipo;   // opcional: 'pasa' | 'lleve' | ''
  final String autor;
  CartelVM({required this.id, required this.texto, required this.tipo, required this.autor});
}

class CartelMesaOverlay extends StatelessWidget {
  final List<CartelVM> carteles;
  const CartelMesaOverlay({super.key, required this.carteles});

  Color _bgFor(String tipo) {
    switch (tipo) {
      case 'pasa':  return const Color(0xFF0BD3A0).withOpacity(.90);
      case 'lleve': return const Color(0xFFFFC107).withOpacity(.92);
      default:      return Colors.deepPurpleAccent.withOpacity(.88);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carteles.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment(0, -0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: carteles.take(3).map((c) {
            return TweenAnimationBuilder<double>(
              key: ValueKey(c.id),
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: _bgFor(c.tipo),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 18, offset: const Offset(0,8)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.texto,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '— ${c.autor}',
                      style: TextStyle(
                        color: Colors.black.withOpacity(.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

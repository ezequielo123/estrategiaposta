import 'package:flutter/material.dart';

class CartaWidget extends StatelessWidget {
  final int numero;
  final String palo;
  final double width;
  final double height;

  const CartaWidget({
    super.key,
    required this.numero,
    required this.palo,
    this.width = 80,
    this.height = 120,
  });

  String get simbolo {
    switch (palo.toLowerCase()) {
      case 'espadas':
        return '⚔️';
      case 'bastos':
        return '🪵';
      case 'oros':
        return '🪙';
      case 'copas':
        return '🍷';
      default:
        return '?';
    }
  }

  Color get paloColor {
    switch (palo.toLowerCase()) {
      case 'oros':
        return Colors.amber.shade700;
      case 'copas':
        return Colors.redAccent;
      case 'espadas':
        return Colors.grey.shade600;
      case 'bastos':
        return Colors.brown.shade400;
      default:
        return Colors.black;
    }
  }

  @override
Widget build(BuildContext context) {
  final String assetPath = 'assets/cartas/${numero}_${palo.toLowerCase()}.jpeg';

  return Container(
    width: width,
    height: height,
    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black87, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(2, 2),
        )
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // fallback visual si falta la imagen
          return Stack(
            children: [
              // Número
              Positioned(
                top: 8,
                left: 8,
                child: Text(
                  '$numero',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Simbolo en el centro
              Center(
                child: Text(
                  simbolo,
                  style: const TextStyle(fontSize: 40),
                ),
              ),

              // Palo abajo
              Positioned(
                bottom: 6,
                right: 6,
                child: Text(
                  palo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: paloColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
}
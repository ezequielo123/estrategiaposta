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
        return Colors.amber;
      case 'copas':
        return Colors.redAccent;
      case 'espadas':
        return Colors.grey.shade300;
      case 'bastos':
        return Colors.brown.shade300;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: Stack(
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
                color: Colors.black,
              ),
            ),
          ),

          // Simbolo en el centro
          Center(
            child: Text(
              simbolo,
              style: TextStyle(fontSize: 40),
            ),
          ),

          // Palo abajo
          Positioned(
            bottom: 6,
            right: 6,
            child: Text(
              palo,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: paloColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

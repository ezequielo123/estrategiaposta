import 'package:flutter/material.dart';
import '../models/carta.dart' as model;
import 'carta_widget.dart'; // 🔗 Asegúrate de importar tu widget visual

class ManoJugador extends StatelessWidget {
  final List<model.Carta> cartas;
  final void Function(model.Carta carta) onCartaSeleccionada;

  const ManoJugador({
    super.key,
    required this.cartas,
    required this.onCartaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cartas.asMap().entries.map((entry) {
            final index = entry.key;
            final carta = entry.value;

            return AnimatedOpacity(
              opacity: 1,
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: GestureDetector(
                onTap: () => onCartaSeleccionada(carta),
                child: CartaWidget(
                  numero: carta.numero,
                  palo: carta.palo,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

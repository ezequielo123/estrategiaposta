import 'package:flutter/material.dart';
import '../models/carta.dart';
import '../models/jugada.dart';
import '../models/puntaje_jugador.dart';

class ManoCartas extends StatelessWidget {
  final List<Carta> cartas;
  final void Function(Carta carta) onCartaSeleccionada;

  const ManoCartas({
    Key? key,
    required this.cartas,
    required this.onCartaSeleccionada,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: cartas.map((carta) {
        return GestureDetector(
          onTap: () => onCartaSeleccionada(carta),
          child: CartaWidget(carta: carta),
        );
      }).toList(),
    );
  }
}

class CartaWidget extends StatelessWidget {
  final Carta carta;

  const CartaWidget({Key? key, required this.carta}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).cardColor;
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(vertical: 4),
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.amber, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${carta.numero}\n${carta.palo}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class TableroJugada extends StatelessWidget {
  final List<Jugada> jugadas;

  const TableroJugada({Key? key, required this.jugadas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (jugadas.isEmpty) {
      return const Text('Nadie ha jugado aún.');
    }

    return Column(
      children: jugadas.map((j) {
        return ListTile(
          leading: const Icon(Icons.play_arrow),
          title: Text(j.jugador),
          trailing: Text('${j.carta.numero} de ${j.carta.palo}'),
        );
      }).toList(),
    );
  }
}

class Puntuaciones extends StatelessWidget {
  final List<PuntajeJugador> jugadores;

  const Puntuaciones({Key? key, required this.jugadores}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (jugadores.isEmpty) {
      return const Text('Puntajes no disponibles');
    }

    return Column(
      children: jugadores.map((j) {
        return ListTile(
          title: Text(j.nombre),
          trailing: Text('${j.puntos} pts'),
        );
      }).toList(),
    );
  }
}

class VistaGanador extends StatelessWidget {
  final String nombreGanador;
  final VoidCallback onSalir;

  const VistaGanador({
    Key? key,
    required this.nombreGanador,
    required this.onSalir,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const Text(
          '🎉 ¡Ganador!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          nombreGanador,
          style: const TextStyle(fontSize: 24, color: Colors.greenAccent),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onSalir,
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Salir'),
        ),
      ],
    );
  }
}

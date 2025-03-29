import 'package:flutter/material.dart';
import 'package:estrategia/models/carta.dart';
import 'package:estrategia/models/jugada.dart';
import 'package:estrategia/utils/deck_utils.dart';
import 'package:estrategia/widgets/mano_jugador.dart';
import 'package:estrategia/widgets/mesa_central.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  List<Carta> baraja = [];
  List<Carta> manoJugador = [];
  List<Carta> manoBot = [];
  List<Jugada> jugadas = [];

  @override
  void initState() {
    super.initState();
    iniciarPartida();
  }

  void iniciarPartida() {
    baraja = DeckUtils.mezclar(DeckUtils.crearBaraja());
    manoJugador = DeckUtils.robarCartas(baraja, 5);
    baraja.removeRange(0, 5);
    manoBot = DeckUtils.robarCartas(baraja, 5);
    baraja.removeRange(0, 5);
    jugadas = [];
  }

  void jugarCartaJugador(Carta carta) {
    setState(() {
      manoJugador.removeWhere((c) => c.numero == carta.numero && c.palo == carta.palo);
      jugadas.add(Jugada(jugador: "Tú", carta: carta));

      // Simula turno del bot
      Future.delayed(Duration(milliseconds: 800), () {
        final cartaBot = manoBot.removeAt(0);
        setState(() {
          jugadas.add(Jugada(jugador: "Bot", carta: cartaBot));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      appBar: AppBar(title: Text("Modo Entrenamiento 🧠")),
      body: Stack(
        children: [
          MesaCentral(jugadas: jugadas),
          ManoJugador(
            cartas: manoJugador,
            onCartaSeleccionada: jugarCartaJugador,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.replay),
        onPressed: () => setState(() => iniciarPartida()),
      ),
    );
  }
}

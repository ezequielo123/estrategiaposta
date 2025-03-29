import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/carta.dart' as model;
import '../models/jugada.dart';
import '../models/puntaje_jugador.dart';

import '../services/socket_service.dart';
import '../state/app_state.dart';

import '../widgets/player_seat.dart';
import '../widgets/mesa_central.dart';
import '../widgets/mano_jugador.dart';
import '../widgets/chat_adaptativo_widget.dart';
import '../services/ranking_service.dart'; // 👈 Asegurate de importar

class GameScreen extends StatefulWidget {
  final Map<String, dynamic> estadoRonda;
  final List<Map<String, dynamic>> jugadasIniciales;

  const GameScreen({
    Key? key,
    required this.estadoRonda,
    required this.jugadasIniciales,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final socketService = SocketService();

  int? prediccion;
  bool prediccionEnviada = false;
  bool esperando = true;

  List<model.Carta> cartasJugador = [];
  List<Jugada> jugadasActuales = [];
  List<PuntajeJugador> puntajes = [];
  String? ganador;

  @override
  void initState() {
    super.initState();
    final socket = socketService.getSocket();
    final appState = Provider.of<AppState>(context, listen: false);

    // 🧼 Limpieza
    socket
      ..off('iniciar_ronda')
      ..off('actualizar_tablero')
      ..off('fin_ronda')
      ..off('fin_partida')
      ..off('predicciones_completas')
      ..off('chat_mensaje');

    // 🃏 Cargar mano inicial
    try {
      final jugador = widget.jugadasIniciales.firstWhere(
        (j) => j['jugador']['id'] == appState.socketId,
      );
      final mano = jugador['mano'];
      setState(() {
        cartasJugador = mano
            .map<model.Carta>(
              (c) => model.Carta(numero: c['numero'], palo: c['palo']),
            )
            .toList();
        esperando = false;
      });
    } catch (_) {
      debugPrint('⚠️ No se encontró la mano inicial del jugador');
    }

    // 🛰️ Listeners
    socket.on('iniciar_ronda', (data) {
      final jugadas = List<Map<String, dynamic>>.from(data['jugadas']);
      try {
        final jugador = jugadas.firstWhere(
          (j) => j['jugador']['id'] == appState.socketId,
        );
        final mano = jugador['mano'];
        setState(() {
          cartasJugador = mano
              .map<model.Carta>(
                  (c) => model.Carta(numero: c['numero'], palo: c['palo']))
              .toList();
          esperando = false;
          prediccion = null;
          prediccionEnviada = false;
          jugadasActuales = [];
          ganador = null;
        });
      } catch (_) {
        debugPrint('❌ No se encontró al jugador en iniciar_ronda');
      }
    });

    socket.on('actualizar_tablero', (data) {
      final jugadas = List<Map>.from(data);
      setState(() {
        jugadasActuales = jugadas
            .map(
              (j) => Jugada(
                jugador: j['jugador']['nombre'],
                carta: model.Carta(
                  numero: j['carta']['numero'],
                  palo: j['carta']['palo'],
                ),
              ),
            )
            .toList();
      });
    });

    socket.on('chat_mensaje', (data) {
      final appState = Provider.of<AppState>(context, listen: false);
      final socketId = data['socketId'];
      final mensaje = data['mensaje'];
      appState.agregarMensajeJugador(socketId, mensaje);
    });

    socket.on('fin_ronda', (data) {
      final jugadores = List<Map>.from(data);
      setState(() {
        puntajes = jugadores
            .map((j) => PuntajeJugador(
                  nombre: j['nombre'],
                  puntos: j['puntos'],
                ))
            .toList();
      });
    });

    socket.on('fin_partida', (data) async {
        final g = data['ganador']['nombre'];
        final puntos = data['ganador']['puntos'];

        setState(() {
            ganador = g;
        });

        // 🔥 Guardar en Firebase
        await RankingService.registrarGanador(g, puntos ?? 0);

        // 🕒 Ir a pantalla de leaderboard luego de una pausa
        Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, '/ranking');
        });
    });

    socket.on('predicciones_completas', (_) {
      setState(() {
        prediccionEnviada = true;
      });
    });
  }

  void enviarPrediccion() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (prediccion != null && !prediccionEnviada) {
      socketService.enviarPrediccion(appState.codigoSala, prediccion!);
      setState(() {
        prediccionEnviada = true;
      });
    }
  }

  void jugarCarta(model.Carta carta) {
    final appState = Provider.of<AppState>(context, listen: false);
    socketService.jugarCarta(appState.codigoSala, {
      'numero': carta.numero,
      'palo': carta.palo,
    });
    setState(() {
      cartasJugador.removeWhere(
        (c) => c.numero == carta.numero && c.palo == carta.palo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;

    final jugadores = widget.estadoRonda['jugadores'];
    final posiciones = [
      Offset(size.width / 2 - 30, 40),
      Offset(size.width - 90, size.height * 0.25),
      Offset(size.width - 90, size.height * 0.65),
      Offset(20, size.height * 0.65),
      Offset(20, size.height * 0.25),
    ];

    return Scaffold(
      backgroundColor: Colors.green[900],
      body: Stack(
        children: [
          // 🪑 Jugadores en círculo
          for (int i = 0; i < jugadores.length && i < 5; i++)
            PlayerSeat(
              nombre: jugadores[i]['nombre'],
              puntos: jugadores[i]['puntos'],
              posicion: posiciones[i],
              esJugadorActual: jugadores[i]['id'] == appState.socketId,
              ultimoMensaje: appState.mensajesJugador[jugadores[i]['id']],
            ),

          // 🃏 Cartas jugadas en el centro
          MesaCentral(jugadas: jugadasActuales),

          // 🙋 Tu mano de cartas
          ManoJugador(
            cartas: cartasJugador,
            onCartaSeleccionada: jugarCarta,
          ),

          // 🔮 Predicción
          if (!prediccionEnviada)
            Positioned(
              bottom: 150,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  const Text(
                    'Selecciona predicción:',
                    style: TextStyle(color: Colors.white),
                  ),
                  DropdownButton<int>(
                    dropdownColor: Colors.grey[900],
                    value: prediccion,
                    hint: const Text(
                      "Elegir predicción",
                      style: TextStyle(color: Colors.white),
                    ),
                    items: List.generate(
                      widget.estadoRonda['numCartas'] + 1,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('$i'),
                      ),
                    ),
                    onChanged: (val) => setState(() => prediccion = val),
                  ),
                  ElevatedButton(
                    onPressed: prediccion != null ? enviarPrediccion : null,
                    child: const Text('Enviar predicción'),
                  ),
                ],
              ),
            ),

          // 🌀 Esperando
          if (esperando)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 💬 Chat adaptativo (responde a tamaño)
          const ChatAdaptativoWidget(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_screen.dart';
import '../services/socket_service.dart';
import '../state/app_state.dart';
import 'home_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final socketService = SocketService();
  List<Map> jugadores = [];

  @override
  void initState() {
    super.initState();
    final socket = socketService.getSocket();

    socket.off('estado_jugadores');
    socket.off('iniciar_ronda');

    socket.on('estado_jugadores', (data) {
      setState(() {
        jugadores = List<Map>.from(data);
      });
    });

    socket.on('iniciar_ronda', (data) {
      final appState = Provider.of<AppState>(context, listen: false);
      final estado = Map<String, dynamic>.from(data['estado']);
      final jugadas = List<Map<String, dynamic>>.from(data['jugadas']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            estadoRonda: estado,
            jugadasIniciales: jugadas,
          ),
        ),
      );
    });

    final appState = Provider.of<AppState>(context, listen: false);
    socket.emit('pedir_estado', {
      'codigo': appState.codigoSala,
    });
  }

  void iniciarPartida() {
    final appState = Provider.of<AppState>(context, listen: false);
    socketService.iniciarPartida(appState.codigoSala);
  }

  void salirDeSala() {
    final appState = Provider.of<AppState>(context, listen: false);

    // Opcional: emitir un evento 'salir_sala' al backend
    socketService.getSocket().disconnect();
    appState.reset();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sala ${appState.codigoSala}'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            tooltip: 'Salir de sala',
            onPressed: salirDeSala,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Bienvenido ${appState.nombreJugador}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Divider(height: 30),
            Text('Jugadores en sala:', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Expanded(
              child: jugadores.isEmpty
                  ? Center(child: Text('Esperando jugadores...'))
                  : ListView.builder(
                      itemCount: jugadores.length,
                      itemBuilder: (_, index) {
                        final j = jugadores[index];
                        return ListTile(
                          leading: Icon(Icons.person),
                          title: Text(j['nombre']),
                          subtitle: Text('Puntos: ${j['puntos']}'),
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              onPressed: iniciarPartida,
              icon: Icon(Icons.play_arrow),
              label: Text('Iniciar Partida'),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}

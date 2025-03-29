import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lobby_screen.dart';
import '../services/socket_service.dart';
import '../state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController codigoCtrl = TextEditingController();
  final socket = SocketService();

  bool _cargando = false;
  String? _error;

  void crearSala() {
    final nombre = nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _mostrarError('Ingresa tu nombre');
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.setJugador(nombre);

    setState(() {
      _cargando = true;
      _error = null;
    });

    socket.crearSala(
      nombre,
      (data) {
        setState(() => _cargando = false);
        appState.setCodigoSala(data['codigo']);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LobbyScreen()),
        );
      },
      (msgError) {
        setState(() {
          _cargando = false;
          _error = msgError;
        });
        _mostrarError(msgError);
      },
    );
  }

  void unirseSala() {
    final nombre = nombreCtrl.text.trim();
    final codigo = codigoCtrl.text.trim().toUpperCase();

    if (nombre.isEmpty || codigo.isEmpty) {
      _mostrarError('Completa tu nombre y el código de sala');
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.setJugador(nombre);
    appState.setCodigoSala(codigo);

    setState(() {
      _cargando = true;
      _error = null;
    });

    socket.unirseSala(
      nombre,
      codigo,
      (data) {
        setState(() => _cargando = false);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LobbyScreen()),
        );
      },
      (msgError) {
        setState(() {
          _cargando = false;
          _error = msgError;
        });
        _mostrarError(msgError);
      },
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Estrategia 🃏')),
        body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),

            TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(labelText: 'Tu nombre'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crear sala'),
                onPressed: _cargando ? null : crearSala,
            ),
            const Divider(height: 40),
            TextField(
                controller: codigoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'Código de sala'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Unirse a sala'),
                onPressed: _cargando ? null : unirseSala,
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
                icon: const Icon(Icons.leaderboard),
                label: const Text('🏆 Ver Ranking Global'),
                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                ),
                onPressed: () {
                Navigator.pushNamed(context, '/ranking');
                },
            ),

            if (_cargando)
                const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
                ),
            ],
        ),
        ),
    );
    }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../state/app_state.dart';
import 'lobby_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final socketService = SocketService();

  bool _cargando = false;
  String? _error;

  void _crearSala() {
    final appState = Provider.of<AppState>(context, listen: false);
    final nombre = appState.nombreJugador;

    if (nombre.isEmpty) {
      setState(() => _error = 'Nombre no válido');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    socketService.crearSala(
      nombre,
      (data) {
        setState(() => _cargando = false);
        appState.setCodigoSala(data['codigo']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LobbyScreen()),
        );
      },
      (msgError) {
        setState(() {
          _cargando = false;
          _error = msgError;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msgError)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Sala')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),

              Text('Jugador: ${appState.nombreJugador}',
                  style: TextStyle(fontSize: 16)),

              SizedBox(height: 30),

              _cargando
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _crearSala,
                      child: Text('Crear Sala'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

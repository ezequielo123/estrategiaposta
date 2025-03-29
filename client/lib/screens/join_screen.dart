import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../state/app_state.dart';
import 'lobby_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({Key? key}) : super(key: key);

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _codigoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final socketService = SocketService();

  bool _cargando = false;
  String? _error;

  void _unirseSala() {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final nombre = appState.nombreJugador;
    final codigo = _codigoController.text.trim().toUpperCase();

    setState(() {
      _cargando = true;
      _error = null;
    });

    socketService.unirseSala(
      nombre,
      codigo,
      (data) {
        setState(() => _cargando = false);
        appState.setCodigoSala(codigo);

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
      appBar: AppBar(title: const Text('Unirse a Sala')),
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

              SizedBox(height: 20),

              TextFormField(
                controller: _codigoController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'Código de sala'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Ingresa el código de la sala'
                        : null,
              ),
              SizedBox(height: 30),

              _cargando
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _unirseSala,
                      child: Text('Unirse'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/socket_service.dart';

class ChatPanel extends StatefulWidget {
  final AppState appState;

  const ChatPanel({super.key, required this.appState});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final socketService = SocketService();

  void _enviarMensaje() {
    final mensaje = _controller.text.trim();
    if (mensaje.isEmpty) return;

    final socket = socketService.getSocket();
    socket.emit('chat_mensaje', {
      'jugador': widget.appState.nombreJugador,
      'mensaje': mensaje,
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mensajes = widget.appState.mensajesJugador;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black87,
      child: Column(
        children: [
          const Text('Chat de Jugadores', style: TextStyle(color: Colors.white, fontSize: 18)),
          const Divider(color: Colors.white30),
          Expanded(
            child: ListView(
              reverse: true,
              children: mensajes.entries.toList().reversed.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white30),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribir mensaje...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[800],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _enviarMensaje(),
                ),
              ),
              IconButton(
                onPressed: _enviarMensaje,
                icon: const Icon(Icons.send, color: Colors.amberAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
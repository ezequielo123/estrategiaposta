import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../state/app_state.dart';

class ChatToggleWidget extends StatefulWidget {
  const ChatToggleWidget({super.key});

  @override
  State<ChatToggleWidget> createState() => _ChatToggleWidgetState();
}

class _ChatToggleWidgetState extends State<ChatToggleWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> mensajes = [];

  bool abierto = false;

  @override
  void initState() {
    super.initState();
    final socket = SocketService().getSocket();

    socket.on('mensaje_sala', (data) {
      setState(() {
        mensajes.add({
          'jugador': data['jugador'],
          'mensaje': data['mensaje'],
        });
      });
    });
  }

  void enviarMensaje() {
    final appState = Provider.of<AppState>(context, listen: false);
    final mensaje = _controller.text.trim();
    if (mensaje.isEmpty) return;

    SocketService().getSocket().emit('mensaje_sala', {
      'codigo': appState.codigoSala,
      'jugador': appState.nombreJugador,
      'mensaje': mensaje,
    });

    setState(() {
      mensajes.add({
        'jugador': appState.nombreJugador,
        'mensaje': mensaje,
      });
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        child: abierto
            ? Container(
                key: const ValueKey("open"),
                width: 250,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 40,
                      color: Colors.black.withOpacity(0.9),
                      child: Row(
                        children: [
                          const Text("💬 Chat", style: TextStyle(color: Colors.white)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => abierto = false),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: mensajes.length,
                        itemBuilder: (_, index) {
                          final m = mensajes[mensajes.length - 1 - index];
                          return Text(
                            '${m['jugador']}: ${m['mensaje']}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Escribe...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => enviarMensaje(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: enviarMensaje,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            : FloatingActionButton(
                key: const ValueKey("closed"),
                backgroundColor: Colors.green[800],
                onPressed: () => setState(() => abierto = true),
                child: const Icon(Icons.chat_bubble),
              ),
      ),
    );
  }
}

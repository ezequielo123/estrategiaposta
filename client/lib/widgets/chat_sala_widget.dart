import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../state/app_state.dart';

class ChatSalaWidget extends StatefulWidget {
  const ChatSalaWidget({super.key});

  @override
  State<ChatSalaWidget> createState() => _ChatSalaWidgetState();
}

class _ChatSalaWidgetState extends State<ChatSalaWidget> {
  final _controller = TextEditingController();
  final List<_MensajeChat> mensajes = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final socket = SocketService().getSocket();

    socket.on('chat_mensaje', (data) {
      setState(() {
        mensajes.insert(
          0,
          _MensajeChat(
            jugador: data['jugador'] ?? 'Anónimo',
            socketId: data['socketId'],
            mensaje: data['mensaje'],
          ),
        );
      });
    });
  }

  void enviarMensaje() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);

    SocketService().getSocket().emit('enviar_mensaje_chat', {
      'codigo': appState.codigoSala,
      'mensaje': texto,
    });

    setState(() {
      mensajes.insert(
        0,
        _MensajeChat(
          jugador: appState.nombreJugador,
          socketId: appState.socketId,
          mensaje: texto,
        ),
      );
    });

    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void enviarEmoji(String emoji) {
    _controller.text = emoji;
    enviarMensaje();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Positioned(
      right: 0,
      top: 80,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 260,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          border: const Border(left: BorderSide(color: Colors.white30)),
        ),
        child: Column(
          children: [
            const Text(
              '💬 Chat de Sala',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: mensajes.length,
                itemBuilder: (_, index) {
                  final m = mensajes[index];
                  final esPropio = m.socketId == appState.socketId;

                  return Align(
                    alignment:
                        esPropio ? Alignment.centerRight : Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: esPropio ? Colors.blueAccent : Colors.grey[850],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(esPropio ? 12 : 0),
                          bottomRight: Radius.circular(esPropio ? 0 : 12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: esPropio
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!esPropio)
                            Text(
                              m.jugador,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            m.mensaje,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // Emojis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['😀', '😡', '🔥', '😂', '💯', '🎉'].map((emoji) {
                return GestureDetector(
                  onTap: () => enviarEmoji(emoji),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
          ],
        ),
      ),
    );
  }
}

class _MensajeChat {
  final String jugador;
  final String socketId;
  final String mensaje;

  _MensajeChat({
    required this.jugador,
    required this.socketId,
    required this.mensaje,
  });
}

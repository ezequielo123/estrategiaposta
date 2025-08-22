import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../state/app_state.dart';
import '../services/socket_service.dart';

class ChatAdaptativoWidget extends StatefulWidget {
  /// Pasá un mapa id → nombre para mostrar nombres bonitos (desde GameScreen).
  final Map<String, String>? nombresPorId;

  const ChatAdaptativoWidget({super.key, this.nombresPorId});

  @override
  State<ChatAdaptativoWidget> createState() => _ChatAdaptativoWidgetState();
}

class _ChatAdaptativoWidgetState extends State<ChatAdaptativoWidget> {
  // UI
  static const double _kHeaderH = 44;   // altura preferida (sin forzar)
  static const double _kExpandedH = 280;

  final msgCtrl = TextEditingController();
  bool minimizado = true; // arranca minimizado
  int _unread = 0;

  // Mensajes persistentes del chat (id, texto, ts)
  final List<_Msg> _mensajes = <_Msg>[];

  // Audio
  final _player = AudioPlayer();
  final AssetSource _source = AssetSource('sounds/notify.mp3'); // ← sin const
  bool _audioPrimed = false;

  // Socket
  late final SocketService _svc;
  late final void Function(dynamic) _onChatHandler; // ← no-nullable

  @override
  void initState() {
    super.initState();
    _svc = SocketService();

    // Suscribirnos al evento de chat directamente (independiente del GameScreen)
    _onChatHandler = (data) async {
      try {
        final m = Map<String, dynamic>.from(data as Map);
        final id = (m['socketId'] ?? '').toString();
        final texto = (m['mensaje'] ?? '').toString();
        if (texto.isEmpty) return;

        setState(() {
          _mensajes.insert(0, _Msg(id: id, texto: texto, ts: DateTime.now()));
          if (minimizado) _unread++;
        });

        await _playNotify();
      } catch (_) {
        // ignorar
      }
    };

    _svc.getSocket().off('chat_mensaje'); // limpiamos duplicados por las dudas
    _svc.getSocket().on('chat_mensaje', _onChatHandler);
  }

  @override
  void dispose() {
    _svc.getSocket().off('chat_mensaje', _onChatHandler);
    msgCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _primeAudio() async {
    if (_audioPrimed) return;
    try {
      // Web suele exigir interacción del usuario; “preparamos” la fuente.
      await _player.setSource(_source);
      _audioPrimed = true;
    } catch (_) {
      // si falla, igual probaremos play() cuando llegue mensaje
    }
  }

  Future<void> _playNotify() async {
    try {
      if (!_audioPrimed) {
        await _player.setSource(_source);
        _audioPrimed = true;
      }
      await _player.stop();
      await _player.play(_source); // volumen por defecto
    } catch (e) {
      debugPrint('[Chat] notify error: $e');
    }
  }

  String _displayNameFor(String id, AppState app) {
    // prioridad: nombres que nos pasan desde GameScreen
    final byProp = widget.nombresPorId?[id];
    if (byProp != null && byProp.isNotEmpty) return byProp;

    // último recurso: id corto
    if (id.length <= 6) return id;
    return '${id.substring(0, 3)}…${id.substring(id.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 680;
    final appState = Provider.of<AppState>(context, listen: false);

    return Positioned(
      right: isWide ? 12 : 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: isWide ? 300 : MediaQuery.of(context).size.width,
        height: minimizado ? _kHeaderH : _kExpandedH,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.80),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isWide ? 14 : 0),
            topRight: const Radius.circular(14),
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isWide ? 14 : 0),
            topRight: const Radius.circular(14),
          ),
          child: Column(
            // 👉 Para que el header se adapte al alto disponible
            mainAxisSize: MainAxisSize.max,
            children: [
              // Header (alto flexible: sin height fijo para evitar overflow)
              InkWell(
                onTap: () {
                  setState(() {
                    minimizado = !minimizado;
                    if (!minimizado) _unread = 0;
                  });
                  _primeAudio(); // primera interacción, habilita audio en web
                },
                child: Container(
                  // En lugar de height fijo, imponemos un mínimo y dejamos que se adapte.
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.deepPurple.withOpacity(0.7),
                  child: SizedBox(
                    // altura preferida (no obligatoria); si el padre da menos, no desborda
                    height: _kHeaderH,
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$_unread',
                              style: const TextStyle(
                                  color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Icon(
                          minimizado ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Cuerpo (solo si expandido)
              if (!minimizado)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                    child: _mensajes.isEmpty
                        ? const Center(
                            child: Text('No hay mensajes', style: TextStyle(color: Colors.white38)),
                          )
                        : ListView.builder(
                            reverse: true, // últimos arriba
                            itemCount: _mensajes.length,
                            itemBuilder: (_, i) {
                              final m = _mensajes[i];
                              final nombre = _displayNameFor(m.id, appState);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '$nombre  ',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: m.texto,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),

              // Input (solo si expandido)
              if (!minimizado)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: msgCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white10,
                              hintText: 'Escribir...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onSubmitted: (_) => _enviar(context.read<AppState>()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.amber),
                          onPressed: () => _enviar(context.read<AppState>()),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _enviar(AppState appState) {
    final mensaje = msgCtrl.text.trim();
    if (mensaje.isEmpty) return;

    final codigo = appState.codigoSala;
    SocketService().enviarMensajeChat(codigo, mensaje);
    msgCtrl.clear();
  }
}

class _Msg {
  final String id;
  final String texto;
  final DateTime ts;
  _Msg({required this.id, required this.texto, required this.ts});
}

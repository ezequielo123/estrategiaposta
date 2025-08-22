import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../services/socket_service.dart';
import '../widgets/animated_glow.dart';
import '../widgets/animated_pulse_button.dart';
import '../screens/game_screen.dart';
import 'home_screen.dart';
import 'package:flutter/services.dart'; // Clipboard


class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late final SocketService _socketService;
  late final dynamic _socket; // keep it dynamic to avoid extra imports
  List<Map<String, dynamic>> _jugadores = const [];
  bool _iniciando = false;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _socket = _socketService.getSocket();

    // === Listeners defensivos ===
    _socket.on('estado_jugadores', _onEstadoJugadores);
    _socket.on('sala_creada', _onSalaActualizada);
    _socket.on('sala_unida', _onSalaActualizada);
    _socket.on('iniciar_ronda', _onIniciarRonda);
  }

  @override
  void dispose() {
    _socket.off('estado_jugadores', _onEstadoJugadores);
    _socket.off('sala_creada', _onSalaActualizada);
    _socket.off('sala_unida', _onSalaActualizada);
    _socket.off('iniciar_ronda', _onIniciarRonda);
    super.dispose();
  }

  void _onEstadoJugadores(dynamic data) {
    if (!mounted) return;
    try {
      final list = (data as List?)?.cast<Map>() ?? const [];
      setState(() {
        _jugadores = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {/* payload inesperado */}
  }

  void _onSalaActualizada(dynamic data) {
    // refresca listado desde 'sala_creada' / 'sala_unida' si traen jugadores
    _onEstadoJugadores((data is Map && data['jugadores'] is List) ? data['jugadores'] : null);
  }

  void _onIniciarRonda(dynamic data) {
    if (!mounted) return;
    if (data is! Map) {
      debugPrint('[Lobby] iniciar_ronda payload inesperado: $data');
      return;
    }

    // Cast defensivo
    final Map<String, dynamic> estadoRonda =
        Map<String, dynamic>.from((data['estado'] as Map?) ?? const {});

    final List<Map<String, dynamic>> jugadasIniciales =
        (
          (data['jugadasIniciales'] as List?)             // preferida por el cliente
          ?? (data['jugadas'] as List?)                   // fallback desde el server actual
          ?? const []
        )
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Si tu GameScreen pide otros required, pásalos aquí también
    Future.microtask(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            estadoRonda: estadoRonda,
            jugadasIniciales: jugadasIniciales,
          ),
        ),
      );
    });
  }



  void iniciarPartida() {
    if (_iniciando) return;
    final app = context.read<AppState>();
    final codigo = app.codigoSala;
    if (codigo.isEmpty) return;

    setState(() => _iniciando = true);
    _socketService.iniciarPartida(codigo);

    // si el server emite 'iniciar_ronda', navegamos en el listener
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _iniciando = false);
    });
  }

  Future<void> _copiarCodigo(String codigo) async {
    if (codigo.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: codigo)); // 👈 copia real
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código $codigo copiado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _salirSala() {
    final app = context.read<AppState>();
    final codigo = app.codigoSala;
    if (codigo.isNotEmpty) {
      _socketService.salirSala(codigo);
    }
    app.reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final nombre = app.nombreJugador;
    final codigo = app.codigoSala;
    final esHost = app.esHost;

    final hayMinimo = _jugadores.length >= 2;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: _salirSala,
        ),
        title: Row(
          children: [
            const Icon(Icons.groups_2_rounded, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            Text('Sala $codigo', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Copiar código',
            icon: const Icon(Icons.copy_rounded, color: Colors.white70),
            onPressed: () => _copiarCodigo(codigo),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Header(nombre: nombre, codigo: codigo),
                const SizedBox(height: 16),
                Expanded(
                  child: _PlayersCard(
                    jugadores: _jugadores,
                    youSocketId: app.socketId,
                  ),
                ),
                const SizedBox(height: 16),
                if (esHost)
                  _StartCard(
                    enabled: hayMinimo && !_iniciando,
                    onPressed: iniciarPartida,
                    esperando: _iniciando,
                  )
                else
                  _WaitingCard(minimo: hayMinimo),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _salirSala,
                  icon: const Icon(Icons.logout_rounded),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  label: const Text('Salir de la sala'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== Sub-widgets UI =====================

class _Header extends StatelessWidget {
  final String nombre;
  final String codigo;
  const _Header({required this.nombre, required this.codigo});

  @override
  Widget build(BuildContext context) {
    return AnimatedGlow(
      active: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.amber.shade700,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre.isEmpty ? 'Jugador' : nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comparte este código con tus amigos',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CodePill(
              code: codigo,
              onCopy: () async {
                if (codigo.isEmpty) return;
                Clipboard.setData(ClipboardData(text: codigo));
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(
                    content: Text('Código copiado: $codigo'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CodePill extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  const _CodePill({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              code.isEmpty ? '----' : code,
              style: const TextStyle(
                color: Colors.white,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  final List<Map<String, dynamic>> jugadores;
  final String youSocketId;
  const _PlayersCard({required this.jugadores, required this.youSocketId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Jugadores conectados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${jugadores.length}',
                    style: TextStyle(color: Colors.amber.shade200, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: jugadores.isEmpty
                  ? Center(
                      child: Text(
                        'Esperando jugadores…',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    )
                  : GridView.builder(
                      itemCount: jugadores.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3.2,
                      ),
                      itemBuilder: (context, index) {
                        final j = jugadores[index];
                        final id = (j['id'] ?? '') as String;
                        final nombre = (j['nombre'] ?? 'Jugador') as String;
                        final puntos = (j['puntos'] ?? 0) as int;
                        final isYou = id == youSocketId;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isYou ? 0.10 : 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isYou
                                  ? Colors.amber.shade700.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isYou
                                    ? Colors.amber.shade700
                                    : Colors.white.withOpacity(0.12),
                                child: Text(
                                  nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isYou ? '$nombre (vos)' : nombre,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Puntos: $puntos',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  final bool enabled;
  final bool esperando;
  final VoidCallback onPressed;
  const _StartCard({
    required this.enabled,
    required this.onPressed,
    this.esperando = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedGlow(
      active: enabled,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              enabled ? '¿Listos?' : 'Necesitás al menos 2 jugadores',
              style: TextStyle(
                color: enabled ? Colors.amber.shade200 : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: AnimatedPulseButton(
                enabled: enabled && !esperando,
                onPressed: onPressed,
                label: esperando ? 'Iniciando…' : '¡Ahora sí, iniciar partida!',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final bool minimo;
  const _WaitingCard({required this.minimo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              minimo ? 'Esperando al host para comenzar…' : 'Esperando jugadores (mín. 2)…',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

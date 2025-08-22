// lib/screens/home_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/socket_service.dart';
import '../state/app_state.dart';
import 'lobby_screen.dart';
import 'package:flutter/services.dart'; // Clipboard


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final nombreCtrl = TextEditingController();
  final codigoCtrl = TextEditingController();
  final _socketService = SocketService();
  List<Map<String, dynamic>> _jugadores = <Map<String, dynamic>>[];

  bool _cargando = false;
  String? _error;

  int _maxJugadores = 4;

  @override
  void initState() {
    super.initState();
    // Prefill con el nombre y (opcional) el último código
    final app = context.read<AppState>();
    nombreCtrl.text = (app.userName ?? app.nombreJugador);
    // Si querés también prellenar el campo de código:
    // if ((app.ultimoCodigoSala ?? '').isNotEmpty) {
    //   codigoCtrl.text = app.ultimoCodigoSala!;
    // }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    codigoCtrl.dispose();
    super.dispose();
  }

  // ---------------- LÓGICA ----------------

  Future<void> crearSala() async {
    final nombre = nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _mostrarError('⚠️ Ingresá tu nombre');
      return;
    }

    final appState = context.read<AppState>();
    await appState.setUserName(nombre); // 👈 persiste el nombre

    setState(() => _cargando = true);

    _socketService.crearSala(
      nombre,
      _maxJugadores,
      (map) async {
        final codigo = (map['codigo'] ?? '') as String;

        context.read<AppState>().setCodigoSala(codigo);
        context.read<AppState>().setEsHost(true);

        // 👇 COPIAR AL PORTAPAPELES + SNACK
        await Clipboard.setData(ClipboardData(text: codigo));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código $codigo copiado'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Guarda última sala para rejoin
        await context.read<AppState>().saveLastSession(codigo);

        final jugadoresRaw = (map['jugadores'] as List?) ?? const [];
        final jugadores = jugadoresRaw
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        setState(() {
          _jugadores = jugadores;
          _cargando = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LobbyScreen()),
        );
      },
      (jugadores) {
        setState(() {
          _jugadores = jugadores;
          _cargando = false;
        });
      },
    );
  }

  Future<void> _onTapUnirse() async {
    final nombre = nombreCtrl.text.trim();
    final codigo = codigoCtrl.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('⚠️ Ingresá tu nombre');
      return;
    }
    if (codigo.isEmpty) {
      _mostrarError('⚠️ Ingresá el código de sala');
      return;
    }

    final appState = context.read<AppState>();
    await appState.setUserName(nombre); // 👈 persiste el nombre

    setState(() => _cargando = true);

    _socketService.unirseSala(
      nombre,
      codigo,
      (map) async {
        final cod = (map['codigo'] as String?) ?? codigo;
        context.read<AppState>().setCodigoSala(cod);
        context.read<AppState>().setEsHost(false);

        // 👇 COPIAR + SNACK
        await Clipboard.setData(ClipboardData(text: cod));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código $cod copiado'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Guarda última sala para rejoin
        await context.read<AppState>().saveLastSession(cod);

        final jugadoresRaw = (map['jugadores'] as List?) ?? const [];
        final jugadores = jugadoresRaw
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        setState(() {
          _jugadores = jugadores;
          _cargando = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LobbyScreen()),
        );
      },
      (jugadores) {
        setState(() {
          _jugadores = jugadores;
          _cargando = false;
        });
      },
    );
  }

  /// Reunirme rápido a la última sala guardada
  Future<void> _reunirme() async {
    final app = context.read<AppState>();
    final code = app.ultimoCodigoSala;
    if (code == null || code.isEmpty) {
      _mostrarError('No hay una sala reciente guardada');
      return;
    }

    setState(() => _cargando = true);

    // Usa el usuario persistente automáticamente
    _socketService.unirseSalaAuto(
      codigo: code,
      onUnida: (map) async {
        final cod = (map['codigo'] as String?) ?? code;
        context.read<AppState>().setCodigoSala(cod);
        context.read<AppState>().setEsHost(false);

        // Refresca última sala
        await context.read<AppState>().saveLastSession(cod);

        final jugadoresRaw = (map['jugadores'] as List?) ?? const [];
        final jugadores = jugadoresRaw
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        setState(() {
          _jugadores = jugadores;
          _cargando = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LobbyScreen()),
        );
      },
      onEstadoJugadores: (jugadores) {
        setState(() {
          _jugadores = (jugadores as List?)
                  ?.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              <Map<String, dynamic>>[];
        });
      },
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final heroHeight = isWide ? 360.0 : 280.0;
    final app = context.watch<AppState>();
    final ultimo = app.ultimoCodigoSala;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo gradiente
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Hero con imagen + overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/segundo.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                  // Vignette y degradado para mejor lectura
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Título sobre la imagen
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estrategia 🃏',
                          style: GoogleFonts.rubik(
                            fontSize: isWide ? 40 : 34,
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Predicción. Estrategia. Gloria.',
                          style: GoogleFonts.rubik(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: isWide ? 18 : 16,
                          ),
                        ),
                        const Spacer(),
                        // Chips de highlights (opcional)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _Pill(text: 'Multijugador'),
                            _Pill(text: 'Rondas dinámicas'),
                            _Pill(text: 'Ranking global'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido principal (form en tarjeta glass)
          Align(
            alignment: isWide ? Alignment.center : Alignment.bottomCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                isWide ? heroHeight - 120 : heroHeight - 80,
                16,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card del formulario
                            Expanded(child: _glassCard(_buildForm(context))),
                            const SizedBox(width: 16),
                            // Tarjeta secundaria con info/acciones
                            SizedBox(
                              width: 280,
                              child: _glassCard(_buildSidePanel(context)),
                            ),
                          ],
                        )
                      : _glassCard(_buildForm(context)),
                ),
              ),
            ),
          ),

          if (_cargando)
            const Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(color: Colors.amberAccent),
            ),
        ],
      ),
    );
  }

  // ---- Widgets UI ----

  Widget _glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final app = context.watch<AppState>();
    final ultimo = app.ultimoCodigoSala;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado del formulario
        Row(
          children: [
            const Icon(Icons.videogame_asset_rounded, color: Colors.amberAccent),
            const SizedBox(width: 8),
            Text(
              'Entrá a jugar',
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _styledField(
          controller: nombreCtrl,
          hint: '👤 Tu nombre',
        ),
        const SizedBox(height: 12),
        _styledField(
          controller: codigoCtrl,
          hint: '🔐 Código de sala',
        ),

        const SizedBox(height: 12),
        _buildMaxJugadoresSelector(),

        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _primaryButton(
                label: '➕ Crear sala',
                color: Colors.greenAccent,
                onPressed: _cargando ? null : crearSala,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _primaryButton(
                label: '🔓 Unirse',
                color: Colors.blueAccent,
                onPressed: _cargando ? null : _onTapUnirse,
              ),
            ),
          ],
        ),

        // ⭐ Botón Reunirme a la última sala
        if ((ultimo ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.meeting_room_outlined),
            label: Text('Reunirme a la sala $ultimo'),
            onPressed: _cargando ? null : _reunirme,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.25)),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],

        const SizedBox(height: 14),
        _ghostButton(
          label: '🏆 Ver Ranking Global',
          onPressed: () => Navigator.pushNamed(context, '/ranking'),
        ),
      ],
    );
  }

  Widget _buildSidePanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consejos rápidos',
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        const SizedBox(height: 10),
        _tip('Elegí un nombre claro: te verán tus rivales.'),
        _tip('Compartí el código para invitar amigos.'),
        _tip('El último en predecir no puede igualar el total.'),
        const Divider(color: Colors.white12, height: 24),
        Text('Accesos',
            style: GoogleFonts.rubik(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 8),
        _miniAction('Cómo jugar', Icons.help_outline, () {
          _mostrarError('Pronto habrá tutorial 😉');
        }),
        _miniAction('Novedades', Icons.new_releases_outlined, () {
          _mostrarError('Pronto habrá changelog ✨');
        }),
      ],
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.amberAccent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amberAccent),
        ),
      ),
      onSubmitted: (v) async {
        final t = v.trim();
        if (t.isNotEmpty) {
          await context.read<AppState>().setUserName(t);
          _mostrarError('Nombre guardado');
        }
      },
    );
  }

  Widget _buildMaxJugadoresSelector() {
    return Row(
      children: [
        const Icon(Icons.group, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        const Text('Máx. jugadores:', style: TextStyle(color: Colors.white70)),
        const SizedBox(width: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<int>(
              value: _maxJugadores,
              dropdownColor: const Color(0xFF141327),
              iconEnabledColor: Colors.white,
              underline: const SizedBox(),
              items: [2, 3, 4, 5].map((val) {
                return DropdownMenuItem(
                  value: val,
                  child: Text('$val jugadores',
                      style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _maxJugadores = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_arrow),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _ghostButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.25)),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );

  Widget _miniAction(String label, IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// lib/screens/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/carta.dart' as model;
import '../models/jugada.dart';
import '../models/puntaje_jugador.dart';

import '../services/socket_service.dart';
import '../state/app_state.dart';

import '../widgets/player_seat.dart';
import '../widgets/mesa_central.dart';
import '../widgets/mano_jugador.dart';
import '../widgets/chat_adaptativo_widget.dart';
import '../services/ranking_service.dart'; // ya no se usa al final, pero lo dejo

// arriba de GameScreen
import '../widgets/scoreboard_panel.dart';
import '../widgets/prediction_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'final_score_screen.dart';

import '../widgets/turn_halo.dart';
import '../widgets/turn_chip.dart';

import '../widgets/cartel_mesa_overlay.dart';

class GameScreen extends StatefulWidget {
  final Map<String, dynamic> estadoRonda;
  final List<Map<String, dynamic>> jugadasIniciales;

  const GameScreen({
    Key? key,
    required this.estadoRonda,
    required this.jugadasIniciales,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final socketService = SocketService();
  final _sfx = AudioPlayer();

  // Carteles (emotes) en mesa
  final Map<String, Timer> _cartelTimers = {};
  final List<CartelVM> _cartelesActivos = [];

  // 🔮 Predicción
  int? prediccion;
  bool prediccionEnviada = false;
  bool esperando = true;

  bool _esMiTurnoPred = false;
  String _turnoNombre = '';
  List<int> _opcionesPred = <int>[];
  int _countdown = 0;
  Timer? _timer;

  // 🃏 Juego
  List<model.Carta> cartasJugador = [];
  List<Jugada> jugadasActuales = [];
  List<PuntajeJugador> puntajes = [];
  String? ganador;
  Map<String, int?> prediccionesJugadores = {};

  // Cuenta regresiva de predicción
  static const int _COUNTDOWN_TOTAL = 15; // ⟵ 15s
  String _turnoPredId = ''; // ⟵ quién está prediciendo

  // Jugadores en vivo (scoreboard y asientos)
  List<Map<String, dynamic>> _jugadores = <Map<String, dynamic>>[];

  // Estado de ronda para fallback de opciones
  Map<String, dynamic> _estadoRonda = {};

  // Animación de reparto
  bool _dealing = false;

  // 🕹️ Turno de jugar carta
  bool _esMiTurnoJuego = false;
  String _turnoJuegoNombre = '';

  // Demora visual entre bazas
  Timer? _bazaDelayTimer;
  List<Jugada>? _deferredJugadas;

  @override
  void initState() {
    super.initState();
    final socket = socketService.getSocket();
    final appState = Provider.of<AppState>(context, listen: false);

    _sfx.setVolume(0.7);

    // Estado inicial
    _estadoRonda = Map<String, dynamic>.from(widget.estadoRonda);
    final baseJug = (widget.estadoRonda['jugadores'] as List?) ?? const [];
    _jugadores = baseJug
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Limpieza de listeners
    for (final ev in [
      'iniciar_ronda',
      'actualizar_tablero',
      'fin_ronda',
      'fin_partida',
      'estado_predicciones',
      'predicciones_cerradas',
      'predicciones_completas',
      'turno_prediccion',
      'opciones_validas_prediccion',
      'prediccion_auto',
      'turno_jugar',
      'error_prediccion',
      'error_jugada',
      'chat_mensaje',
      'fin_mano', // ⬅️ nuevo
    ]) {
      socket.off(ev);
    }

    // Cargar mano inicial
    try {
      Map<String, dynamic>? yo;
      for (final e in widget.jugadasIniciales) {
        final m = Map<String, dynamic>.from(e);
        final id = (m['jugador'] is Map)
            ? (m['jugador']['id'] as String?)
            : (m['id'] as String?);
        if (id == appState.socketId) {
          yo = m;
          break;
        }
      }
      if (yo != null) {
        final manoRaw = (yo['mano'] as List?) ?? const [];
        setState(() {
          cartasJugador = manoRaw
              .map<model.Carta>((c) => model.Carta(
                    numero: (c as Map)['numero'],
                    palo: c['palo'],
                  ))
              .toList();
          esperando = false;
        });
        _playDealAnim();
      } else {
        debugPrint('⚠️ No se encontró la mano inicial del jugador');
      }
    } catch (_) {
      debugPrint('⚠️ Error casteando jugadasIniciales');
    }

    // Listeners
    socket.on('iniciar_ronda', (data) {
      try {
        Map<String, dynamic> estado = {};
        List<Map<String, dynamic>> jugadas = [];

        if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          if (m['estado'] is Map) {
            estado = Map<String, dynamic>.from(m['estado']);
          }
          final ji = m['jugadasIniciales'];
          if (ji is List) {
            jugadas = ji
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else if (m['jugadas'] is List) {
            jugadas = (m['jugadas'] as List)
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        }

        final myId = appState.socketId;
        Map<String, dynamic>? yo;
        for (final j in jugadas) {
          final id = (j['jugador'] is Map) ? j['jugador']['id'] : j['id'];
          if (id == myId) {
            yo = j;
            break;
          }
        }

        final manoRaw = (yo?['mano'] as List?) ?? const [];
        setState(() {
          _estadoRonda = estado.isNotEmpty ? estado : _estadoRonda;
          cartasJugador = manoRaw
              .map<model.Carta>((c) => model.Carta(
                    numero: (c as Map)['numero'],
                    palo: c['palo'],
                  ))
              .toList();
          esperando = false;
          prediccion = null;
          prediccionEnviada = false;
          _esMiTurnoPred = false;
          _opcionesPred = [];
          _turnoNombre = '';
          _turnoPredId = '';
          _stopCountdown();
          jugadasActuales = [];
          ganador = null;
          _esMiTurnoJuego = false;
          _turnoJuegoNombre = '';
          if (_estadoRonda['jugadores'] is List) {
            _jugadores = (_estadoRonda['jugadores'] as List)
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        });
        _playDealAnim();
      } catch (e) {
        debugPrint('❌ Error en iniciar_ronda: $e');
      }
    });

    // Tablero
    socket.on('actualizar_tablero', (data) {
      try {
        final listaDynamic = (data is List)
            ? data
            : (data is Map && data['jugadas'] is List)
                ? data['jugadas']
                : const [];

        // Parseo igual que antes
        final parsed = <Jugada>[];
        for (final elem in listaDynamic) {
          if (elem is! Map) continue;
          final m = Map<String, dynamic>.from(elem);
          final jugadorNombre = (m['jugador'] is Map)
              ? (m['jugador']['nombre'] ?? '').toString()
              : (m['jugador'] ?? '').toString();

          final c = m['carta'];
          if (c is! Map) continue;

          parsed.add(
            Jugada(
              jugador: jugadorNombre,
              carta: model.Carta(
                numero: (c['numero'] as num).toInt(),
                palo: (c['palo'] ?? '').toString(),
              ),
            ),
          );
        }

        // Detectar si ES la PRIMERA carta de la SIGUIENTE baza
        final nPlayers = _jugadores.length;
        final wasComplete = (jugadasActuales.length == nPlayers) && nPlayers > 0;
        final isFirstOfNextTrick = (parsed.length == 1) && wasComplete;

        if (isFirstOfNextTrick) {
          // ⏱️ Demoramos 1s el reemplazo de la mesa (para que se vea la baza anterior completa)
          _deferredJugadas = parsed;
          _bazaDelayTimer?.cancel();
          _bazaDelayTimer = Timer(const Duration(seconds: 1), () {
            if (!mounted) return;
            final myName = Provider.of<AppState>(context, listen: false).nombreJugador;
            final misJugadas = (_deferredJugadas ?? parsed).where((j) => j.jugador == myName);

            setState(() {
              jugadasActuales = _deferredJugadas ?? parsed;
              // Si en esta nueva lista aparece mi carta (primer jugador fui yo), la removemos
              for (final j in misJugadas) {
                cartasJugador.removeWhere(
                  (c) => c.numero == j.carta.numero && c.palo == j.carta.palo,
                );
              }
            });
            _deferredJugadas = null;
          });

          // No actualizamos inmediatamente para mantener visibles las cartas anteriores
          return;
        }

        // Caso normal: actualización inmediata (misma baza en curso o ya con 2+ cartas de la nueva)
        _bazaDelayTimer?.cancel();
        final myName = Provider.of<AppState>(context, listen: false).nombreJugador;
        final misJugadas = parsed.where((j) => j.jugador == myName);

        setState(() {
          jugadasActuales = parsed;
          // si en esta actualización aparece mi carta, recién ahí la saco
          for (final j in misJugadas) {
            cartasJugador.removeWhere(
              (c) => c.numero == j.carta.numero && c.palo == j.carta.palo,
            );
          }
        });
      } catch (e) {
        debugPrint('❌ Error en actualizar_tablero: $e');
      }
    });

    // Al cerrar una baza: dejar visible 1s la mesa antes de limpiar (útil en mano de 1 carta)
    socket.on('fin_mano', (_) {
      _bazaDelayTimer?.cancel();
      _bazaDelayTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;

        // Si seguimos mostrando la baza completa anterior, limpiamos la mesa
        if (_jugadores.isNotEmpty && jugadasActuales.length == _jugadores.length) {
          setState(() => jugadasActuales = []);
        }
      });
    });

    // Turno de jugar
    socket.on('turno_jugar', (data) {
      try {
        final app = Provider.of<AppState>(context, listen: false);
        String id = '';
        String nombre = '';
        if (data is String) {
          id = data;
        } else if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          id = (m['id'] ?? '').toString();
          nombre = (m['nombre'] ?? '').toString();
        }
        setState(() {
          _esMiTurnoJuego = (id == app.socketId);
          _turnoJuegoNombre = nombre;
        });

        // ✨ aviso sutil cuando arranca el turno de jugar
        final msg = _esMiTurnoJuego ? '¡Es tu turno!' : 'Turno de $nombre';
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

      } catch (_) {}
    });

    // Chat
    socket.on('chat_mensaje', (data) async {
      try {
        final m = Map<String, dynamic>.from(data as Map);
        final sid = (m['socketId'] ?? '').toString();
        final mensaje = (m['mensaje'] ?? '').toString();

        // Actualiza el estado global (para que el widget del chat lo vea)
        Provider.of<AppState>(context, listen: false)
            .agregarMensajeJugador(sid, mensaje);

        // Si el mensaje NO es mío -> sonido + notificación visual sutil
        final myId = Provider.of<AppState>(context, listen: false).socketId;
        if (sid != myId) {
          await _sfx.stop();
          await _sfx.play(AssetSource('sounds/notify.wav'));
          if (mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text('Nuevo mensaje'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (_) {}
    });

    // Fin de ronda
    socket.on('fin_ronda', (data) {
      try {
        final rawList = (data is List)
            ? data
            : (data is Map && data['jugadores'] is List)
                ? data['jugadores']
                : (data is Map && data['puntajes'] is List)
                    ? data['puntajes']
                    : const [];

        final jugadores = <Map<String, dynamic>>[];
        for (final e in rawList) {
          if (e is Map) jugadores.add(Map<String, dynamic>.from(e));
        }

        final byNombre = {
          for (final j in jugadores)
            (j['nombre'] ?? '').toString():
                (j['puntos'] as num?)?.toInt() ?? 0
        };

        setState(() {
          puntajes = jugadores
              .map((j) => PuntajeJugador(
                    nombre: (j['nombre'] ?? '').toString(),
                    puntos: (j['puntos'] as num?)?.toInt() ?? 0,
                  ))
              .toList();

          _jugadores = _jugadores.map((j) {
            final nombre = (j['nombre'] ?? '').toString();
            if (byNombre.containsKey(nombre)) {
              return {
                ...j,
                'puntos': byNombre[nombre],
              };
            }
            return j;
          }).toList();
        });
      } catch (e) {
        debugPrint('❌ Error en fin_ronda: $e');
      }
    });

    // Fin de partida
    socket.on('fin_partida', (data) async {
      try {
        final m = Map<String, dynamic>.from(data as Map);

        // ganador: { nombre, puntos }
        final ganadorMap = Map<String, dynamic>.from(m['ganador'] ?? const {});
        final nombreGanador = (ganadorMap['nombre'] ?? '').toString();

        // tablero: [{id,nombre,puntos}]
        final tablero = (m['tablero'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const <Map<String, dynamic>>[];

        final rondas = (m['rondas'] as num?)?.toInt() ?? 0;

        if (mounted) {
          setState(() {
            ganador = nombreGanador;
          });
        }

        if (!mounted) return;

        if (tablero.isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => FinalScoreScreen(
                ganador: ganadorMap,
                tablero: tablero,
                rondas: rondas,
              ),
            ),
          );
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/ranking');
          });
        }
      } catch (e, st) {
        debugPrint('❌ Error en fin_partida: $e\n$st');
      }
    });

    // Estado de predicciones
    socket.on('estado_predicciones', (data) {
      try {
        final lista = (data as List?) ?? const [];
        final preds = <String, int?>{};
        final nuevosJug = <Map<String, dynamic>>[];
        for (final p in lista) {
          if (p is! Map) continue;
          final m = Map<String, dynamic>.from(p);
          final id = (m['id'] ?? '').toString();
          final pred =
              (m['prediccion'] is num) ? (m['prediccion'] as num).toInt() : null;
          preds[id] = pred;
          nuevosJug.add(m);
        }
        setState(() {
          prediccionesJugadores = preds;
          _jugadores = nuevosJug;
        });
      } catch (e) {
        debugPrint('❌ Error en estado_predicciones: $e');
      }
    });

    // ⛔️ Cerrar predicciones: frenar countdown + ocultar UI
    socket.on('predicciones_completas', (_) {
      _stopCountdown();
      if (!mounted) return;
      setState(() {
        prediccionEnviada = true;
        _esMiTurnoPred = false;
        _turnoPredId = '';
        _turnoNombre = '';
        _opcionesPred = [];
        _countdown = 0;
      });
    });

    // (Compat) algunos servers envían 'predicciones_cerradas'
    socket.on('predicciones_cerradas', (_) {
      _stopCountdown();
      if (!mounted) return;
      setState(() {
        prediccionEnviada = true;
        _esMiTurnoPred = false;
        _turnoPredId = '';
        _turnoNombre = '';
        _opcionesPred = [];
        _countdown = 0;
      });
    });

    // Turno de predicción (+ fallback)
    socket.on('turno_prediccion', (data) {
      try {
        String turnoId = '';
        String nombre = '';
        if (data is String) {
          turnoId = data;
        } else if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          turnoId = (m['id'] ?? '').toString();
          nombre = (m['nombre'] ?? '').toString();
        }
        final esMio = turnoId == appState.socketId;
        setState(() {
          _turnoPredId = turnoId;
          _esMiTurnoPred = esMio;
          _turnoNombre = nombre;
          _countdown = _COUNTDOWN_TOTAL;
          prediccion = null;
          _opcionesPred = [];
          prediccionEnviada = false;
        });
        _startCountdown();

        // Fallback: si no llegan opciones en 300 ms, las calculamos localmente
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          if (_esMiTurnoPred && _opcionesPred.isEmpty) {
            final total =
                (_estadoRonda['numCartas'] as num?)?.toInt() ?? 0;
            final myId = appState.socketId;
            final sumaPrevias = prediccionesJugadores.entries
                .where((e) => e.key != myId && e.value != null)
                .fold<int>(0, (acc, e) => acc + (e.value ?? 0));
            final esUltimo =
                (_estadoRonda['ultimoJugadorPrediccionId']?.toString() ?? '') ==
                    myId;

            final List<int> fallback = [
              for (int i = 0; i <= total; i++)
                if (!(esUltimo && (sumaPrevias + i == total))) i
            ];
            if (fallback.isNotEmpty) {
              setState(() => _opcionesPred = fallback);
            }
          }
        });
      } catch (e) {
        debugPrint('❌ Error en turno_prediccion: $e');
      }
    });

    // Opciones válidas
    socket.on('opciones_validas_prediccion', (data) {
      try {
        List list;
        if (data is List) {
          list = data;
        } else if (data is Map && data['opciones'] is List) {
          list = data['opciones'];
        } else {
          list = const [];
        }
        final ints = list.map<int>((e) => (e as num).toInt()).toList();
        if (!mounted) return;
        setState(() => _opcionesPred = ints);
      } catch (e) {
        debugPrint('❌ Error en opciones_validas_prediccion: $e');
      }
    });

    // Autopredicción informativa
    socket.on('prediccion_auto', (autoVal) {
      final val = (autoVal is num) ? autoVal.toInt() : autoVal;
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Se asignó automáticamente tu predicción: $val')),
      );
    });

    // Errores
    socket.on('error_prediccion', (msg) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(msg.toString())));
      setState(() => _esMiTurnoPred = true); // reintentar
    });

    socket.on('error_jugada', (msg) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(msg.toString())));
      setState(() => _esMiTurnoJuego = true); // reintentar
    });

    // Carteles que llegan del server
    socket.on('cartel_mesa', (data) {
      try {
        final m = Map<String, dynamic>.from(data as Map);
        final from = (m['from'] is Map) ? Map<String, dynamic>.from(m['from']) : const {};
        final autor = (from['nombre'] ?? '').toString();
        final texto = (m['texto'] ?? '').toString();
        final tipo  = (m['tipo'] ?? '').toString();
        final id    = '${DateTime.now().microsecondsSinceEpoch}-${from['id'] ?? ''}';

        setState(() {
          _cartelesActivos.add(CartelVM(id: id, texto: texto, tipo: tipo, autor: autor));
        });

        _cartelTimers[id]?.cancel();
        _cartelTimers[id] = Timer(const Duration(milliseconds: 2500), () {
          if (!mounted) return;
          setState(() => _cartelesActivos.removeWhere((c) => c.id == id));
          _cartelTimers.remove(id);
        });
      } catch (_) {}
    });
  }

  // Animación de reparto
  void _playDealAnim() {
    setState(() => _dealing = true);
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _dealing = false);
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 0) {
        t.cancel();
        if (_esMiTurnoPred && !prediccionEnviada) {
          _autoPrediccion();
        }
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
  }

  void _autoPrediccion() {
    int? choice;
    if (_opcionesPred.contains(1)) {
      choice = 1;
    } else if (_opcionesPred.contains(0)) {
      choice = 0;
    } else if (_opcionesPred.isNotEmpty) {
      choice = _opcionesPred.reduce((a, b) => a < b ? a : b);
    } else {
      final total = (_estadoRonda['numCartas'] as num?)?.toInt() ?? 0;
      choice = total > 0 ? 1 : 0;
    }
    if (choice != null) {
      setState(() => prediccion = choice);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Se asignó automáticamente tu predicción: $choice')),
      );
      enviarPrediccion(force: true);
    }
  }

  void enviarPrediccion({bool force = false}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final p = prediccion;
    if (p == null) return;

    final dentroDeTiempo = _countdown > 0;
    final opcionValida = _opcionesPred.contains(p);

    if (!force) {
      if (!_esMiTurnoPred || !dentroDeTiempo || !opcionValida) return;
    } else {
      if (!_esMiTurnoPred) return;
    }

    socketService.enviarPrediccion(appState.codigoSala, p);
    setState(() {
      _esMiTurnoPred = false; // el server moverá el turno
      prediccionEnviada = true;
    });
  }

  void jugarCarta(model.Carta carta) {
    if (!_esMiTurnoJuego) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('No es tu turno.')));
      return;
    }
    final appState = Provider.of<AppState>(context, listen: false);
    socketService.jugarCarta(appState.codigoSala, {
      'numero': carta.numero,
      'palo': carta.palo,
    });
  }

  @override
  void dispose() {
    _bazaDelayTimer?.cancel();
    for (final t in _cartelTimers.values) { t.cancel(); }
    _cartelTimers.clear();

    _sfx.dispose();
    _stopCountdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;

    final posiciones = [
      Offset(size.width / 2 - 30, 40),
      Offset(size.width - 90, size.height * 0.25),
      Offset(size.width - 90, size.height * 0.65),
      Offset(20, size.height * 0.65),
      Offset(20, size.height * 0.25),
    ];

    final app = context.watch<AppState>();
    final esMiTurno = app.esMiTurno;
    final nombreTurno = app.nombresPorSocket[app.turnoJugadorId ?? ''] ?? '...';

    return Scaffold(
      backgroundColor: Colors.green[900],
      body: Stack(
        children: [
          // Asientos (mantengo tu PlayerSeat tal cual)
          for (int i = 0; i < _jugadores.length && i < 5; i++)
            PlayerSeat(
              nombre: (_jugadores[i]['nombre'] ?? '').toString(),
              puntos: (_jugadores[i]['puntos'] as num?)?.toInt() ?? 0,
              posicion: posiciones[i],
              esJugadorActual: (_jugadores[i]['id'] ?? '') == appState.socketId,
              ultimoMensaje: appState.mensajesJugador[_jugadores[i]['id']],
              enTurnoPred:
                  _turnoPredId == (_jugadores[i]['id'] ?? '').toString(),
              segsRestantesPred: _turnoPredId ==
                      (_jugadores[i]['id'] ?? '').toString()
                  ? _countdown
                  : null,
              segsTotalesPred: _COUNTDOWN_TOTAL,
              enTurnoJuego: (context.read<AppState>().turnoJugadorId ?? '') == ((_jugadores[i]['id'] ?? '').toString()),
            ),

          // Mesa central (agrandada)
          Builder(builder: (context) {
            final w = MediaQuery.of(context).size.width;
            final scaleMesa = w >= 1100 ? 1.15 : w >= 800 ? 1.12 : 1.08;
            return Center(
              child: Transform.scale(
                scale: scaleMesa,
                child: MesaCentral(jugadas: jugadasActuales),
              ),
            );
          }),
          // Overlay de carteles/emotes en mesa (encima de la mesa)
          CartelMesaOverlay(carteles: _cartelesActivos),

          // 🧮 Scoreboard elegante
          Positioned(
            top: 16,
            right: 16,
            child: ScoreboardPanel(
              jugadores: _jugadores,
              predicciones: prediccionesJugadores,
              turnoPredId: _turnoPredId,
              segsRestantesPred: _countdown,
              segsTotalesPred: _COUNTDOWN_TOTAL,
            ),
          ),

          // UI de predicción (arriba, compacta)
          if (!prediccionEnviada)
            PredictionBar(
              esMiTurno: _esMiTurnoPred,
              turnoNombre: _turnoNombre,
              countdown: _countdown,
              opciones: _opcionesPred,
              seleccion: prediccion,
              onSelect: (i) => setState(() => prediccion = i),
              onEnviar: () => enviarPrediccion(),
            ),

          // Mano del jugador (agrandada + animación)
          AnimatedSlide(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            offset: _dealing ? const Offset(0, 0.2) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _dealing ? 0.0 : 1.0,
              child: Builder(builder: (context) {
                final w = MediaQuery.of(context).size.width;
                final scaleHand = w >= 1100 ? 1.28 : w >= 800 ? 1.22 : 1.16;

                return Transform.scale(
                  scale: scaleHand,
                  alignment: Alignment.bottomCenter,
                  child: TurnHalo(
                    active: esMiTurno,
                    intensity: 1.2,
                    child: ManoJugador(
                      cartas: cartasJugador,
                      onCartaSeleccionada: (c) => jugarCarta(c),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Esperando
          if (esperando)
            const Center(child: CircularProgressIndicator(color: Colors.white)),


          // Botones de cartel rápido
          Positioned(
            right: 12,
            bottom: 140, // que no tape tu mano
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _cartelBtn('Pasaaaaaaa', tipo: 'pasa', color: const Color(0xFF0BD3A0)),
                const SizedBox(height: 8),
                _cartelBtn('Que se la ieveeeeee', tipo: 'lleve', color: const Color(0xFFFFC107)),
              ],
            ),
          ),

          // Chat
          ChatAdaptativoWidget(
            nombresPorId: {
              for (final j in _jugadores)
                (j['id'] ?? '').toString(): (j['nombre'] ?? '').toString(),
            },
          ),

          // 🟡 Chip sutil de turno, arriba centrado
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: TurnChip(
              esMiTurno: esMiTurno,
              texto: esMiTurno ? '¡Es tu turno!' : 'Turno de $nombreTurno',
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartelBtn(String texto, {required String tipo, required Color color}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        final app = Provider.of<AppState>(context, listen: false);
        SocketService().enviarCartel(app.codigoSala, texto, tipo: tipo);
      },
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  // (opcional) tu scoreboard viejo, lo dejo por si lo usás en otro lado
  Widget _scoreboard({
    required List<Map<String, dynamic>> jugadores,
    required Map<String, int?> predicciones,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tablero',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...jugadores.map((j) {
            final id = (j['id'] ?? '').toString();
            final nombre = (j['nombre'] ?? '').toString();
            final puntos = (j['puntos'] as num?)?.toInt() ?? 0;
            final pred = predicciones[id];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Pred: ${pred ?? '—'}',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Pts: $puntos',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

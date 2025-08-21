// server/index.js
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const { createGameRoom, getGameRoom, eliminarSala, salas } = require('./game/GameManager');
const { logEvento, logSala, logJugador } = require('./logger');

const app = express();

// --- CORS (configurable por env) ---
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map(s => s.trim())
  : ['*'];

app.use(cors({ origin: allowedOrigins, credentials: true }));

// health & raíz
app.get('/', (_, res) => res.send('OK'));
app.get('/health', (_, res) => res.json({ ok: true }));

const server = http.createServer(app);
const io = new Server(server, {
  path: '/socket.io',
  transports: ['websocket', 'polling'],
  cors: {
    origin: allowedOrigins,
    methods: ['GET', 'POST'],
    credentials: true,
  },
});

// pequeño helper para armar snapshot de predicciones (completo)
function snapshotEstadoPredicciones(sala) {
  return sala.jugadores.map(j => ({
    id: j.id,
    nombre: j.nombre,
    puntos: j.puntos,
    prediccion: j.prediccion ?? null,
  }));
}

io.on('connection', (socket) => {
  logJugador(socket.id, '🔌 Conectado');

  // ─────────────────────────────────────
  // CREAR SALA
  // client: socket.emit('crear_sala', { nombreHost, maxJugadores })
  // ─────────────────────────────────────
  socket.on('crear_sala', ({ nombreHost, maxJugadores }) => {
    try {
      const sala = createGameRoom(socket.id, nombreHost, maxJugadores || 5);
      socket.join(sala.codigo);
      logSala(sala.codigo, `🆕 Sala creada por ${nombreHost}`);

      socket.emit('sala_creada', {
        codigo: sala.codigo,
        socketId: socket.id,
        estado: sala.getEstadoRonda(),
        esHost: true,
      });

      io.to(sala.codigo).emit('estado_jugadores', sala.getEstadoRonda().jugadores);
    } catch (err) {
      socket.emit('error_crear_sala', 'Error al crear la sala');
    }
  });

  // ─────────────────────────────────────
  // UNIRSE A SALA
  // client: socket.emit('unirse_sala', { codigo, nombre })
  // ─────────────────────────────────────
  socket.on('unirse_sala', ({ codigo, nombre }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return socket.emit('error_unirse_sala', 'Sala no encontrada');

    const resultado = sala.agregarJugador(socket.id, nombre);
    if (resultado === 'Sala llena') {
      return socket.emit('error_unirse_sala', 'La sala está llena');
    }

    socket.join(codigo);
    logSala(codigo, `➕ ${nombre} se unió`);

    socket.emit('sala_unida', {
      codigo,
      socketId: socket.id,
      estado: sala.getEstadoRonda(),
      esHost: false,
    });

    io.to(codigo).emit('estado_jugadores', sala.getEstadoRonda().jugadores);
  });

  // ─────────────────────────────────────
  // CHAT
  // ─────────────────────────────────────
  socket.on('enviar_mensaje_chat', ({ codigo, mensaje }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;
    const jugador = sala.getJugador(socket.id);

    io.to(codigo).emit('chat_mensaje', {
      socketId: socket.id,
      jugador: jugador?.nombre || 'Anónimo',
      mensaje,
    });
  });

  // ─────────────────────────────────────
  // ESTADO
  // ─────────────────────────────────────
  socket.on('pedir_estado', ({ codigo }) => {
    const sala = getGameRoom(codigo);
    if (sala) {
      socket.emit('estado_jugadores', sala.getEstadoRonda().jugadores);
    }
  });

  // ─────────────────────────────────────
  // INICIAR PARTIDA
  // ─────────────────────────────────────
  socket.on('iniciar_partida', ({ codigo }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;

    if (!sala.estaListoParaJugar()) {
      return socket.emit('error_iniciar_partida', 'Se necesitan al menos 2 jugadores');
    }

    if (!sala.esHost(socket.id)) {
      return socket.emit('error_iniciar_partida', 'Solo el host puede iniciar la partida');
    }

    sala.iniciarPartida();

    const jugadas = sala.getJugadasActuales();
    const estado = sala.getEstadoRonda();

    io.to(codigo).emit('iniciar_ronda', {
      estado,
      jugadas,
    });

    // primer turno de predicción
    const siguienteId = sala.getJugadorTurnoPrediccion?.();
    const total = sala.getCantidadCartasPorRonda();

    if (siguienteId) {
      const sig = sala.getJugador(siguienteId);
      // 🔔 todos saben quién predice
      io.to(codigo).emit('turno_prediccion', { id: siguienteId, nombre: sig?.nombre || '' });

      // 🔒 opciones al jugador objetivo
      const sumaPrevias = sala.jugadores
        .filter(j => j.id !== siguienteId && j.prediccion != null)
        .reduce((acc, j) => acc + j.prediccion, 0);

      const esUltimo = sala.dealerIndex === sala.jugadores.findIndex(j => j.id === siguienteId);
      const opciones = [];
      for (let i = 0; i <= total; i++) {
        if (esUltimo && sumaPrevias + i === total) continue;
        opciones.push(i);
      }

      io.to(siguienteId).emit('opciones_validas_prediccion', opciones);
      logSala(codigo, `🎯 Primer jugador en predecir: ${sig?.nombre ?? siguienteId}`);
    }

    logSala(codigo, `🎲 Ronda ${estado.ronda} iniciada`);
  });

  // ─────────────────────────────────────
  // PREDICCIÓN
  // ─────────────────────────────────────
  socket.on('enviar_prediccion', ({ codigo, cantidad }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;

    // adaptador de emisión para GameManager
    const emit = (event, data) => {
      if (event === 'turno_prediccion') {
        const sig = sala.getJugador(data);
        io.to(codigo).emit('turno_prediccion', { id: data, nombre: sig?.nombre || '' });
      } else if (event === 'predicciones_completas') {
        io.to(codigo).emit('predicciones_completas');
        // ⬇️ Arranca el turno de JUEGO (primera baza)
        const firstId = sala.getJugadorTurnoJuego?.();
        if (firstId) {
          const pj = sala.getJugador(firstId);
          io.to(codigo).emit('turno_jugar', { id: firstId, nombre: pj?.nombre || '' });
        }
      } else if (event === 'error_prediccion') {
        io.to(socket.id).emit('error_prediccion', data);
      } else if (event === 'opciones_validas_prediccion') {
        // data = { jugadorId, opciones }
        io.to(data.jugadorId).emit('opciones_validas_prediccion', data.opciones ?? []);
      }
    };

    const ok = sala.registrarPrediccion(socket.id, cantidad, emit);
    if (!ok) return; // Error ya emitido desde GameManager

    // broadcast estado de predicciones con info completa
    io.to(codigo).emit('estado_predicciones', snapshotEstadoPredicciones(sala));
  });

  // compat (si algún flujo manda este evento)
  socket.on('error_prediccion_invalida', (msg) => {
    socket.emit('error_prediccion', msg);
  });

  // ─────────────────────────────────────
  // JUGAR CARTA
  // ─────────────────────────────────────
  socket.on('jugar_carta', ({ codigo, carta }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;

    const jugadas = sala.jugarCarta(socket.id, carta);
    if (!jugadas) {
      io.to(socket.id).emit('error_jugada', 'No podés jugar esa carta ahora.');
      return;
    }

    io.to(codigo).emit('actualizar_tablero', jugadas);

    if (sala.manoTerminada()) {
      sala.evaluarMano();
      const resumen = sala.getResultadoMano();
      io.to(codigo).emit('fin_mano', resumen);

      if (sala.rondaTerminada()) {
        // ⬇️ SUMA puntos de la ronda y emite puntuaciones
        const detalle = sala.evaluarPredicciones();
        const puntajes = sala.getPuntajes();

        // Mantener compatibilidad: 'fin_ronda' sigue enviando SOLO la lista de puntajes
        io.to(codigo).emit('fin_ronda', puntajes);

        // Extra (opcional): detalle con delta/total por jugador
        io.to(codigo).emit('fin_ronda_detalle', { detalle, puntajes, ronda: sala.ronda });

        const ganador = sala.jugadorGanador();
        if (ganador) {
          io.to(codigo).emit('fin_partida', {
            ganador: { nombre: ganador.nombre, puntos: ganador.puntos },
          });
          eliminarSala(codigo);
        } else {
          sala.prepararSiguienteRonda();
          io.to(codigo).emit('iniciar_ronda', {
            estado: sala.getEstadoRonda(),
            jugadas: sala.getJugadasActuales(),
          });

          const siguienteId = sala.getJugadorTurnoPrediccion?.();
          if (siguienteId) {
            const sig = sala.getJugador(siguienteId);
            io.to(codigo).emit('turno_prediccion', { id: siguienteId, nombre: sig?.nombre || '' });

            const total = sala.getCantidadCartasPorRonda();
            const sumaPrevias = sala.jugadores
              .filter(j => j.id !== siguienteId && j.prediccion != null)
              .reduce((acc, j) => acc + j.prediccion, 0);
            const esUltimo = sala.dealerIndex === sala.jugadores.findIndex(j => j.id === siguienteId);
            const opciones = [];
            for (let i = 0; i <= total; i++) {
              if (esUltimo && sumaPrevias + i === total) continue;
              opciones.push(i);
            }
            io.to(siguienteId).emit('opciones_validas_prediccion', opciones);
          }
        }
      } else {
        // 🟢 La ronda sigue: el ganador de la baza lidera la siguiente.
        const idTurno = sala.getJugadorTurnoJuego?.();
        if (idTurno) {
          const pj = sala.getJugador(idTurno);
          io.to(codigo).emit('turno_jugar', { id: idTurno, nombre: pj?.nombre || '' });
        }
      }
    } else {
      // 🟢 La baza NO terminó: pasa el turno al siguiente jugador
      sala.avanzarTurnoJuego?.();
      const idTurno = sala.getJugadorTurnoJuego?.();
      if (idTurno) {
        const pj = sala.getJugador(idTurno);
        io.to(codigo).emit('turno_jugar', { id: idTurno, nombre: pj?.nombre || '' });
      }
    }
  });

  // ─────────────────────────────────────
  // SALIR DE SALA
  // ─────────────────────────────────────
  socket.on('salir_sala', ({ codigo }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;

    const eliminado = sala.eliminarJugador(socket.id);
    if (eliminado) {
      socket.leave(codigo);
      io.to(codigo).emit('estado_jugadores', sala.getJugadores());

      if (sala.jugadores.length === 0) {
        eliminarSala(codigo);
      }
    }
  });

  // ─────────────────────────────────────
  // DESCONECTAR
  // ─────────────────────────────────────
  socket.on('disconnect', () => {
    let codigoSala = null;
    let jugadorEliminado = null;

    for (const [codigo, sala] of Object.entries(salas)) {
      const index = sala.jugadores.findIndex(j => j.id === socket.id);
      if (index !== -1) {
        jugadorEliminado = sala.jugadores.splice(index, 1)[0];
        codigoSala = codigo;

        io.to(codigo).emit('estado_jugadores', sala.getJugadores());

        if (sala.jugadores.length === 0) {
          eliminarSala(codigo);
        }
        break;
      }
    }

    if (codigoSala && jugadorEliminado) {
      console.log(`🧹 Jugador ${jugadorEliminado.nombre} fue eliminado de sala ${codigoSala}`);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log('Listening on', PORT));

// server/index.js
// al tope del archivo:
const timersPrediccion = {}; // { [codigoSala]: NodeJS.Timeout }
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const { createGameRoom, getGameRoom, eliminarSala, salas } = require('./game/GameManager');
const { logEvento, logSala, logJugador, logError } = require('./logger');

const app = express();
app.use(cors());

// handy health check while debugging
app.get('/health', (_req, res) => res.send('ok'));

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

// helper: emite turno/opts y arma el timer
function emitirTurnoPrediccion(io, codigo, sala) {
  const jugadorTurno = sala.getJugadorTurnoPrediccion?.();
  if (!jugadorTurno) return;

  // opciones válidas para ese jugador
  const opciones = sala.opcionesValidasPrediccion?.(jugadorTurno.id) ?? [];

  // avisar a toda la sala de quién está de turno
  io.to(codigo).emit('turno_prediccion', { id: jugadorTurno.id, nombre: jugadorTurno.nombre });

  // mandar opciones SOLO al jugador de turno (o a todos si preferís)
  io.to(jugadorTurno.id).emit('opciones_validas_prediccion', opciones);

  // limpiar timer previo
  if (timersPrediccion[codigo]) clearTimeout(timersPrediccion[codigo]);

  // cronómetro 10s → autopredice primer opción válida (o 0)
  timersPrediccion[codigo] = setTimeout(() => {
    const opts = sala.opcionesValidasPrediccion?.(jugadorTurno.id) ?? [0];
    const auto = opts.includes(0) ? 0 : opts[0];

    const r = sala.registrarPrediccion?.(jugadorTurno.id, auto);
    io.to(jugadorTurno.id).emit('prediccion_auto', auto);
    io.to(codigo).emit('estado_predicciones', sala.getJugadores?.() ?? sala.jugadores ?? []);

    if (sala.todosPredijeron?.()) {
      // iniciar la fase de juego / siguiente paso de tu juego
      io.to(codigo).emit('predicciones_cerradas', sala.getJugadores?.() ?? []);
      // aquí arranca tu flujo de "jugar cartas" (si ya lo tienes, llámalo)
      // e.g., io.to(codigo).emit('turno_jugar', sala.getJugadorTurnoJugada());
    } else {
      emitirTurnoPrediccion(io, codigo, sala);
    }
  }, 10000); // 10 s
}

// small helper to safely run actions on a room
function withSala(codigo, socket, fn) {
  const sala = getGameRoom(codigo);
  if (!sala) {
    socket.emit('error_sala', 'La sala no existe.');
    return null;
  }
  try {
    return fn(sala);
  } catch (e) {
    logError(e?.stack || String(e));
    socket.emit('error_sala', 'Error interno del servidor.');
    return null;
  }
}

io.engine.on('connection_error', (err) => {
  console.error('engine connection_error:', {
    code: err.code,       // p.ej. 0
    message: err.message, // p.ej. "Session ID unknown"
    context: err.context, // headers, etc.
  });
});

io.on('connection', (socket) => {
  logEvento('conexion', { socketId: socket.id });

  // --- CREAR SALA ---
  socket.on('crear_sala', ({ nombreHost, maxJugadores = 5 } = {}) => {
    if (!nombreHost || typeof nombreHost !== 'string') {
      socket.emit('error_sala', 'Nombre del host inválido.');
      return;
    }
    const sala = createGameRoom(socket.id, nombreHost.trim(), Number(maxJugadores) || 5);
    socket.join(sala.codigo);

    logSala(sala.codigo, `Sala creada por ${nombreHost} (${socket.id})`);
    socket.emit('sala_creada', {
      codigo: sala.codigo,
      jugadores: sala.getJugadores(),
      estado: sala.getEstadoRonda?.() || null,
      esHost: true,
    });
    io.to(sala.codigo).emit('estado_jugadores', sala.getJugadores());
  });

  // --- UNIRSE A SALA ---
  socket.on('unirse_sala', ({ codigo, nombre }) => {
    withSala(codigo, socket, (sala) => {
      if (!nombre || typeof nombre !== 'string') {
        socket.emit('error_sala', 'Nombre inválido.');
        return;
      }
      if (sala.getJugadores().length >= (sala.maxJugadores || 5)) {
        socket.emit('error_sala', 'La sala está llena.');
        return;
      }

      sala.agregarJugador(socket.id, nombre.trim());
      socket.join(codigo);

      logSala(codigo, `Se unió ${nombre} (${socket.id})`);
      socket.emit('sala_unida', {
        codigo,
        jugadores: sala.getJugadores(),
        estado: sala.getEstadoRonda?.() || null,
        esHost: sala.esHost(socket.id),
      });
      io.to(codigo).emit('estado_jugadores', sala.getJugadores());
    });
  });

  // --- SALIR DE SALA (voluntario) ---
  socket.on('salir_sala', ({ codigo }) => {
    withSala(codigo, socket, (sala) => {
      const eliminado = sala.eliminarJugador(socket.id);
      socket.leave(codigo);
      if (eliminado) {
        logSala(codigo, `Salió ${eliminado.nombre} (${socket.id})`);
        if (sala.getJugadores().length === 0) {
          eliminarSala(codigo);
          logSala(codigo, 'Sala vacía eliminada');
        } else {
          io.to(codigo).emit('estado_jugadores', sala.getJugadores());
        }
      }
    });
  });

  // --- INICIAR PARTIDA ---
  socket.on('iniciar_partida', ({ codigo }) => {
    withSala(codigo, socket, (sala) => {
      if (!sala.esHost(socket.id)) {
        socket.emit('error_sala', 'Solo el host puede iniciar la partida.');
        return;
      }
      // crea ronda y reparte (como ya haces)
      sala.iniciarPartida?.();

      // avisa inicio de ronda + manos iniciales (tu payload unificado)
      io.to(codigo).emit('iniciar_ronda', {
        estado: sala.getEstadoRonda?.(),
        jugadasIniciales: sala.getJugadasActuales?.(),
      });

      // 👉 primer turno de predicción + opciones válidas
      const jt = sala.getJugadorTurnoPrediccion?.();
      if (jt) {
        io.to(codigo).emit('turno_prediccion', jt);
        const opts = sala.opcionesValidasPrediccion?.(jt.id) ?? [];
        io.to(jt.id).emit('opciones_validas_prediccion', opts);
      }

      // arranca la fase de predicción por turnos
      emitirTurnoPrediccion(io, codigo, sala);
    });
  });


  // --- PREDICCIÓN ---
  socket.on('enviar_prediccion', ({ codigo, cantidad }) => {
    withSala(codigo, socket, (sala) => {
      // puentea los emits internos del GameRoom hacia socket.io
      const ok = sala.registrarPrediccion(socket.id, cantidad, (ev, payload) => {
        switch (ev) {
          case 'error_prediccion':
            socket.emit('error_prediccion', payload);
            break;

          case 'estado_predicciones':
            io.to(codigo).emit('estado_predicciones', payload);
            break;

          case 'turno_prediccion': {
            const turno = payload; // { id, nombre }
            io.to(codigo).emit('turno_prediccion', turno);
            // 👉 opciones para el jugador de turno (¡en cada turno!)
            const opts = sala.opcionesValidasPrediccion?.(turno.id) ?? [];
            io.to(turno.id).emit('opciones_validas_prediccion', opts);
            break;
          }

          case 'opciones_validas_prediccion': {
            // compat: puede venir lista o {jugadorId, opciones}
            const opts = Array.isArray(payload) ? payload : payload?.opciones ?? [];
            const target = Array.isArray(payload) ? socket.id : (payload?.jugadorId ?? socket.id);
            io.to(target).emit('opciones_validas_prediccion', opts);
            break;
          }

          case 'predicciones_cerradas':
            io.to(codigo).emit('predicciones_cerradas', payload);

            // 👉 arranca fase de juego: líder es el que sigue al dealer
            sala.turnoActual = (sala.dealerIndex + 1) % sala.jugadores.length;
            const lider = sala.jugadores[sala.turnoActual];
            if (lider) {
              io.to(codigo).emit('turno_jugar', { id: lider.id, nombre: lider.nombre });
            }
            break;
        }
      });

      // Si no pudo registrar (p.ej. opción prohibida), volver a mandar opciones del jugador de turno
      if (!ok) {
        const turno = sala.getJugadorTurnoPrediccion?.();
        if (turno && turno.id) {
          const opts = sala.opcionesValidasPrediccion?.(turno.id) ?? [];
          io.to(turno.id).emit('opciones_validas_prediccion', opts);
        }
      }
    });
  });

  // --- JUGAR CARTA ---
  socket.on('jugar_carta', ({ codigo, carta }) => {
    withSala(codigo, socket, (sala) => {
      // 1) Validación de turno
      const idxJugador = sala.jugadores.findIndex((j) => j.id === socket.id);
      if (idxJugador === -1) return;

      const playsCount = sala.cartasEnJuego.length; // cuántos ya jugaron en esta mano
      const turnoIndexEsperado = (sala.turnoActual + playsCount) % sala.jugadores.length;
      if (idxJugador !== turnoIndexEsperado) {
        socket.emit('error_jugada', 'No podés jugar esa carta ahora.');
        return;
      }

      // 2) Registrar jugada
      const jugadas = sala.jugarCarta(socket.id, carta);
      if (!jugadas) {
        socket.emit('error_jugada', 'No podés jugar esa carta ahora.');
        return;
      }

      // Emití la mesa actual (las cartas jugadas en la mano)
      io.to(codigo).emit('actualizar_tablero', jugadas);

      // 3) ¿Se cerró la mano?
      if (sala.manoTerminada()) {
        // calcular ganador ANTES de evaluar (porque evaluar limpia cartasEnJuego)
        const jugadasMano = [...sala.cartasEnJuego];
        let ganadorEntrada = null;
        let maxNum = -Infinity;
        for (const entry of jugadasMano) {
          const num = Number(entry?.carta?.numero ?? -Infinity);
          if (num > maxNum) {
            maxNum = num;
            ganadorEntrada = entry;
          }
        }
        const ganadorId = ganadorEntrada?.jugador?.id;

        sala.evaluarMano();
        io.to(codigo).emit('fin_mano', sala.getResultadoMano());

        // el próximo líder de la mano es el ganador
        if (ganadorId) {
          const idxGanador = sala.jugadores.findIndex((j) => j.id === ganadorId);
          if (idxGanador >= 0) sala.turnoActual = idxGanador;
        }

        // 3.a) ¿Terminó la ronda?
        if (sala.rondaTerminada()) {
          sala.evaluarPredicciones();
          io.to(codigo).emit('fin_ronda', { puntajes: sala.getPuntajes() });

          // preparar siguiente ronda (volverá a fase de predicción)
          if (typeof sala.prepararSiguienteRonda === 'function') {
            sala.prepararSiguienteRonda();
            sala.iniciarRonda();
            io.to(codigo).emit('iniciar_ronda', {
              estado: sala.getEstadoRonda(),
              jugadasIniciales: sala.getJugadasActuales(),
            });

            const jugadorTurno = sala.getJugadorTurnoPrediccion?.();
            if (jugadorTurno) {
              io.to(codigo).emit('turno_prediccion', jugadorTurno);
            }
          }
          return;
        }

        // 3.b) Si no terminó la ronda, empieza una nueva mano → anunciar turno de jugar
        const lider = sala.jugadores[sala.turnoActual];
        if (lider) {
          io.to(codigo).emit('turno_jugar', { id: lider.id, nombre: lider.nombre });
        }
        return;
      }

      // 4) Mano en curso → siguiente turno según orden relativo al líder de la mano
      const nextIndex = (sala.turnoActual + sala.cartasEnJuego.length) % sala.jugadores.length;
      const prox = sala.jugadores[nextIndex];
      if (prox) {
        io.to(codigo).emit('turno_jugar', { id: prox.id, nombre: prox.nombre });
      }
    });
  });

  // --- CHAT ---
  socket.on('enviar_mensaje_chat', ({ codigo, mensaje }) => {
    withSala(codigo, socket, (sala) => {
      const jugador = sala.getJugador?.(socket.id);
      io.to(codigo).emit('chat_mensaje', {
        socketId: socket.id,
        jugador: jugador?.nombre || 'Anónimo',
        mensaje: String(mensaje ?? ''),
      });
    });
  });

  // --- ESTADO / SYNC ---
  socket.on('pedir_estado', ({ codigo }) => {
    withSala(codigo, socket, (sala) => {
      socket.emit('estado_jugadores', sala.getJugadores());
      if (sala.getEstadoRonda) socket.emit('estado_ronda', sala.getEstadoRonda());
    });
  });

  // --- DESCONECTAR ---
  socket.on('disconnect', (reason) => {
    logEvento('disconnect', { socketId: socket.id, reason });

    let codigoSala = null;
    let jugadorEliminado = null;

    for (const codigo of Object.keys(salas)) {
      const sala = salas[codigo];
      const eliminado = sala.eliminarJugador?.(socket.id);
      if (eliminado) {
        codigoSala = codigo;
        jugadorEliminado = eliminado;
        socket.leave(codigo);

        if (sala.getJugadores().length === 0) {
          eliminarSala(codigo);
          logSala(codigo, 'Sala vacía eliminada (disconnect)');
        } else {
          io.to(codigo).emit('estado_jugadores', sala.getJugadores());
        }
        break;
      }
    }

    if (codigoSala && jugadorEliminado) {
      logJugador(socket.id, `Desconectado y removido de sala ${codigoSala}`);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🛰️  Servidor escuchando en puerto ${PORT}`);
});

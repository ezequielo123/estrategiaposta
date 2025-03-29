const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const { createGameRoom, getGameRoom, eliminarSala } = require('./game/GameManager');
const { logEvento, logSala, logJugador } = require('./logger');

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

io.on('connection', (socket) => {
  logJugador(socket.id, '🔌 Conectado');

  // 🔹 CREAR SALA
  socket.on('crear_sala', ({ nombreJugador }) => {
    try {
      const sala = createGameRoom(socket.id, nombreJugador);
      socket.join(sala.codigo);
      logSala(sala.codigo, `🆕 Sala creada por ${nombreJugador}`);
  
      socket.emit('sala_creada', {
        codigo: sala.codigo,
        socketId: socket.id, // ✅ Nuevo
        estado: sala.getEstadoRonda()
      });
  
      io.to(sala.codigo).emit('estado_jugadores', sala.getEstadoRonda().jugadores);
    } catch (err) {
      socket.emit('error_crear_sala', 'Error al crear la sala');
    }
  });

  // 💬 Evento de chat por jugador
  socket.on('enviar_mensaje_chat', ({ codigo, mensaje }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;
  
    const jugador = sala.getJugador(socket.id);
  
    io.to(codigo).emit('chat_mensaje', {
      socketId: socket.id,
      jugador: jugador?.nombre || 'Anónimo',
      mensaje
    });
  });
    

  // 🔹 UNIRSE A SALA
  socket.on('unirse_sala', ({ codigo, nombreJugador }) => {
    const sala = getGameRoom(codigo);
    if (!sala) {
      return socket.emit('error_unirse_sala', 'Sala no encontrada');
    }
  
    sala.agregarJugador(socket.id, nombreJugador);
    socket.join(codigo);
    logSala(codigo, `➕ ${nombreJugador} se unió`);
  
    socket.emit('sala_unida', {
      codigo,
      socketId: socket.id, // ✅ NUEVO
      estado: sala.getEstadoRonda()
    });
  
    io.to(codigo).emit('estado_jugadores', sala.getEstadoRonda().jugadores);
  });
  

  // 🔹 PEDIR ESTADO JUGADORES
  socket.on('pedir_estado', ({ codigo }) => {
    const sala = getGameRoom(codigo);
    if (sala) {
      socket.emit('estado_jugadores', sala.getEstadoRonda().jugadores);
    }
  });

  // 🔹 INICIAR PARTIDA
  socket.on('iniciar_partida', ({ codigo }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;
  
    sala.iniciarPartida();
  
    const jugadas = sala.getJugadasActuales();
    const estado = sala.getEstadoRonda();
    
    console.log('🛰️ Emitiendo iniciar_ronda');
    console.log('Estado:', estado);
    console.log('Jugadas:', JSON.stringify(jugadas, null, 2));

    io.to(codigo).emit('iniciar_ronda', {
      estado,
      jugadas
    });
  
    logSala(codigo, `🎲 Ronda ${estado.ronda} iniciada`);
  });

  socket.on('mensaje_sala', ({ codigo, jugador, mensaje }) => {
    io.to(codigo).emit('mensaje_sala', { jugador, mensaje });
  });
  

  // 🔹 ENVIAR PREDICCIÓN
  socket.on('enviar_prediccion', ({ codigo, cantidad }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;

    sala.registrarPrediccion(socket.id, cantidad);
    logSala(codigo, `📊 Predicción recibida`);

    if (sala.todasLasPrediccionesHechas()) {
      io.to(codigo).emit('predicciones_completas');
    }
  });

  // 🔹 JUGAR CARTA
  socket.on('jugar_carta', ({ codigo, carta }) => {
    const sala = getGameRoom(codigo);
    if (!sala) return;

    const jugadas = sala.jugarCarta(socket.id, carta);
    if (jugadas) {
      io.to(codigo).emit('actualizar_tablero', jugadas);

      if (sala.manoTerminada()) {
        sala.evaluarMano();
        const resumen = sala.getResultadoMano();
        io.to(codigo).emit('fin_mano', resumen);

        if (sala.rondaTerminada()) {
          sala.evaluarPredicciones();
          const puntajes = sala.getPuntajes();
          io.to(codigo).emit('fin_ronda', puntajes);

          const ganador = sala.jugadorGanador();
          if (ganador) {
            io.to(codigo).emit('fin_partida', {
              ganador: {
                nombre: ganador.nombre,
                puntos: ganador.puntos, // ✅ necesario para Firebase
              }
            });
            eliminarSala(codigo);
          } else {
            sala.prepararSiguienteRonda();
            const nuevaMano = sala.getJugadasActuales();
            io.to(codigo).emit('iniciar_ronda', nuevaMano);
          }
        }
      }
    }
  });

  // 🔹 DESCONECTAR
  socket.on('disconnect', () => {
    console.log(`🔌 Jugador desconectado: ${socket.id}`);
  
    // Buscar en qué sala estaba
    let codigoSala = null;
    let jugadorEliminado = null;
  
    for (const [codigo, sala] of Object.entries(salas)) {
      const index = sala.jugadores.findIndex(j => j.id === socket.id);
      if (index !== -1) {
        jugadorEliminado = sala.jugadores.splice(index, 1)[0];
        codigoSala = codigo;
  
        // Notificar nueva lista de jugadores
        io.to(codigo).emit('estado_jugadores', sala.getJugadores());
  
        // Eliminar sala si queda vacía
        if (sala.jugadores.length === 0) {
          delete salas[codigo];
          console.log(`💥 Sala ${codigo} eliminada (vacía)`);
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
server.listen(PORT, () => {
  console.log(`🛰️  Servidor escuchando en puerto ${PORT}`);
});

// server/game/GameManager.js
const Player = require('./Player');
const { crearBaraja, mezclar } = require('../utils/Deck');

// Mapa en memoria: codigoSala -> GameRoom
const salas = {};

function generarCodigoSala() {
  return Math.random().toString(36).substr(2, 6).toUpperCase();
}

class GameRoom {
  constructor(idHost, nombreHost, maxJugadores = 5) {
    this.codigo = generarCodigoSala();
    this.jugadores = [new Player(idHost, nombreHost)];
    this.hostId = idHost;
    this.maxJugadores = maxJugadores;

    // Estado de la partida
    this.turnoActual = 0;
    this.baraja = [];
    this.cartasEnJuego = []; // [{ jugador, carta }]
    this.ronda = 0;

    // Patrón 1-3-5-7-5-3-1
    this.patronCartas = [1, 3, 5, 7, 5, 3, 1];

    // dealerIndex: quién reparte (es el ÚLTIMO en predecir)
    this.dealerIndex = 0;

    // índice del jugador que debe predecir ahora (va hacia atrás y termina en dealer)
    this.turnoPrediccionIndex = 0;
  }

  // --- Gestión de jugadores ---
  agregarJugador(id, nombre) {
    if (this.jugadores.length >= this.maxJugadores) return 'Sala llena';
    const yaExiste = this.jugadores.find((j) => j.id === id);
    if (!yaExiste) this.jugadores.push(new Player(id, nombre));
    return 'OK';
  }

  eliminarJugador(idJugador) {
    const index = this.jugadores.findIndex((j) => j.id === idJugador);
    if (index === -1) return null;
    const eliminado = this.jugadores.splice(index, 1)[0];

    // Ajustar índices si el eliminado estaba “antes” de los punteros
    if (this.jugadores.length > 0) {
      if (index <= this.dealerIndex) {
        this.dealerIndex = (this.dealerIndex - 1 + this.jugadores.length) % this.jugadores.length;
      }
      if (index <= this.turnoPrediccionIndex) {
        this.turnoPrediccionIndex =
          (this.turnoPrediccionIndex - 1 + this.jugadores.length) % this.jugadores.length;
      }
    } else {
      this.dealerIndex = 0;
      this.turnoPrediccionIndex = 0;
    }

    return eliminado;
  }

  esHost(id) { return this.hostId === id; }

  getJugador(id) { return this.jugadores.find((j) => j.id === id); }

  getJugadores() {
    // incluye prediccion para que el cliente pueda pintar el estado de la fase
    return this.jugadores.map((j) => ({
      id: j.id,
      nombre: j.nombre,
      puntos: j.puntos,
      prediccion: j.prediccion ?? null,
      manosGanadas: j.manosGanadas ?? 0,
    }));
  }

  getPuntajes() {
    // útil para 'fin_ronda'
    return this.jugadores.map((j) => ({ nombre: j.nombre, puntos: j.puntos }));
  }

  // --- Rondas ---
  getCantidadCartasPorRonda() {
    return this.patronCartas[(this.ronda - 1) % this.patronCartas.length];
  }

  iniciarPartida() {
    this.ronda = 1;
    this.iniciarRonda();
  }

  iniciarRonda() {
    this.cartasEnJuego = [];
    this.baraja = mezclar(crearBaraja());

    // al iniciar la ronda, predice primero el jugador anterior al dealer;
    // la predicción avanza hacia atrás y el ÚLTIMO es el dealer
    if (this.jugadores.length > 0) {
      this.turnoPrediccionIndex =
        (this.dealerIndex - 1 + this.jugadores.length) % this.jugadores.length;
    } else {
      this.turnoPrediccionIndex = 0;
    }

    const numCartas = this.getCantidadCartasPorRonda();
    this.jugadores.forEach((j) => j.resetearParaNuevaRonda());

    // repartir numCartas a cada jugador
    for (let i = 0; i < numCartas; i++) {
      this.jugadores.forEach((j) => {
        const carta = this.baraja.pop();
        if (carta) j.mano.push(carta);
      });
    }

    this.turnoActual = 0;
  }

  // --- Predicciones ---
  getJugadorTurnoPrediccion() {
    const j = this.jugadores[this.turnoPrediccionIndex];
    return j ? { id: j.id, nombre: j.nombre } : null;
  }

  getSumaPredicciones() {
    return this.jugadores.reduce(
      (acc, j) => acc + (typeof j.prediccion === 'number' ? j.prediccion : 0),
      0
    );
  }

  opcionesValidasPrediccion(idJugador) {
    const total = this.getCantidadCartasPorRonda();
    let opts = Array.from({ length: total + 1 }, (_, i) => i);

    // es último si el índice de turno está en el dealer y el jugador coincide
    const esUltimo =
      this.turnoPrediccionIndex === this.dealerIndex &&
      this.jugadores[this.turnoPrediccionIndex]?.id === idJugador;

    if (!esUltimo) return opts;

    const sumaPrevias = this.jugadores
      .filter((j) => j.id !== idJugador && j.prediccion != null)
      .reduce((acc, j) => acc + j.prediccion, 0);

    const prohibida = this.getCantidadCartasPorRonda() - sumaPrevias;
    return opts.filter((v) => v !== prohibida);
  }

  todosPredijeron() {
    return this.jugadores.every((j) => typeof j.prediccion === 'number');
  }

  registrarPrediccion(idJugador, cantidad, emit /* (event, data) => void */) {
    const turno = this.getJugadorTurnoPrediccion();
    if (!turno || idJugador !== turno.id) {
      emit?.('error_prediccion', 'No es tu turno para predecir.');
      return false;
    }

    const total = this.getCantidadCartasPorRonda();
    const val = Number(cantidad);
    if (!Number.isInteger(val) || val < 0 || val > total) {
      emit?.('error_prediccion', 'Cantidad inválida.');
      return false;
    }

    const opciones = this.opcionesValidasPrediccion(idJugador);
    if (!opciones.includes(val)) {
      emit?.('error_prediccion', 'No podés elegir esa cantidad, igualaría el total de manos.');
      // Compatibilidad: enviamos opciones en dos formatos
      emit?.('opciones_validas_prediccion', opciones); // ← lista (lo que consume el cliente)
      emit?.('opciones_validas_prediccion_detalle', { jugadorId: idJugador, opciones }); // ← opcional
      return false;
    }

    const jugador = this.getJugador(idJugador);
    if (!jugador) return false;

    jugador.prediccion = val;

    // avisar estado acumulado (ahora getJugadores() incluye 'prediccion')
    emit?.('estado_predicciones', this.getJugadores());

    // ¿Era el último (dealer)?
    const esUltimo = this.turnoPrediccionIndex === this.dealerIndex;
    if (esUltimo) {
      emit?.('predicciones_cerradas', this.getJugadores());
      return true;
    }

    // avanzar al jugador anterior (orden inverso) y notificar turno
    this.turnoPrediccionIndex =
      (this.turnoPrediccionIndex - 1 + this.jugadores.length) % this.jugadores.length;

    const siguiente = this.getJugadorTurnoPrediccion();
    emit?.('turno_prediccion', siguiente);

    // si el siguiente es el dealer, enviarle sus opciones válidas (lista + detalle)
    if (this.turnoPrediccionIndex === this.dealerIndex && siguiente) {
      const optsUltimo = this.opcionesValidasPrediccion(siguiente.id);
      emit?.('opciones_validas_prediccion', optsUltimo);
      emit?.('opciones_validas_prediccion_detalle', { jugadorId: siguiente.id, opciones: optsUltimo });
    }

    return true;
  }

  // --- Juego de cartas ---
  jugarCarta(idJugador, carta) {
    const jugador = this.getJugador(idJugador);
    if (!jugador) return null;

    // evitar doble jugada del mismo jugador en la mano
    if (this.cartasEnJuego.find((j) => j.jugador.id === idJugador)) return null;

    const cartaJug = jugador.jugarCarta(carta);
    if (!cartaJug) return null;

    this.cartasEnJuego.push({ jugador, carta: cartaJug });
    return this.cartasEnJuego; // el servidor emite este array en 'actualizar_tablero'
  }

  manoTerminada() {
    return this.cartasEnJuego.length === this.jugadores.length;
  }

  evaluarMano() {
    // Regla simple: gana la carta de mayor número (sin palo triunfo)
    let max = -1;
    let ganador = null;

    this.cartasEnJuego.forEach(({ jugador, carta }) => {
      if (carta.numero > max) {
        max = carta.numero;
        ganador = jugador;
      }
    });

    if (ganador) ganador.manosGanadas++;
    this.cartasEnJuego = [];
  }

  rondaTerminada() {
    return this.jugadores.every((j) => j.mano.length === 0);
  }

  evaluarPredicciones() {
    this.jugadores.forEach((j) => {
      if (j.prediccion === j.manosGanadas) {
        j.puntos += 5 + j.manosGanadas;
      }
    });
  }

  prepararSiguienteRonda() {
    this.ronda++;
    this.dealerIndex = (this.dealerIndex + 1) % this.jugadores.length;
    this.iniciarRonda();
  }

  // Indica si la partida terminó luego de evaluar una ronda
  jugadorGanador() {
    const maxRondas = this.patronCartas.length;
    // Al terminar la ÚLTIMA ronda, this.ronda === maxRondas
    if (this.ronda >= maxRondas) {
      return this.jugadores.reduce(
        (max, j) => (j.puntos > max.puntos ? j : max),
        this.jugadores[0]
      );
    }
    return null;
  }

  // --- Estado para el cliente ---
  getEstadoRonda() {
    return {
      ronda: this.ronda,
      numCartas: this.getCantidadCartasPorRonda(),
      jugadores: this.getJugadores(),
      dealerId: this.jugadores[this.dealerIndex]?.id,
      // El último en predecir es el dealer (lo usa la UI para bloquear opciones)
      ultimoJugadorPrediccionId: this.jugadores[this.dealerIndex]?.id,
    };
  }

  // ⚠️ Nombre histórico: se usa al iniciar la ronda para enviar la mano completa
  // a cada jugador en el evento 'iniciar_ronda'. Mantener forma:
  // [{ jugador: {id, nombre}, mano: [{numero, palo}, ...] }]
  getJugadasActuales() {
    return this.jugadores.map((j) => ({
      jugador: { id: j.id, nombre: j.nombre },
      mano: j.mano,
    }));
  }

  getResultadoMano() {
    return this.jugadores.map((j) => ({
      nombre: j.nombre,
      manosGanadas: j.manosGanadas,
      prediccion: j.prediccion,
      acerto: j.prediccion === j.manosGanadas,
      puntosGanados: j.prediccion === j.manosGanadas ? 5 + j.manosGanadas : 0,
    }));
  }

  getManoJugador(id) {
    const j = this.getJugador(id);
    return j ? j.mano : [];
  }

  estaListoParaJugar() {
    return this.jugadores.length >= 2;
  }
}

// --- API del módulo ---
function createGameRoom(idHost, nombreHost, maxJugadores = 5) {
  const room = new GameRoom(idHost, nombreHost, maxJugadores);
  salas[room.codigo] = room;
  return room;
}
function getGameRoom(codigo) { return salas[codigo]; }
function eliminarSala(codigo) { delete salas[codigo]; }

module.exports = {
  createGameRoom,
  getGameRoom,
  eliminarSala,
  salas,
  GameRoom, // (opcional) útil para tests
};

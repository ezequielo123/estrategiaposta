const Player = require('./Player');
const { crearBaraja, mezclar } = require('../utils/Deck');

const salas = {};

function generarCodigoSala() {
  return Math.random().toString(36).substr(2, 6).toUpperCase();
}

class GameRoom {
  constructor(idHost, nombreHost) {
    this.codigo = generarCodigoSala();
    this.jugadores = [new Player(idHost, nombreHost)];
    this.turnoActual = 0;
    this.baraja = [];
    this.cartasEnJuego = [];
    this.ronda = 0;
    this.patronCartas = [1, 3, 5, 7, 5, 3, 1];
  }

  agregarJugador(id, nombre) {
    if (this.jugadores.length >= 5) return 'Sala llena';
    const yaExiste = this.jugadores.find((j) => j.id === id);
    if (!yaExiste) this.jugadores.push(new Player(id, nombre));
  }

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
    const numCartas = this.getCantidadCartasPorRonda();
    this.jugadores.forEach((j) => j.resetearParaNuevaRonda());

    for (let i = 0; i < numCartas; i++) {
      this.jugadores.forEach((j) => {
        j.mano.push(this.baraja.pop());
      });
    }

    this.turnoActual = 0;
  }

  registrarPrediccion(idJugador, cantidad) {
    const jugador = this.jugadores.find((j) => j.id === idJugador);
    if (jugador) jugador.prediccion = cantidad;
  }

  todasLasPrediccionesHechas() {
    return (
      this.jugadores.every((j) => j.prediccion !== null) &&
      this.validarPredicciones()
    );
  }

  validarPredicciones() {
    const total = this.jugadores.reduce((acc, j) => acc + j.prediccion, 0);
    return total !== this.getCantidadCartasPorRonda();
  }

  jugarCarta(idJugador, carta) {
    const jugador = this.jugadores.find((j) => j.id === idJugador);
    if (!jugador) return null;

    const cartaJug = jugador.jugarCarta(carta);
    if (!cartaJug) return null;

    this.cartasEnJuego.push({ jugador, carta: cartaJug });
    return this.cartasEnJuego;
  }

  manoTerminada() {
    return this.cartasEnJuego.length === this.jugadores.length;
  }

  evaluarMano() {
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
        j.puntos += j.manosGanadas * 5;
      } else {
        j.puntos += j.manosGanadas * 1;
      }
    });
  }

  prepararSiguienteRonda() {
    this.ronda++;
    this.iniciarRonda();
  }

  jugadorGanador() {
    return this.jugadores.find((j) => j.puntos >= 100);
  }

  getJugadores() {
    return this.jugadores.map((j) => ({
      id: j.id,
      nombre: j.nombre,
      puntos: j.puntos,
    }));
  }

  getEstadoRonda() {
    return {
      ronda: this.ronda,
      numCartas: this.getCantidadCartasPorRonda(),
      jugadores: this.getJugadores(),
    };
  }

  getJugadasActuales() {
    return this.jugadores.map((j) => ({
      jugador: {
        id: j.id,
        nombre: j.nombre,
      },
      mano: j.mano,
    }));
  }

  getResultadoMano() {
    return this.jugadores.map((j) => ({
      nombre: j.nombre,
      manosGanadas: j.manosGanadas,
    }));
  }

  getPuntajes() {
    return this.getJugadores();
  }

  getJugador(id) {
    return this.jugadores.find((j) => j.id === id);
  }

  getManoJugador(id) {
    const j = this.getJugador(id);
    return j ? j.mano : [];
  }

  estaListoParaJugar() {
    return this.jugadores.length >= 2;
  }
}

// Exports
function createGameRoom(idHost, nombreHost) {
  const room = new GameRoom(idHost, nombreHost);
  salas[room.codigo] = room;
  return room;
}

function getGameRoom(codigo) {
  return salas[codigo];
}

function eliminarSala(codigo) {
  delete salas[codigo];
}

module.exports = {
  createGameRoom,
  getGameRoom,
  eliminarSala,
  salas, // 🆕 necesario para desconexión
};

const Player = require('./Player');
const { crearBaraja, mezclar } = require('../utils/Deck');

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

    // Estado de ronda/partida
    this.ronda = 0;
    this.patronCartas = [1, 3, 5, 7, 5, 3, 1];
    this.dealerIndex = 0;

    // Predicciones
    this.turnoPrediccionIndex = 0;

    // Juego de bazas
    this.baraja = [];
    this.cartasEnJuego = [];
    this.turnoJuegoLiderIndex = 0; // quién lidera la baza actual
    this.turnoJuegoIndex = 0;      // a quién le toca jugar ahora
  }

  agregarJugador(id, nombre) {
    if (this.jugadores.length >= this.maxJugadores) return 'Sala llena';
    const yaExiste = this.jugadores.find((j) => j.id === id);
    if (!yaExiste) this.jugadores.push(new Player(id, nombre));
  }

  esHost(id) {
    return this.hostId === id;
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

    // El orden de predicción va "hacia atrás" desde el jugador a la izquierda del dealer,
    // por eso arrancamos en dealer - 1 (mod n).
    this.turnoPrediccionIndex =
      (this.dealerIndex - 1 + this.jugadores.length) % this.jugadores.length;

    // Reparto
    const numCartas = this.getCantidadCartasPorRonda();
    this.jugadores.forEach((j) => j.resetearParaNuevaRonda());
    for (let i = 0; i < numCartas; i++) {
      this.jugadores.forEach((j) => {
        const carta = this.baraja.pop();
        if (carta) j.mano.push(carta);
      });
    }

    // El que empieza a JUGAR la primera baza de la ronda es el de la izquierda del dealer
    this.turnoJuegoLiderIndex = (this.dealerIndex + 1) % this.jugadores.length;
    this.turnoJuegoIndex = this.turnoJuegoLiderIndex;
  }

  // ——— Turno de JUEGO ———
  getJugadorTurnoJuego() {
    return this.jugadores[this.turnoJuegoIndex]?.id;
  }
  avanzarTurnoJuego() {
    this.turnoJuegoIndex = (this.turnoJuegoIndex + 1) % this.jugadores.length;
  }

  // ——— Turno de PREDICCIÓN ———
  getJugadorTurnoPrediccion() {
    return this.jugadores[this.turnoPrediccionIndex]?.id;
  }

  registrarPrediccion(idJugador, cantidad, emit) {
    const jugadorEsperado = this.getJugadorTurnoPrediccion();
    if (idJugador !== jugadorEsperado) return false;

    const jugador = this.getJugador(idJugador);
    if (!jugador) return false;

    const total = this.getCantidadCartasPorRonda();
    const esUltimo = this.turnoPrediccionIndex === this.dealerIndex;

    const sumaPredichas = this.jugadores
      .filter((j) => j.prediccion != null && j.id !== idJugador)
      .reduce((acc, j) => acc + j.prediccion, 0);

    // ❌ Regla especial para el último jugador
    if (esUltimo && sumaPredichas + cantidad === total) {
      emit(
        'error_prediccion',
        'No podés elegir esa cantidad, haría que la suma sea igual al total de manos.'
      );

      const opcionesValidas = [];
      for (let i = 0; i <= total; i++) {
        if (sumaPredichas + i !== total) opcionesValidas.push(i);
      }

      emit('opciones_validas_prediccion', {
        jugadorId: idJugador,
        opciones: opcionesValidas,
      });

      return false;
    }

    // ✅ Guardar predicción
    jugador.prediccion = cantidad;

    if (esUltimo) {
      emit('predicciones_completas');
    } else {
      // Avanza hacia el jugador anterior en el orden
      this.turnoPrediccionIndex =
        (this.turnoPrediccionIndex - 1 + this.jugadores.length) %
        this.jugadores.length;

      const siguienteJugador = this.getJugadorTurnoPrediccion();
      emit('turno_prediccion', siguienteJugador);

      // Solo si el que viene ahora es el último, mandamos sus opciones válidas
      if (this.turnoPrediccionIndex === this.dealerIndex) {
        const sumaSinUltimo = this.jugadores
          .filter((j) => j.id !== siguienteJugador && j.prediccion != null)
          .reduce((acc, j) => acc + j.prediccion, 0);

        const opciones = [];
        for (let i = 0; i <= total; i++) {
          if (sumaSinUltimo + i !== total) opciones.push(i);
        }

        emit('opciones_validas_prediccion', {
          jugadorId: siguienteJugador,
          opciones,
        });
      }
    }

    return true;
  }

  jugarCarta(idJugador, carta) {
    // Solo puede jugar el que está en turno
    if (idJugador !== this.getJugadorTurnoJuego()) return null;

    const jugador = this.getJugador(idJugador);
    if (!jugador) return null;

    const yaJugó = this.cartasEnJuego.find((j) => j.jugador.id === idJugador);
    if (yaJugó) return null;

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

    // ⚠️ Ajustá aquí si hay palo/triunfo. Por ahora: gana número más alto.
    this.cartasEnJuego.forEach(({ jugador, carta }) => {
      if (carta.numero > max) {
        max = carta.numero;
        ganador = jugador;
      }
    });

    if (ganador) {
      ganador.manosGanadas++; // ✅ sumar UNA sola vez
      // El ganador lidera la PRÓXIMA baza
      this.turnoJuegoLiderIndex = this.jugadores.findIndex(
        (j) => j.id === ganador.id
      );
      this.turnoJuegoIndex = this.turnoJuegoLiderIndex;
    }

    // limpiar mesa
    this.cartasEnJuego = [];
  }

  rondaTerminada() {
    return this.jugadores.every((j) => j.mano.length === 0);
  }

  // ⚖️ Puntuación de la ronda
  evaluarPredicciones() {
    // Regla usada en tu UI: acierto => 5 + manosGanadas; error => 0 (no suma).
    // Si quisieras penalizar el error, cambia delta cuando !acierto.
    const resumen = this.jugadores.map((j) => {
      const acierto = j.prediccion === j.manosGanadas;
      const delta = acierto ? 5 + j.manosGanadas : 0;

      j.puntos += delta; // 👈 SUMA real al total acumulado

      return {
        id: j.id,
        nombre: j.nombre,
        prediccion: j.prediccion ?? 0,
        ganadas: j.manosGanadas,
        acierto,
        delta,
        total: j.puntos,
      };
    });

    return resumen;
  }

  prepararSiguienteRonda() {
    this.ronda++;
    this.dealerIndex = (this.dealerIndex + 1) % this.jugadores.length;
    this.iniciarRonda();
  }

  jugadorGanador() {
    // Gana el primero que alcanza 101 puntos (o más)
    const ganador = this.jugadores.find(j => (j.puntos ?? 0) >= 101);
    return ganador || null;
  }

  eliminarJugador(idJugador) {
    const index = this.jugadores.findIndex((j) => j.id === idJugador);
    if (index !== -1) {
      return this.jugadores.splice(index, 1)[0];
    }
    return null;
  }

  getJugadores() {
    return this.jugadores.map((j) => ({
      id: j.id,
      nombre: j.nombre,
      puntos: j.puntos,
    }));
  }

  getEstadoRonda() {
    const ultimoIndex = (this.dealerIndex + 1) % this.jugadores.length;
    return {
      ronda: this.ronda,
      numCartas: this.getCantidadCartasPorRonda(),
      jugadores: this.getJugadores(), // incluye puntos
      dealerId: this.jugadores[this.dealerIndex].id,
      ultimoJugadorPrediccionId: this.jugadores[ultimoIndex].id,
    };
  }

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
      acierto: j.prediccion === j.manosGanadas,
      puntosGanados: j.prediccion === j.manosGanadas ? 5 + j.manosGanadas : 0,
    }));
  }

  getPuntajes() {
    return this.getJugadores(); // {id, nombre, puntos}
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

function createGameRoom(idHost, nombreHost, maxJugadores = 5) {
  const room = new GameRoom(idHost, nombreHost, maxJugadores);
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
  salas,
};

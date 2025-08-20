// server/game/Player.js
class Player {
  constructor(id, nombre) {
    this.id = id;
    this.nombre = nombre;
    this.mano = [];        // [{ numero, palo }]
    this.prediccion = null;
    this.manosGanadas = 0;
    this.puntos = 0;
  }

  resetearParaNuevaRonda() {
    this.mano = [];
    this.prediccion = null;
    this.manosGanadas = 0;
  }

  jugarCarta(cartaData) {
    if (!cartaData || typeof cartaData.numero !== 'number' || typeof cartaData.palo !== 'string') {
      // Silencioso para producción; descomenta si necesitás diagnosticar:
      // console.warn(`[Player] Carta inválida de ${this.nombre}`, cartaData);
      return null;
    }
    const idx = this.mano.findIndex(c => c.numero === cartaData.numero && c.palo === cartaData.palo);
    if (idx === -1) return null;

    const carta = this.mano[idx];
    this.mano.splice(idx, 1);
    return carta;
  }
}

module.exports = Player;

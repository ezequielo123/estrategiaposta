class Player {
    constructor(id, nombre) {
      this.id = id;
      this.nombre = nombre;
      this.mano = []; // Array de cartas: { numero, palo }
      this.prediccion = null;
      this.manosGanadas = 0;
      this.puntos = 0;
    }
  
    /**
     * Reinicia datos del jugador al comenzar una nueva ronda
     */
    resetearParaNuevaRonda() {
      this.mano = [];
      this.prediccion = null;
      this.manosGanadas = 0;
    }
  
    /**
     * Intenta jugar una carta específica desde la mano del jugador.
     * Devuelve la carta si fue jugada, o null si no existía.
     */
    jugarCarta(cartaData) {
      if (!cartaData || typeof cartaData.numero !== 'number' || typeof cartaData.palo !== 'string') {
        console.warn(`[Player] Carta inválida recibida por ${this.nombre}`);
        return null;
      }
  
      const index = this.mano.findIndex(
        c => c.numero === cartaData.numero && c.palo === cartaData.palo
      );
  
      if (index === -1) return null;
  
      const carta = this.mano[index];
      this.mano.splice(index, 1);
      return carta;
    }
  }
  
  module.exports = Player;
  
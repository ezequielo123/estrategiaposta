class Player {
    constructor(id, nombre) {
      this.id = id;
      this.nombre = nombre;
      this.mano = [];
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
  
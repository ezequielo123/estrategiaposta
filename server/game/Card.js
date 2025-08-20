class Card {
    constructor(palo, numero) {
      this.palo = palo;
      this.numero = numero;
    }
  
    getValor() {
      return this.numero;
    }
  
    toString() {
        return `${this.numero} de ${this.palo}`;
    }
  }
  
  module.exports = Card;
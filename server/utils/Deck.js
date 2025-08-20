const PALOS = ['oros', 'copas', 'espadas', 'bastos'];
const NUMEROS = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

function crearBaraja() {
  const baraja = [];

  for (const palo of PALOS) {
    for (const numero of NUMEROS) {
      baraja.push({ numero, palo });
    }
  }

  return baraja;
}

function mezclar(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

module.exports = {
  crearBaraja,
  mezclar,
};

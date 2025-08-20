// server/utils/Deck.js
const PALOS = Object.freeze(['oros', 'copas', 'espadas', 'bastos']);
const NUMEROS = Object.freeze([1, 2, 3, 4, 5, 6, 7, 10, 11, 12]);

function crearBaraja() {
  const baraja = [];
  for (const palo of PALOS) {
    for (const numero of NUMEROS) {
      baraja.push({ numero, palo });
    }
  }
  return baraja; // 40 cartas
}

/**
 * Fisher–Yates shuffle.
 * Pass a custom RNG for deterministic tests (e.g., () => 0.42).
 */
function mezclar(array, rng = Math.random) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

module.exports = {
  crearBaraja,
  mezclar,
  PALOS,     // extra export (optional to use)
  NUMEROS,   // extra export (optional to use)
};

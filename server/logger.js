const chalk = require('chalk');

function logJugador(id, mensaje) {
  console.log(chalk.cyan(`[Jugador ${id}] → ${mensaje}`));
}

function logSala(codigo, mensaje) {
  console.log(chalk.magenta(`[Sala ${codigo}] 🏠 → ${mensaje}`));
}

function logEvento(nombre, data = null) {
  console.log(chalk.green(`[Evento] ${nombre}`));
  if (data) console.log(chalk.gray(JSON.stringify(data, null, 2)));
}

function logError(mensaje) {
  console.log(chalk.red(`[ERROR] ${mensaje}`));
}

module.exports = {
  logJugador,
  logSala,
  logEvento,
  logError,
};

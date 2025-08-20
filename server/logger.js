// server/logger.js
let chalk = null;
try { chalk = require('chalk'); } catch (_) {}

const useChalk =
  chalk && typeof chalk.gray === 'function' ? chalk :
  chalk && chalk.default && typeof chalk.default.gray === 'function' ? chalk.default :
  null;

const C = {
  gray:   (s) => useChalk ? useChalk.gray(s)   : s,
  magenta:(s) => useChalk ? useChalk.magenta(s): s,
  green:  (s) => useChalk ? useChalk.green(s)  : s,
  cyan:   (s) => useChalk ? useChalk.cyan(s)   : s,
  red:    (s) => useChalk ? useChalk.red(s)    : s,
  white:  (s) => useChalk ? useChalk.white(s)  : s,
};

const ts = () => new Date().toISOString();

function logEvento(tipo, data) {
  console.log(C.gray(`[${ts()}]`), C.magenta('🛰️ evento:'), C.white(tipo), data ?? '');
}
function logSala(codigo, msg) {
  console.log(C.gray(`[${ts()}]`), C.green(`🏷️ sala:${codigo}`), C.white(msg ?? ''));
}
function logJugador(id, msg) {
  console.log(C.gray(`[${ts()}]`), C.cyan(`👤 jugador:${id}`), C.white(msg ?? ''));
}
function logError(err) {
  console.error(C.gray(`[${ts()}]`), C.red('❌ error:'), err);
}

module.exports = { logEvento, logSala, logJugador, logError };

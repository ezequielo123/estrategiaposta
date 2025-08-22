// server/storage/firestore.js
const admin = require('firebase-admin');

// --- Init credenciales (ENV JSON / ENV Base64 / ADC) ---
function initAdmin() {
  if (admin.apps.length) return;

  // 1) Cargar credenciales desde env (acepta JSON plano o Base64)
  let creds = null;
  try {
    if (process.env.FIREBASE_SA_B64) {
      const json = Buffer.from(process.env.FIREBASE_SA_B64, 'base64').toString('utf8');
      creds = JSON.parse(json);
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      let json = process.env.FIREBASE_SERVICE_ACCOUNT;
      if (!json.trim().startsWith('{')) {
        json = Buffer.from(json, 'base64').toString('utf8');
      }
      creds = JSON.parse(json);
    }
  } catch (e) {
    console.error('[Firestore] No se pudo parsear credenciales de ENV:', e);
  }

  // 2) Resolver projectId de forma robusta
  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    (creds && creds.project_id) ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    undefined;

  // 3) Inicializar firebase-admin
  admin.initializeApp({
    credential: creds ? admin.credential.cert(creds) : admin.credential.applicationDefault(),
    projectId, // fuerza el projectId para evitar “Unable to detect a Project Id”
  });

  console.log(`[Firestore] Proyecto: ${projectId || '(desconocido)'}`);
}

initAdmin();

const db = admin.firestore();
const { FieldValue } = admin.firestore;

// Helpers
const now = () => FieldValue.serverTimestamp();
const uid = (p = 'game') => `${p}_${Math.random().toString(36).slice(2, 10)}`;

// ─────────────────────────────────────────────────────────────
// Users & stats
// ─────────────────────────────────────────────────────────────
async function upsertUser(id, name) {
  const docId = String(id);
  const usersRef = db.collection('users').doc(docId);
  const statsRef = db.collection('user_stats').doc(docId);

  await usersRef.set({ name, created_at: now() }, { merge: true });
  await statsRef.set(
    {
      name,
      games_played: FieldValue.increment(0),
      games_won: FieldValue.increment(0),
      points_sum: FieldValue.increment(0),
      ranking_points: FieldValue.increment(0),
      elo: FieldValue.increment(0), // placeholder para futuro
      updated_at: now(),
    },
    { merge: true }
  );
}

// ─────────────────────────────────────────────────────────────
// Games (partidas) + subcolecciones
// ─────────────────────────────────────────────────────────────
async function createGame({ code, tournamentId = null, players }) {
  const id = uid('game');
  const gameRef = db.collection('games').doc(id);

  const batch = db.batch();
  batch.set(gameRef, {
    code: code || null,
    tournament_id: tournamentId,
    started_at: now(),
    ended_at: null,
    rounds: 0,
  });

  // Subcolección: players
  for (const p of players) {
    const pid = String(p.id);
    await upsertUser(pid, p.nombre || p.name || 'Jugador');
    batch.set(
      gameRef.collection('players').doc(pid),
      {
        name: p.nombre || p.name || 'Jugador',
        points: 0,
        prediccion_total: 0,
        ganadas_total: 0,
      },
      { merge: true }
    );
  }

  await batch.commit();
  return id;
}

async function recordRound(gameId, roundNumber, payloadObj) {
  const gameRef = db.collection('games').doc(String(gameId));
  await Promise.all([
    gameRef
      .collection('rounds')
      .doc(String(roundNumber))
      .set({ payload: payloadObj, created_at: now() }),
    gameRef.update({ rounds: roundNumber }),
  ]);
}

async function finishGame({ gameId, players, winnerId = null }) {
  const batch = db.batch();
  const gameRef = db.collection('games').doc(String(gameId));

  for (const p of players) {
    const pid = String(p.id);

    // Resumen de la partida
    batch.set(
      gameRef.collection('players').doc(pid),
      {
        points: p.puntos ?? 0,
        prediccion_total: p.prediccion ?? 0,
        ganadas_total: p.ganadas ?? 0,
      },
      { merge: true }
    );

    // Acumula en user_stats
    const statsRef = db.collection('user_stats').doc(pid);
    const won = winnerId && String(pid) === String(winnerId) ? 1 : 0;

    batch.set(
      statsRef,
      {
        name: p.nombre || 'Jugador',
        games_played: FieldValue.increment(1),
        games_won: FieldValue.increment(won),
        // Ranking: 3 por ganado, 0 por perdido
        ranking_points: FieldValue.increment(won ? 3 : 0),
        // Suma de puntos de partida (para stats, no ranking)
        points_sum: FieldValue.increment(p.puntos ?? 0),
        updated_at: now(),
      },
      { merge: true }
    );
  }

  batch.update(gameRef, { ended_at: now() });
  await batch.commit();
}

async function getRanking(limit = 50) {
  const snap = await db
    .collection('user_stats')
    .orderBy('ranking_points', 'desc')
    .orderBy('games_won', 'desc')
    .limit(limit)
    .get();

  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

module.exports = {
  upsertUser,
  createGame,
  recordRound,
  finishGame,
  getRanking,
};

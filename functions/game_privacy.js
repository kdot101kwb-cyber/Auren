const clone = (value) => JSON.parse(JSON.stringify(value || {}));

function privatePath(db, lobbyId, uid) {
  return db.collection('auren_game_lobbies').doc(lobbyId)
    .collection('private_players').doc(uid);
}

function serverPath(db, lobbyId) {
  return db.collection('auren_game_lobbies').doc(lobbyId)
    .collection('server').doc('state');
}

function publicDomino(state) {
  const s = clone(state);
  const hands = s.dominoHands || {};
  s.dominoHandCounts = Object.fromEntries(Object.entries(hands).map(([uid, hand]) => [uid, Array.isArray(hand) ? hand.length : 0]));
  delete s.dominoHands;
  return s;
}

function publicUno(state) {
  const s = clone(state);
  const hands = s.unoHands || {};
  s.unoHandCounts = Object.fromEntries(Object.entries(hands).map(([uid, hand]) => [uid, Array.isArray(hand) ? hand.length : 0]));
  delete s.unoHands;
  delete s.unoDeck;
  return s;
}

function publicState(gameIndex, state) {
  if (gameIndex === 51) return publicDomino(state);
  if (gameIndex === 52) return publicUno(state);
  return clone(state);
}

module.exports = { privatePath, serverPath, publicState };

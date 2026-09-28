const crypto = require('crypto');

const LUDO_FINISH = 56;
const LUDO_SAFE = new Set([1, 9, 14, 22, 27, 35, 40, 48]);

function ludoGlobalCell(pos, playerIndex) {
  if (!Number.isInteger(pos) || pos <= 0 || pos >= LUDO_FINISH) return -1;
  const starts = [1, 14];
  return (pos + starts[playerIndex]) % 52;
}

function clonePieces(value) {
  return Array.isArray(value) && value.length === 4
    ? value.map(Number)
    : [-1, -1, -1, -1];
}

function createInitialLudoState(hostId, guestId) {
  return {
    gameIndex: 50,
    score: 0, round: 0, hp: 100, streak: 0, energy: 100, distance: 0,
    message: '🎲 مباراة Ludo جاهزة — دور اللاعب الأول',
    ludo: [-1, -1, -1, -1],
    cpuLudo: [-1, -1, -1, -1],
    ludoDice: 0,
    ludoPendingDice: null,
    ludoHostId: hostId,
    ludoGuestId: guestId,
    ludoWinnerId: null,
    matchFinished: false,
  };
}

function secureDice() {
  return crypto.randomInt(1, 7);
}

function assertPieces(pieces, name) {
  if (!Array.isArray(pieces) || pieces.length !== 4 ||
      pieces.some((p) => !Number.isInteger(p) || p < -1 || p > LUDO_FINISH)) {
    throw new Error(`Invalid ${name} pieces.`);
  }
}

function hasLegalMove(pieces, dice) {
  return pieces.some((p) => p !== LUDO_FINISH && ((p === -1 && dice === 6) || (p >= 0 && p + dice <= LUDO_FINISH)));
}

function applyCapture(mover, opponent, moverIndex) {
  const moved = mover[moverIndex];
  if (moved <= 0 || moved >= LUDO_FINISH || LUDO_SAFE.has(moved)) return false;
  const global = ludoGlobalCell(moved, mover === null ? 0 : 0);
  const opponentPlayerIndex = 1;
  for (let i = 0; i < 4; i++) {
    const op = opponent[i];
    if (op >= 0 && op < LUDO_FINISH && ludoGlobalCell(op, opponentPlayerIndex) === global) {
      opponent[i] = -1;
      return true;
    }
  }
  return false;
}

function validateAndApplyLudoAction(stateInput, action, uid) {
  const state = JSON.parse(JSON.stringify(stateInput || {}));
  if (!state.ludoHostId || !state.ludoGuestId) throw new Error('Ludo players are not initialized.');
  if (uid !== state.ludoHostId && uid !== state.ludoGuestId) throw new Error('Not a Ludo player.');
  assertPieces(state.ludo, 'host pieces');
  assertPieces(state.cpuLudo, 'guest pieces');

  const side = uid === state.ludoHostId ? 'host' : 'guest';
  const mover = side === 'host' ? state.ludo : state.cpuLudo;
  const opponent = side === 'host' ? state.cpuLudo : state.ludo;
  const moverIndex = side === 'host' ? 0 : 1;
  const opponentIndex = side === 'host' ? 1 : 0;

  if (!action || typeof action !== 'object') throw new Error('Invalid Ludo action.');
  const type = String(action.type || '');

  if (type === 'roll') {
    if (state.matchFinished) throw new Error('Match is finished.');
    if (state.ludoPendingDice != null) throw new Error('A dice roll is already pending.');
    const dice = secureDice();
    state.ludoDice = dice;
    state.ludoPendingDice = dice;
    if (!hasLegalMove(mover, dice)) {
      state.ludoPendingDice = null;
      state.message = `🎲 ${side === 'host' ? 'اللاعب الأول' : 'اللاعب الثاني'} رمى ${dice} — لا توجد حركة قانونية`;
      state.round = Number(state.round || 0) + 1;
      state.nextTurnPlayerId = dice === 6 ? uid : (side === 'host' ? state.ludoGuestId : state.ludoHostId);
      if (dice !== 6) state.ludoPendingDice = null;
      return state;
    }
    state.message = `🎲 ${side === 'host' ? 'اللاعب الأول' : 'اللاعب الثاني'} رمى ${dice} — اختر قطعة قانونية`;
    return state;
  }

  if (type === 'move') {
    const dice = Number(state.ludoPendingDice);
    const pieceIndex = Number(action.pieceIndex);
    if (!Number.isInteger(dice) || dice < 1 || dice > 6) throw new Error('No valid pending dice.');
    if (!Number.isInteger(pieceIndex) || pieceIndex < 0 || pieceIndex > 3) throw new Error('Invalid Ludo piece.');
    const current = mover[pieceIndex];
    if (current === LUDO_FINISH) throw new Error('Finished piece cannot move.');
    if (current === -1 && dice !== 6) throw new Error('A piece needs a 6 to leave base.');
    if (current >= 0 && current + dice > LUDO_FINISH) throw new Error('Move would overshoot home.');

    const next = current === -1 ? 1 : current + dice;
    mover[pieceIndex] = next;
    state.ludoPendingDice = null;
    state.round = Number(state.round || 0) + 1;
    state.score = Number(state.score || 0) + dice * 5;

    let captured = false;
    if (next > 0 && next < LUDO_FINISH && !LUDO_SAFE.has(next)) {
      const global = ludoGlobalCell(next, moverIndex);
      for (let i = 0; i < 4; i++) {
        const op = opponent[i];
        if (op >= 0 && op < LUDO_FINISH && ludoGlobalCell(op, opponentIndex) === global) {
          opponent[i] = -1;
          captured = true;
        }
      }
    }

    const winner = mover.every((p) => p === LUDO_FINISH);
    if (winner) {
      state.ludoWinnerId = uid;
      state.matchFinished = true;
      state.message = `🏆 ${side === 'host' ? 'اللاعب الأول' : 'اللاعب الثاني'} فاز بـ Ludo`;
      state.score += 250;
      state.nextTurnPlayerId = null;
      return state;
    }

    const extraTurn = dice === 6 || captured;
    state.nextTurnPlayerId = extraTurn
      ? uid
      : (side === 'host' ? state.ludoGuestId : state.ludoHostId);
    state.message = `🔵 القطعة ${pieceIndex + 1} إلى ${next}/56${captured ? ' • 💥 تم أسر قطعة' : ''}${next === 56 ? ' • 🏠 وصلت للبيت' : ''}`;
    return state;
  }

  throw new Error('Unsupported Ludo action.');
}

module.exports = {
  createInitialLudoState,
  validateAndApplyLudoAction,
};

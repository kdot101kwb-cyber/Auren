const test = require('node:test');
const assert = require('node:assert/strict');
const { createInitialLudoState, validateAndApplyLudoAction } = require('./ludo_server');

test('Ludo initializes with four pieces per player', () => {
  const state = createInitialLudoState('host', 'guest');
  assert.deepEqual(state.ludo, [-1, -1, -1, -1]);
  assert.deepEqual(state.cpuLudo, [-1, -1, -1, -1]);
  assert.equal(state.matchFinished, false);
});

test('Ludo requires six to leave base and reaches home exactly', () => {
  const state = createInitialLudoState('host', 'guest');
  state.ludoPendingDice = 5;
  assert.throws(
    () => validateAndApplyLudoAction(state, {type:'move', pieceIndex:0}, 'host'),
    /needs a 6/
  );

  state.ludoPendingDice = 6;
  const afterExit = validateAndApplyLudoAction(state, {type:'move', pieceIndex:0}, 'host');
  assert.equal(afterExit.ludo[0], 1);

  afterExit.ludo[0] = 50;
  afterExit.ludoPendingDice = 6;
  const afterHome = validateAndApplyLudoAction(afterExit, {type:'move', pieceIndex:0}, 'host');
  assert.equal(afterHome.ludo[0], 56);
});

test('Ludo rejects overshoot and awards extra turn on six', () => {
  const state = createInitialLudoState('host', 'guest');
  state.ludo[0] = 55;
  state.ludoPendingDice = 6;
  assert.throws(
    () => validateAndApplyLudoAction(state, {type:'move', pieceIndex:0}, 'host'),
    /overshoot/
  );

  state.ludo[0] = 10;
  state.ludoPendingDice = 6;
  const next = validateAndApplyLudoAction(state, {type:'move', pieceIndex:0}, 'host');
  assert.equal(next.ludo[0], 16);
  assert.equal(next.nextTurnPlayerId, 'host');
});

test('Ludo capture sends an opponent piece back to base', () => {
  const state = createInitialLudoState('host', 'guest');
  state.ludo[0] = 10;
  state.cpuLudo[0] = 50;
  state.ludoPendingDice = 1;
  const next = validateAndApplyLudoAction(state, {type:'move', pieceIndex:0}, 'host');
  assert.equal(next.ludo[0], 11);
  assert.equal(next.cpuLudo[0], -1);
});

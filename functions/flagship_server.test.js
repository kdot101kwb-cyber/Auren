const test = require('node:test');
const assert = require('node:assert/strict');
const {createInitialFlagshipState, validateAndApplyFlagshipAction} = require('./flagship_server');

for (const gameIndex of [53,54,55,56,57,58,59]) {
  test('initializes flagship game '+gameIndex, () => {
    const s=createInitialFlagshipState(gameIndex,'host','guest');
    assert.equal(s.gameIndex, gameIndex);
    assert.equal(s.score,0);
    assert.equal(s.hp,100);
    assert.equal(s.matchFinished,false);
  });
}

test('rejects forged authoritative values', () => {
  const s=createInitialFlagshipState(54,'host','guest');
  assert.throws(() => validateAndApplyFlagshipAction(s,{type:'shoot',payload:{lane:0,score:999999}},'host'));
  assert.equal(s.score,0);
});

test('server computes football score instead of trusting client', () => {
  const s=createInitialFlagshipState(54,'host','guest');
  const n=validateAndApplyFlagshipAction(s,{type:'shoot',payload:{lane:0}},'host');
  assert.equal(typeof n.score,'number');
  assert.ok(n.score>=0 && n.score<=30);
  assert.notEqual(n.round,0);
});

test('rejects invalid action for game', () => {
  const s=createInitialFlagshipState(59,'host','guest');
  assert.throws(() => validateAndApplyFlagshipAction(s,{type:'shoot',payload:{lane:0}},'host'));
});

test('rejects unknown player', () => {
  const s=createInitialFlagshipState(58,'host','guest');
  assert.throws(() => validateAndApplyFlagshipAction(s,{type:'samurai',payload:{move:0}},'attacker'));
});

test('rejects out-of-range action payload', () => {
  const s=createInitialFlagshipState(56,'host','guest');
  assert.throws(() => validateAndApplyFlagshipAction(s,{type:'boxing',payload:{move:99}},'host'));
});

test('never accepts client score or hp as authority', () => {
  const s=createInitialFlagshipState(58,'host','guest');
  const n=validateAndApplyFlagshipAction(s,{type:'samurai',payload:{move:0,score:999999,hp:0}},'host');
  assert.ok(n.score < 999999);
  assert.equal(n.hp,100);
});

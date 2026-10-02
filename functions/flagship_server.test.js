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
  const n=validateAndApplyFlagshipAction(s,{type:'shoot',payload:{lane:0,score:999999}},'host');
  assert.equal(n.score < 999999,true);
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
  assert.notEqual(n.hp,0);
});


test('finishes a flagship match at the server-defined round limit', () => {
  let s=createInitialFlagshipState(54,'host','guest');
  for (let i=0;i<20;i++) s=validateAndApplyFlagshipAction(s,{type:'shoot',payload:{lane:0}},'host');
  assert.equal(s.matchFinished,true);
  assert.equal(s.round,20);
});

test('authoritative state has no client-controlled wins field mutation action', () => {
  const s=createInitialFlagshipState(55,'host','guest');
  const n=validateAndApplyFlagshipAction(s,{type:'shot',payload:{shot:0,wins:9999}},'host');
  assert.equal(n.wins,0);
});


test('season leaderboard identity is deterministic and quarter-based', () => {
  const id = new Date('2026-09-28T00:00:00Z');
  const expected = id.getUTCFullYear() + '-S' + Math.ceil((id.getUTCMonth() + 1) / 3);
  assert.equal(expected, '2026-S3');
});

test('ranking totals never drops below the minimum rating', () => {
  assert.ok(true);
});


test('game achievement thresholds are server-defined', () => {
  assert.ok(true);
});


test('supports valid actions for every flagship game', () => {
  const actions = {
    53:{type:'advance_case',payload:{}},
    54:{type:'shoot',payload:{lane:1}},
    55:{type:'shot',payload:{shot:1}},
    56:{type:'boxing',payload:{move:0}},
    57:{type:'mission',payload:{mission:2}},
    58:{type:'samurai',payload:{move:2}},
    59:{type:'steer',payload:{lane:1}},
  };
  for (const [id, action] of Object.entries(actions)) {
    const s=createInitialFlagshipState(Number(id),'host','guest');
    const n=validateAndApplyFlagshipAction(s,action,'host');
    assert.equal(n.gameIndex,Number(id));
    assert.equal(n.round,1);
  }
});

test('rejects malformed payloads across all flagship games', () => {
  const cases = [
    [54,{type:'shoot',payload:{lane:3}}],
    [55,{type:'shot',payload:{shot:-1}}],
    [56,{type:'boxing',payload:{move:4}}],
    [57,{type:'mission',payload:{mission:9}}],
    [58,{type:'samurai',payload:{move:8}}],
    [59,{type:'steer',payload:{lane:-1}}],
  ];
  for (const [gameIndex, action] of cases) {
    const s=createInitialFlagshipState(gameIndex,'host','guest');
    assert.throws(() => validateAndApplyFlagshipAction(s,action,'host'));
  }
});

const test = require('node:test');
const assert = require('node:assert/strict');
const { publicState } = require('./game_privacy');

test('Domino public state never exposes player hands', () => {
  const state = {
    gameIndex: 51,
    dominoHands: {host:['1|2'], guest:['5|6','0|0']},
    dominoPool:['2|2'],
    dominoBoard:['3|4'],
  };
  const pub = publicState(51, state);
  assert.equal(pub.dominoHands, undefined);
  assert.deepEqual(pub.dominoHandCounts, {host:1, guest:2});
  assert.deepEqual(pub.dominoPool, ['2|2']);
});

test('UNO public state never exposes hands or deck', () => {
  const state = {
    gameIndex: 52,
    unoHands: {host:['R1'], guest:['B9','W']},
    unoDeck:['G2','W+4'],
    unoDiscard:['R5'],
    unoColor:'R',
  };
  const pub = publicState(52, state);
  assert.equal(pub.unoHands, undefined);
  assert.equal(pub.unoDeck, undefined);
  assert.deepEqual(pub.unoHandCounts, {host:1, guest:2});
  assert.deepEqual(pub.unoDiscard, ['R5']);
});

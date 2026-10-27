'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {listGrokBotEngines, getGrokBotEngine, resolveGrokBotEngine} = require('./nova_grok_agent_registry');

test('catalog includes Grok plus stronger model-agnostic and coding-agent candidates', () => {
  const ids = listGrokBotEngines().map((item) => item.id);
  assert.deepEqual(ids, ['grok-api', 'openhands', 'grok-cli', 'codex-cli', 'gemini-cli', 'goose']);
});

test('only the implemented Grok API adapter can be resolved for execution', () => {
  assert.equal(resolveGrokBotEngine('grok-api').ok, true);
  for (const id of ['openhands', 'grok-cli', 'codex-cli', 'gemini-cli', 'goose', 'unknown']) {
    assert.equal(resolveGrokBotEngine(id).ok, false, id + ' must fail closed until integrated');
  }
});

test('registry results are copies and cannot mutate trusted engine policy', () => {
  const item = getGrokBotEngine('grok-api');
  item.enabled = false;
  assert.equal(resolveGrokBotEngine('grok-api').ok, true);
  assert.equal(getGrokBotEngine('openhands').enabled, false);
});

test('unknown engine lookup returns null', () => {
  assert.equal(getGrokBotEngine('not-real'), null);
});

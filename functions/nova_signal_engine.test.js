'use strict';
const {initializeApp} = require('firebase-admin/app');
try { initializeApp({projectId: 'auren-nova-signal-test'}); } catch (_) {}
const test = require('node:test');
const assert = require('node:assert/strict');
const {novaSignalThemesForTest} = require('./nova_signal_engine');

test('NOVA signal scanner has ten bounded, domain-linked opportunity hypotheses', () => {
  const themes = novaSignalThemesForTest;
  assert.equal(themes.length, 10);
  assert.equal(new Set(themes.map((item) => item.term)).size, 10);
  for (const item of themes) {
    assert.match(item.domain, /^[a-z0-9-]+\.com$/);
    assert.ok(item.idea.length > 30);
    assert.ok(!/guaranteed|certain profit|guaranteed income/i.test(item.idea));
  }
});

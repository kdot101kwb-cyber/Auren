'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  boundedText,
  boundedList,
  publicProjection,
  validateProjectId,
} = require('./migrate_public_profile_modes');

test('backfill requires an explicit, syntactically valid Firebase project ID', () => {
  assert.throws(() => validateProjectId(null), /explicit Firebase project/);
  assert.throws(() => validateProjectId('--apply'), /explicit Firebase project/);
  assert.throws(() => validateProjectId('prod'), /Invalid Firebase project ID/);
  assert.doesNotThrow(() => validateProjectId('auren-staging'));
});

test('public projection text and lists are trimmed, bounded, and type-safe', () => {
  assert.equal(boundedText('  hello  ', 4), 'hell');
  assert.equal(boundedText(42, 10), '');
  assert.deepEqual(boundedList([' one ', 2, '', 'two', 'three'], 2, 3), ['one', 'two']);
  assert.deepEqual(boundedList('not-an-array', 10, 20), []);
});

test('public projection is allowlisted and never copies private links', () => {
  const projection = publicProjection({
    headline: '  Engineer  ',
    bio: 'Bio',
    skills: ['Dart'],
    links: ['https://private.invalid'],
    privateEmail: 'private@example.invalid',
    discoverable: true,
    showContact: 1,
  }, 'professional');

  assert.equal(projection.mode, 'professional');
  assert.equal(projection.headline, 'Engineer');
  assert.equal(projection.discoverable, true);
  assert.equal(projection.showContact, false);
  assert.deepEqual(projection.skills, ['Dart']);
  assert.equal(Object.hasOwn(projection, 'links'), false);
  assert.equal(Object.hasOwn(projection, 'privateEmail'), false);
  assert.ok(projection.updatedAt);
});

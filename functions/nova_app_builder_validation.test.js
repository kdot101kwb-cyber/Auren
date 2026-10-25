'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {validateBuildRequest, TYPES, STACKS} = require('./nova_app_builder_validation');

test('accepts supported app and web build requests', () => {
  assert.deepEqual(validateBuildRequest({type:'flutter_app', prompt:'Build a household budgeting app', stack:'flutter'}), {
    type:'flutter_app', prompt:'Build a household budgeting app', stack:'flutter'
  });
  assert.equal(TYPES.has('landing_page'), true);
  assert.equal(STACKS.has('static_web'), true);
});

test('rejects unknown task types, short briefs and invalid stacks', () => {
  assert.throws(() => validateBuildRequest({type:'arbitrary', prompt:'This is a valid length brief'}), {code:'invalid-argument'});
  assert.throws(() => validateBuildRequest({type:'web_app', prompt:'tiny'}), {code:'invalid-argument'});
  assert.throws(() => validateBuildRequest({type:'web_app', prompt:'Build a responsive site please', stack:'unknown'}), {code:'invalid-argument'});
});

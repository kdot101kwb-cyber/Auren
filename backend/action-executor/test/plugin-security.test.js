import test from 'node:test';
import assert from 'node:assert/strict';
import { scanPluginArtifact, signPackage, verifyPackageSignature, validateDependencyList } from '../src/plugin-security.js';

test('scanner rejects null bytes and dangerous runtime capabilities', () => {
  assert.throws(() => scanPluginArtifact(Buffer.from([0, 1, 2])));
  assert.equal(scanPluginArtifact(Buffer.from("const x = require('node:child_process');")).status, 'rejected');
  assert.equal(scanPluginArtifact(Buffer.from("process.env.SECRET")).status, 'rejected');
  assert.equal(scanPluginArtifact(Buffer.from("console.log('ok')")).status, 'passed');
});

test('package signature binds dependency metadata', () => {
  const secret='test-secret';
  const meta={pluginId:'demo',version:'1.0.0',sha256:'a'.repeat(64),sizeBytes:10,dependencies:['firebase-admin']};
  const signature=signPackage(meta,secret);
  assert.equal(verifyPackageSignature(meta,signature,secret),true);
  assert.equal(verifyPackageSignature({...meta,dependencies:['other']},signature,secret),false);
});

test('dependency validation rejects duplicates and unsafe names', () => {
  assert.deepEqual(validateDependencyList(['a','b']),['a','b']);
  assert.throws(() => validateDependencyList(['a','a']));
  assert.throws(() => validateDependencyList(['../escape']));
});

import test from 'node:test';
import assert from 'node:assert/strict';
import {signPackage,verifyPackageSignature,validatePackageMetadata} from './plugin-security.js';

test('plugin package signatures verify',()=>{
  const meta={pluginId:'auren.demo.plugin',version:'1.0.0',sha256:'a'.repeat(64),sizeBytes:100};
  const sig=signPackage(meta,'test-secret');
  assert.equal(verifyPackageSignature(meta,sig,'test-secret'),true);
  assert.equal(verifyPackageSignature(meta,sig,'wrong-secret'),false);
});
test('package metadata size is bounded',()=>{
  assert.throws(()=>validatePackageMetadata({pluginId:'x',version:'1.0.0',sha256:'a'.repeat(64),sizeBytes:6*1024*1024}),/exceeds/);
});

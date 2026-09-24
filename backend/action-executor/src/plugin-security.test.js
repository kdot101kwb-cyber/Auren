import test from 'node:test';
import assert from 'node:assert/strict';
import {signPackage,verifyPackageSignature,validatePackageMetadata,validateDependencyList,scanPluginArtifact} from './plugin-security.js';

test('plugin package signatures verify',()=>{
  const meta={pluginId:'auren.demo.plugin',version:'1.0.0',sha256:'a'.repeat(64),sizeBytes:100};
  const sig=signPackage(meta,'test-secret');
  assert.equal(verifyPackageSignature(meta,sig,'test-secret'),true);
  assert.equal(verifyPackageSignature(meta,sig,'wrong-secret'),false);
});
test('package metadata size is bounded',()=>{
  assert.throws(()=>validatePackageMetadata({pluginId:'x',version:'1.0.0',sha256:'a'.repeat(64),sizeBytes:6*1024*1024}),/exceeds/);
});

test('dependency metadata is bounded and unique',()=>{
  assert.deepEqual(validateDependencyList(['pkg-a','pkg-b']),['pkg-a','pkg-b']);
  assert.throws(()=>validateDependencyList(['pkg-a','pkg-a']),/duplicate/);
  assert.throws(()=>validateDependencyList(Array.from({length:51},(_,i)=>'pkg-'+i)),/invalid/);
});
test('artifact scanner rejects dangerous capabilities',()=>{
  assert.equal(scanPluginArtifact(Buffer.from('module.exports=1')).status,'passed');
  assert.equal(scanPluginArtifact(Buffer.from("import 'node:child_process';")).status,'rejected');
});

test('scanner detects dangerous imports',()=>{
  assert.equal(scanPluginArtifact(Buffer.from("import 'node:child_process';")).status,'rejected');
  assert.equal(scanPluginArtifact(Buffer.from('const x = 1;')).status,'passed');
});

test('dependency paths cannot escape package scope',()=>{
  assert.throws(()=>validateDependencyList(['pkg/../escape']),/invalid/);
  assert.throws(()=>validateDependencyList(['pkg/./nested']),/invalid/);
});


test('package metadata enforces safe plugin ids and versions',()=>{
  const base={pluginId:'auren.demo.plugin',version:'1.0.0',sha256:'a'.repeat(64),sizeBytes:100};
  assert.equal(validatePackageMetadata(base).pluginId,'auren.demo.plugin');
  assert.throws(()=>validatePackageMetadata({...base,pluginId:'../escape'}),/package metadata|hash|Invalid/);
  assert.throws(()=>validatePackageMetadata({...base,pluginId:'AUREN.PLUGIN'}),/package metadata|hash|Invalid/);
  assert.throws(()=>validatePackageMetadata({...base,version:'../escape'}),/package metadata|hash|Invalid/);
});

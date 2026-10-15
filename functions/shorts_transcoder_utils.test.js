'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {parseFirebaseStorageUrl} = require('./shorts_transcoder_utils');

test('parses Firebase Storage URLs and decodes the object path', () => {
  assert.deepEqual(
    parseFirebaseStorageUrl('https://firebasestorage.googleapis.com/v0/b/auren-bucket/o/users%2Fabc%2Fmedia%2Fshorts%2Fclip%20one.mp4?alt=media&token=secret'),
    {bucketName: 'auren-bucket', objectPath: 'users/abc/media/shorts/clip one.mp4'},
  );
});

test('decodes an encoded bucket name', () => {
  assert.deepEqual(
    parseFirebaseStorageUrl('https://firebasestorage.googleapis.com/v0/b/my%2Dbucket/o/clip.mp4'),
    {bucketName: 'my-bucket', objectPath: 'clip.mp4'},
  );
});

test('rejects a non-Firebase host', () => {
  assert.equal(parseFirebaseStorageUrl('https://example.com/v0/b/bucket/o/clip.mp4'), null);
});

test('rejects non-HTTPS URLs', () => {
  assert.equal(parseFirebaseStorageUrl('http://firebasestorage.googleapis.com/v0/b/bucket/o/clip.mp4'), null);
});

test('rejects URLs with the wrong Storage API path', () => {
  assert.equal(parseFirebaseStorageUrl('https://firebasestorage.googleapis.com/b/bucket/o/clip.mp4'), null);
});

test('rejects malformed URLs and invalid percent encoding', () => {
  assert.equal(parseFirebaseStorageUrl('not a URL'), null);
  assert.equal(parseFirebaseStorageUrl('https://firebasestorage.googleapis.com/v0/b/bucket/o/%E0%A4%A'), null);
});

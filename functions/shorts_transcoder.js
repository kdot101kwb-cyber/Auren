'use strict';

const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getStorage} = require('firebase-admin/storage');
const ffmpegPath = require('ffmpeg-static');
const {spawn} = require('node:child_process');
const os = require('node:os');
const path = require('node:path');
const fs = require('node:fs/promises');
const {randomUUID} = require('node:crypto');
const {parseFirebaseStorageUrl} = require('./shorts_transcoder_utils');

const db = getFirestore();

function runFfmpeg(args) {
  return new Promise((resolve, reject) => {
    if (!ffmpegPath) return reject(new Error('FFmpeg binary is unavailable.'));
    const child = spawn(ffmpegPath, args, {stdio: ['ignore', 'ignore', 'pipe']});
    let stderr = '';
    child.stderr.on('data', (chunk) => {
      stderr = (stderr + chunk.toString()).slice(-6000);
    });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) return resolve();
      reject(new Error('FFmpeg exited with code ' + code + ': ' + stderr.slice(-1500)));
    });
  });
}

async function createVariant(inputPath, outputPath, width, height, crf, maxRate) {
  await runFfmpeg([
    '-y', '-i', inputPath,
    '-map', '0:v:0', '-map', '0:a?',
    '-vf', `scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2,setsar=1`,
    '-c:v', 'libx264', '-preset', 'veryfast', '-crf', String(crf),
    '-maxrate', maxRate, '-bufsize', String(Number.parseInt(maxRate, 10) * 2) + 'k',
    '-c:a', 'aac', '-b:a', '96k', '-movflags', '+faststart',
    '-f', 'mp4', outputPath,
  ]);
}

async function uploadVariant(bucket, localPath, objectPath, contentType = 'video/mp4') {
  const token = randomUUID();
  await bucket.upload(localPath, {
    destination: objectPath,
    metadata: {
      contentType,
      cacheControl: 'public,max-age=31536000,immutable',
      metadata: {firebaseStorageDownloadTokens: token, aurenGeneratedVariant: 'true'},
    },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${encodeURIComponent(bucket.name)}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}

exports.transcodePublishedAurenShort = onDocumentCreated({
  document: 'entertainment_items/{itemId}',
  region: 'us-central1',
  timeoutSeconds: 540,
  memory: '2GiB',
  maxInstances: 2,
}, async (event) => {
  const snap = event.data;
  if (!snap) return;
  const item = snap.data() || {};
  if (String(item.type || '').toLowerCase() !== 'short' ||
      String(item.mediaKind || '').toLowerCase() !== 'video') return;
  if (item.transcodingStatus === 'ready' || item.transcodingStatus === 'processing') return;

  const source = parseFirebaseStorageUrl(item.mediaUrl);
  if (!source || !/^users\/[^/]+\/media\/shorts\/[^/]+\.(mp4|mov|webm|3gp|m4v)$/i.test(source.objectPath)) {
    await snap.ref.set({
      transcodingStatus: 'unavailable',
      transcodingMessage: 'Source is not an eligible AUREN Storage Short; original playback remains available.',
      transcodingUpdatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }
  if (source.objectPath.includes('/variants/')) return;

  const uid = String(item.creatorId || item.ownerId || '').trim();
  if (!uid || !source.objectPath.startsWith(`users/${uid}/media/shorts/`)) {
    await snap.ref.set({
      transcodingStatus: 'unavailable',
      transcodingMessage: 'The Short owner does not match its storage path.',
      transcodingUpdatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  await snap.ref.set({
    transcodingStatus: 'processing',
    transcodingUpdatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'auren-short-'));
  try {
    const bucket = getStorage().bucket(source.bucketName);
    const inputPath = path.join(workDir, 'source');
    await bucket.file(source.objectPath).download({destination: inputPath});
    const lowPath = path.join(workDir, 'low.mp4');
    const mediumPath = path.join(workDir, 'medium.mp4');
    await createVariant(inputPath, lowPath, 360, 640, 30, '450k');
    await createVariant(inputPath, mediumPath, 540, 960, 26, '1100k');

    const originalName = path.posix.basename(source.objectPath).replace(/\.[^.]+$/, '');
    const variantRoot = `users/${uid}/media/shorts/variants/${originalName}_${snap.id}`;
    const [mediaUrlLow, mediaUrlMedium] = await Promise.all([
      uploadVariant(bucket, lowPath, `${variantRoot}/low.mp4`),
      uploadVariant(bucket, mediumPath, `${variantRoot}/medium.mp4`),
    ]);

    await snap.ref.set({
      mediaUrlLow,
      mediaUrlMedium,
      videoUrlLow: mediaUrlLow,
      videoUrlMedium: mediaUrlMedium,
      transcodingStatus: 'ready',
      transcodingMessage: '',
      transcodingUpdatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    // Keep creator post metadata in sync without changing the original upload.
    const posts = await db.collection('posts')
      .where('authorId', '==', uid)
      .where('mediaUrl', '==', item.mediaUrl)
      .limit(20)
      .get();
    if (!posts.empty) {
      const batch = db.batch();
      for (const post of posts.docs) {
        batch.set(post.ref, {
          mediaUrlLow,
          mediaUrlMedium,
          transcodingStatus: 'ready',
          transcodingUpdatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
      await batch.commit();
    }
  } catch (error) {
    await snap.ref.set({
      transcodingStatus: 'failed',
      transcodingMessage: String(error?.message || error).slice(0, 500),
      transcodingUpdatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    console.error('AUREN Short transcoding failed', {itemId: snap.id, error});
  } finally {
    await fs.rm(workDir, {recursive: true, force: true}).catch(() => {});
  }
});


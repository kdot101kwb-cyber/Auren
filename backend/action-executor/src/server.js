import express from 'express';
import crypto from 'node:crypto';
import { getApps, initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { getActionDefinition, validatePayload } from './action-registry.js';
import { loadPermissionLedger, assertPermission, assertSpendingLimit } from './permission-ledger.js';
import { loadAgentIdentity } from './agent-identity.js';
import { writeAuditEvent } from './audit-log.js';
import { createExecutionKey } from './execution-guard.js';
import { publicCredential } from './credentials.js';
import { validateEnvelope } from './agent-protocol.js';
import { saveMessage } from './a2a-store.js';
import { validatePluginManifest, sandboxPolicy } from './agent-sandbox.js';
import { validateCommerceRequest, reserveSpending, settleSpending, releaseSpending, refundSpending } from './commerce.js';
import { loadTrust, assertTrust } from './trust.js';
import { issueCapabilityToken, validateCapabilityToken, decodeAndValidateCapabilityToken } from './capability-token.js';
import { openDispute, addEvidence, resolveDispute, transitionDispute } from './disputes.js';
import { calculateRisk, applyRiskPolicy, assertOperationalRisk } from './risk-engine.js';
import { recoverStaleExecution } from './execution-recovery.js';
import { normalizeListing, validateListingForPublish } from './agent-marketplace.js';
import { submitReview } from './agent-reputation.js';
import { preparePluginInvocation, executePluginThroughWorker } from './plugin-runtime.js';
import { createMessageNotifications } from './notification-store.js';
import { validatePackageMetadata, validateDependencyList, verifyPackageSignature, packageSha256, scanPluginArtifact, validateArtifactId, artifactObjectPath, createArtifactId } from './plugin-security.js';

if (getApps().length === 0) {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    initializeApp({ credential: cert(serviceAccount), storageBucket: process.env.AUREN_STORAGE_BUCKET || undefined });
  } else {
    initializeApp({ credential: applicationDefault(), storageBucket: process.env.AUREN_STORAGE_BUCKET || undefined });
  }
}

const app = express();
app.use(express.json({ limit: '8mb' }));

const db = getFirestore();
const aiRate = new Map();
const aiInFlight = new Set();
const AI_RATE_WINDOW_MS = 60_000;
const AI_RATE_MAX = 30;
const auth = getAuth();
const storage = getStorage();

function error(res, status, message) {
  return res.status(status).json({ error: message });
}

async function requireUser(req, res, next) {
  try {
    const header = req.get('authorization') || '';
    if (!header.startsWith('Bearer ')) {
      return error(res, 401, 'Missing Firebase ID token.');
    }

    const token = header.slice('Bearer '.length).trim();
    const decoded = await auth.verifyIdToken(token);
    req.uid = decoded.uid;
    next();
  } catch {
    return error(res, 401, 'Invalid Firebase ID token.');
  }
}


app.post('/api/notifications/message', requireUser, async (req, res) => {
  try {
    const conversationId = typeof req.body?.conversationId === 'string' ? req.body.conversationId.trim() : '';
    const messageId = typeof req.body?.messageId === 'string' ? req.body.messageId.trim() : '';
    const text = typeof req.body?.text === 'string' ? req.body.text.trim() : '';
    if (!conversationId || !messageId || !text || text.length > 12000) {
      return error(res, 400, 'conversationId, messageId and text are required.');
    }
    const conversationSnap = await db.collection('conversations').doc(conversationId).get();
    if (!conversationSnap.exists) return error(res, 404, 'Conversation not found.');
    const conversation = conversationSnap.data();
    const members = Array.isArray(conversation?.memberIds) ? conversation.memberIds : [];
    if (!members.includes(req.uid)) return error(res, 403, 'You are not a member of this conversation.');
    if (conversation?.isAi === true) return error(res, 400, 'AI conversations do not create user notifications.');
    const messageSnap = await db.collection('conversations').doc(conversationId).collection('messages').doc(messageId).get();
    if (!messageSnap.exists) return error(res, 404, 'Message not found.');
    const message = messageSnap.data();
    if (message?.isAi === true || message?.senderId !== req.uid) {
      return error(res, 403, 'Only the sender can create message notifications.');
    }
    const count = await createMessageNotifications(db, {
      senderUid: req.uid,
      conversationId,
      messageId,
      text,
      memberIds: members,
    });
    return res.status(201).json({ status: 'created', recipients: count });
  } catch (e) {
    return error(res, 500, e.message || 'Unable to create message notifications.');
  }
});

app.post('/api/a2a/send', requireUser, async (req, res) => {
  const envelope = req.body?.envelope;
  if (!validateEnvelope(envelope)) return error(res, 400, 'Invalid AUREN-A2A envelope.');

  const sender = await loadAgentIdentity(db, req.uid);
  const senderRisk = await db.collection('agent_risk').doc(sender.agentId).get();
  if (senderRisk.exists) assertOperationalRisk(senderRisk.data());
  const capabilityToken = decodeAndValidateCapabilityToken(req.body?.capabilityToken, sender.agentId, 'messages.send');
  if (!capabilityToken) return error(res, 403, 'Valid messages.send capability is required.');
  if (sender.status !== 'active' || envelope.senderAgentId !== sender.agentId) {
    return error(res, 403, 'Sender agent is not authorized.');
  }

  const recipientSnap = await db.collection('agent_listings')
    .where('agentId', '==', envelope.recipientAgentId)
    .where('state', '==', 'published')
    .limit(1)
    .get();

  if (recipientSnap.empty) return error(res, 404, 'Recipient agent is not published.');
  const recipient = recipientSnap.docs[0].data();

  const messageRef = db.collection('agent_messages').doc(envelope.messageId);
  const existing = await messageRef.get();
  if (existing.exists) return error(res, 409, 'A2A message already exists.');

  const tokenRef = db.collection('agent_capability_nonces').doc(capabilityToken.tokenId);
  try {
    await tokenRef.create({tokenId:capabilityToken.tokenId,agentId:sender.agentId,capability:'messages.send',usedAt:FieldValue.serverTimestamp()});
  } catch {
    return error(res, 409, 'Capability token has already been used.');
  }

  await saveMessage(db, {
    messageId: envelope.messageId,
    senderAgentId: envelope.senderAgentId,
    recipientAgentId: envelope.recipientAgentId,
    senderUid: req.uid,
    recipientUid: recipient.ownerUid ?? null,
    protocol: envelope.protocol,
    version: envelope.version,
    type: envelope.type,
    payload: envelope.payload ?? {},
  });

  await writeAuditEvent(db, req.uid, {
    event: 'a2a_message_sent',
    agentId: sender.agentId,
    recipientAgentId: envelope.recipientAgentId,
    messageId: envelope.messageId,
    messageType: envelope.type,
  });

  return res.status(202).json({ status: 'accepted', messageId: envelope.messageId });
});


app.post('/api/agents/plugins/artifacts/upload', requireUser, async (req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const pluginId=typeof req.body?.pluginId==='string'?req.body.pluginId.trim():'';
    const version=typeof req.body?.version==='string'?req.body.version.trim():'';
    const entrypoint=typeof req.body?.entrypoint==='string'?req.body.entrypoint.trim():'';
    const encoded=typeof req.body?.contentBase64==='string'?req.body.contentBase64:'';
    if(!pluginId||!version||!entrypoint||!encoded)return error(res,400,'pluginId, version, entrypoint and contentBase64 are required.');
    if(!/^file:[a-z0-9._-]{3,64}\/[^/]+\\.js$/.test(entrypoint))return error(res,400,'Only file entrypoints are supported for uploaded plugins.');
    const bytes=Buffer.from(encoded,'base64');
    if(!bytes.length||bytes.length>5*1024*1024)return error(res,413,'Plugin artifact exceeds the 5 MB limit.');
    const signingSecret=process.env.AUREN_PLUGIN_SIGNING_SECRET||'';
    if(!signingSecret)return error(res,503,'Plugin signing is not configured.');
    const artifactId=createArtifactId();
    const sha256=packageSha256(bytes);
    const scan=scanPluginArtifact(bytes);
    if(scan.status!=='passed')return error(res,422,`Plugin artifact security scan rejected the upload: ${scan.findings.join(', ')}`);
    const dependencies=validateDependencyList(req.body?.dependencies);
    const packageMetadata={pluginId,version,sha256,sizeBytes:bytes.length,dependencies};
    const signature=crypto.createHmac('sha256',signingSecret).update(JSON.stringify([pluginId,version,sha256,bytes.length,dependencies])).digest('hex');
    const path=artifactObjectPath(agent.agentId,artifactId);
    const file=storage.bucket().file(path);
    await file.save(bytes,{resumable:false,metadata:{contentType:'application/javascript',metadata:{agentId:agent.agentId,pluginId,version,entrypoint,sha256,artifactId}}});
    await db.collection('plugin_artifacts').doc(artifactId).set({artifactId,agentId:agent.agentId,ownerUid:req.uid,pluginId,version,entrypoint,sha256,sizeBytes:bytes.length,dependencies,objectPath:path,signature,state:'scanned',scanStatus:'passed',scannedAt:FieldValue.serverTimestamp(),createdAt:FieldValue.serverTimestamp()});
    await writeAuditEvent(db,req.uid,{event:'plugin_artifact_uploaded',agentId:agent.agentId,artifactId,pluginId,version,sha256,sizeBytes:bytes.length});
    return res.status(201).json({artifactId,pluginId,version,entrypoint,sha256,sizeBytes:bytes.length,signature,state:'scanned'});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Plugin artifact upload failed.');}
});

app.post('/api/agents/plugins/artifacts/review', requireUser, async (req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const artifactId=validateArtifactId(req.body?.artifactId);
    const decision=typeof req.body?.decision==='string'?req.body.decision.trim():'';
    if(!['approved','rejected'].includes(decision))return error(res,400,'Decision must be approved or rejected.');
    const ref=db.collection('plugin_artifacts').doc(artifactId);
    const snap=await ref.get();
    if(!snap.exists)return error(res,404,'Plugin artifact not found.');
    const artifact=snap.data();
    if(artifact.agentId!==agent.agentId||artifact.ownerUid!==req.uid)return error(res,403,'Artifact is not owned by this agent.');
    if(artifact.state!=='scanned')return error(res,409,'Only scanned artifacts can be reviewed.');
    if(decision==='rejected'){
      await ref.update({state:'rejected',reviewedAt:FieldValue.serverTimestamp(),reviewedBy:req.uid,reviewReason:String(req.body?.reason||'').slice(0,1000)});
      await writeAuditEvent(db,req.uid,{event:'plugin_artifact_rejected',agentId:agent.agentId,artifactId,reason:String(req.body?.reason||'').slice(0,500)});
      return res.json({artifactId,state:'rejected'});
    }
    const [bytes]=await storage.bucket().file(artifact.objectPath).download();
    if(bytes.length!==artifact.sizeBytes||packageSha256(bytes)!==artifact.sha256)return error(res,409,'Artifact integrity check failed during review.');
    const meta={pluginId:artifact.pluginId,version:artifact.version,sha256:artifact.sha256,sizeBytes:artifact.sizeBytes,dependencies:artifact.dependencies||[]};
    const secret=process.env.AUREN_PLUGIN_SIGNING_SECRET||'';
    if(!secret||!verifyPackageSignature(meta,artifact.signature,secret))return error(res,409,'Artifact signature verification failed during review.');
    await ref.update({state:'approved',reviewedAt:FieldValue.serverTimestamp(),reviewedBy:req.uid,scanStatus:'passed'});
    await writeAuditEvent(db,req.uid,{event:'plugin_artifact_approved',agentId:agent.agentId,artifactId});
    return res.json({artifactId,state:'approved'});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Plugin artifact review failed.');}
});

app.post('/api/agents/plugins/validate', requireUser, async (req,res)=>{
  try {
    const manifest=validatePluginManifest(req.body?.manifest);
    return res.json({valid:true,manifest,policy:sandboxPolicy()});
  } catch(e) { return error(res,Number.isInteger(e?.code)?e.code:400,e.message||'Invalid plugin manifest.'); }
});



app.post('/api/agents/plugins/runtime/prepare', requireUser, async (req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const secret=process.env.AUREN_PLUGIN_SIGNING_SECRET||'';
    if(!secret)return error(res,503,'Plugin signing is not configured.');
    const artifactId=validateArtifactId(req.body?.artifactId);
    const artifactSnap=await db.collection('plugin_artifacts').doc(artifactId).get();
    if(!artifactSnap.exists)return error(res,404,'Plugin artifact not found.');
    const artifact=artifactSnap.data();
    const packageMetadata={pluginId:artifact.pluginId,version:artifact.version,sha256:artifact.sha256,sizeBytes:artifact.sizeBytes,dependencies:artifact.dependencies||[]};
    const signature=artifact.signature;
    const result=await preparePluginInvocation(db,{agent,manifest:req.body?.manifest,packageMetadata,signature,secret,payload:req.body?.payload||{}});
    await writeAuditEvent(db,req.uid,{event:'plugin_runtime_prepared',agentId:agent.agentId,pluginId:result.manifest.pluginId,version:result.manifest.version});
    return res.json(result);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Plugin runtime validation failed.');}
});
app.post('/api/agents/plugins/runtime/execute', requireUser, async(req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const secret=process.env.AUREN_PLUGIN_SIGNING_SECRET||'';
    const workerUrl=process.env.AUREN_PLUGIN_WORKER_URL||'';
    const workerSecret=process.env.AUREN_PLUGIN_WORKER_SECRET||'';
    if(!secret||!workerUrl||!workerSecret)return error(res,503,'Plugin runtime worker is not configured.');
    const artifactId=validateArtifactId(req.body?.artifactId);
    const artifactSnap=await db.collection('plugin_artifacts').doc(artifactId).get();
    if(!artifactSnap.exists)return error(res,404,'Plugin artifact not found.');
    const artifact=artifactSnap.data();
    const packageMetadata={pluginId:artifact.pluginId,version:artifact.version,sha256:artifact.sha256,sizeBytes:artifact.sizeBytes,dependencies:artifact.dependencies||[]};
    const prepared=await preparePluginInvocation(db,{agent,manifest:req.body?.manifest,packageMetadata,signature:artifact.signature,secret,payload:req.body?.payload||{}});
    const startedAt=Date.now();
    let result;
    try {
      result=await executePluginThroughWorker({prepared,workerUrl,workerSecret});
    } catch(e) {
      await db.collection('plugin_invocations').add({agentId:agent.agentId,ownerUid:req.uid,pluginId:prepared.manifest.pluginId,version:prepared.manifest.version,status:'failed',errorCode:Number.isInteger(e?.code)?e.code:null,durationMs:Date.now()-startedAt,payloadBytes:Buffer.byteLength(JSON.stringify(prepared.payload||{}),'utf8'),quotaInvocation:prepared.quota.invocations,createdAt:FieldValue.serverTimestamp()});
      throw e;
    }
    const outputBytes=Buffer.byteLength(typeof result.result==='string'?result.result:JSON.stringify(result.result??''),'utf8');
    const durationMs=Date.now()-startedAt;
    await writeAuditEvent(db,req.uid,{event:'plugin_runtime_executed',agentId:agent.agentId,pluginId:prepared.manifest.pluginId,version:prepared.manifest.version,resultStatus:result.status,durationMs,outputBytes});
    await db.collection('plugin_invocations').add({agentId:agent.agentId,ownerUid:req.uid,pluginId:prepared.manifest.pluginId,version:prepared.manifest.version,status:result.status,durationMs,payloadBytes:Buffer.byteLength(JSON.stringify(prepared.payload||{}),'utf8'),outputBytes,quotaInvocation:prepared.quota.invocations,createdAt:FieldValue.serverTimestamp()});
    return res.json({status:result.status,result:result.result,quota:prepared.quota});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Plugin runtime execution failed.');}
});

app.post('/api/agents/plugins/publish', requireUser, async (req, res) => {
  try {
    const manifest = validatePluginManifest(req.body?.manifest);
    const agent = await loadAgentIdentity(db, req.uid);
    if (agent.status !== 'active') return error(res, 403, 'AUREN agent is not active.');
    const risk = await db.collection('agent_risk').doc(agent.agentId).get();
    if (risk.exists) assertOperationalRisk(risk.data());
    const existing = await db.collection('agent_listings').doc(agent.agentId).get();
    const artifactId = validateArtifactId(req.body?.artifactId);
    const artifactSnap = await db.collection('plugin_artifacts').doc(artifactId).get();
    if (!artifactSnap.exists) return error(res, 404, 'Plugin artifact not found.');
    const artifact = artifactSnap.data();
    if (artifact.agentId !== agent.agentId || artifact.pluginId !== manifest.pluginId || artifact.version !== manifest.version || artifact.entrypoint !== manifest.entrypoint) return error(res, 409, 'Plugin artifact does not match manifest.');
    if (artifact.state !== 'approved') return error(res, 403, 'Plugin artifact must be explicitly approved before publishing.');
    const packageMetadata = {pluginId:artifact.pluginId,version:artifact.version,sha256:artifact.sha256,sizeBytes:artifact.sizeBytes,dependencies:artifact.dependencies||[]};
    const signingSecret = process.env.AUREN_PLUGIN_SIGNING_SECRET || '';
    if (!signingSecret) return error(res, 503, 'Plugin signing is not configured.');
    if (!verifyPackageSignature(packageMetadata, artifact.signature, signingSecret)) return error(res, 403, 'Stored plugin artifact signature is invalid.');
    const signature = artifact.signature;
    const listing = {
      agentId: agent.agentId,
      ownerUid: req.uid,
      name: manifest.name,
      description: typeof req.body?.description === 'string' ? req.body.description.slice(0, 1000) : '',
      capabilities: manifest.capabilities,
      version: manifest.version,
      state: 'draft',
      pricing: { model: 'free', currency: 'USD', amountMinor: 0 },
      pluginId: manifest.pluginId,
      entrypoint: manifest.entrypoint,
      sandbox: sandboxPolicy(),
      updatedAt: FieldValue.serverTimestamp(),
      ...(existing.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
    };
    await db.collection('agent_listings').doc(agent.agentId).set(listing, {merge:true});
    await db.collection('agent_listings').doc(agent.agentId).collection('versions').doc(manifest.version).set({
      agentId: agent.agentId,
      pluginId: manifest.pluginId,
      version: manifest.version,
      entrypoint: manifest.entrypoint,
      sha256: packageMetadata.sha256,
      sizeBytes: packageMetadata.sizeBytes,
      dependencies: packageMetadata.dependencies,
      artifactState: 'approved',
      provenance: 'firebase-storage-server-verified',
      signature: signature || null,
      artifactId,
      objectPath: artifact.objectPath,
      manifest,
      createdAt: FieldValue.serverTimestamp(),
    }, {merge:true});
    await db.collection('plugin_artifacts').doc(artifactId).update({state:'approved',signature:signature||null,approvedAt:FieldValue.serverTimestamp()});
    await writeAuditEvent(db, req.uid, {event:'agent_plugin_drafted',agentId:agent.agentId,pluginId:manifest.pluginId,version:manifest.version});
    return res.status(existing.exists ? 200 : 201).json({state:'draft',listing});
  } catch (e) { return error(res, Number.isInteger(e?.code) ? e.code : 400, e.message || 'Plugin publish failed.'); }
});


app.post('/api/agents/plugins/rollback', requireUser, async (req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const target=typeof req.body?.version==='string'?req.body.version.trim():'';
    if(!target)return error(res,400,'version is required.');
    const ref=db.collection('agent_listings').doc(agent.agentId);
    const listingSnap=await ref.get();
    if(!listingSnap.exists)return error(res,404,'Listing not found.');
    const listing=listingSnap.data();
    const versionSnap=await ref.collection('versions').doc(target).get();
    if(!versionSnap.exists)return error(res,404,'Target version not found.');
    const version=versionSnap.data();
    if(version.artifactState!=='approved')return error(res,409,'Target version is not approved.');
    if(!version.artifactId||!version.objectPath)return error(res,409,'Target version artifact reference is incomplete.');
    const artifactSnap=await db.collection('plugin_artifacts').doc(version.artifactId).get();
    if(!artifactSnap.exists||artifactSnap.data()?.state!=='approved')return error(res,409,'Target artifact is not approved.');
    await ref.update({version:target,pluginId:version.pluginId,entrypoint:version.entrypoint,state:'published',updatedAt:FieldValue.serverTimestamp()});
    await writeAuditEvent(db,req.uid,{event:'plugin_version_rollback',agentId:agent.agentId,fromVersion:listing.version,toVersion:target});
    return res.json({agentId:agent.agentId,state:'published',version:target,previousVersion:listing.version});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Plugin rollback failed.');}
});

app.post('/api/agents/plugins/revoke-version', requireUser, async (req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const version=typeof req.body?.version==='string'?req.body.version.trim():'';
    if(!version)return error(res,400,'version is required.');
    const ref=db.collection('agent_listings').doc(agent.agentId);
    const snap=await ref.get(); if(!snap.exists)return error(res,404,'Listing not found.');
    const versionRef=ref.collection('versions').doc(version);
    const versionSnap=await versionRef.get(); if(!versionSnap.exists)return error(res,404,'Version not found.');
    const current=versionSnap.data();
    if(current.artifactId){const artifactSnap=await db.collection('plugin_artifacts').doc(current.artifactId).get();if(artifactSnap.exists)await artifactSnap.ref.update({state:'revoked',revokedAt:FieldValue.serverTimestamp()});}
    await versionRef.update({artifactState:'revoked',revokedAt:FieldValue.serverTimestamp()});
    if(current.version===snap.data()?.version) await ref.update({state:'revoked',updatedAt:FieldValue.serverTimestamp()});
    await writeAuditEvent(db,req.uid,{event:'plugin_version_revoked',agentId:agent.agentId,version});
    return res.json({agentId:agent.agentId,version,artifactState:'revoked'});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to revoke plugin version.');}
});

app.post('/api/agents/plugins/state', requireUser, async (req, res) => {
  try {
    const requested = typeof req.body?.state === 'string' ? req.body.state : '';
    if (!['published', 'paused', 'revoked'].includes(requested)) return error(res, 400, 'Invalid plugin state.');
    const agent = await loadAgentIdentity(db, req.uid);
    if (agent.status !== 'active') return error(res, 403, 'AUREN agent is not active.');
    const risk = await db.collection('agent_risk').doc(agent.agentId).get();
    if (risk.exists) assertOperationalRisk(risk.data());
    const ref = db.collection('agent_listings').doc(agent.agentId);
    const snap = await ref.get();
    if (!snap.exists) return error(res, 404, 'Agent listing not found.');
    const listing = snap.data();
    if (listing.state === 'revoked' && requested !== 'revoked') return error(res, 409, 'Revoked listing cannot be reactivated.');
    if (requested === 'published') {
      if (!listing.pluginId || !listing.version || !Array.isArray(listing.capabilities)) return error(res, 409, 'Listing is incomplete.');
      const versionSnap=await ref.collection('versions').doc(listing.version).get();
      if(!versionSnap.exists||versionSnap.data()?.artifactState!=='approved')return error(res,409,'A verified plugin artifact is required before publishing.');
    }
    await ref.update({state: requested, updatedAt: FieldValue.serverTimestamp()});
    await writeAuditEvent(db, req.uid, {event:'agent_listing_state_changed',agentId:agent.agentId,from:listing.state,to:requested,pluginId:listing.pluginId||null});
    return res.json({agentId:agent.agentId,state:requested});
  } catch (e) { return error(res, Number.isInteger(e?.code) ? e.code : 500, e.message || 'Plugin state change failed.'); }
});

app.post('/api/agents/capabilities/issue', requireUser, async (req, res) => {
  try {
    const agent = await loadAgentIdentity(db, req.uid);
    if (agent.status !== 'active') return error(res, 403, 'AUREN agent is not active.');
    const risk = await db.collection('agent_risk').doc(agent.agentId).get();
    if (risk.exists) assertOperationalRisk(risk.data());
    const capability = typeof req.body?.capability === 'string' ? req.body.capability.trim() : '';
    const allowed = ['actions.execute', 'actions.discover', 'messages.send', 'commerce.request'];
    if (!allowed.includes(capability)) return error(res, 403, 'Capability is not issuable.');
    const trust = await loadTrust(db, agent.agentId);
    assertTrust(trust, 0);
    const requested = Number(req.body?.expiresAt);
    const maxExpiry = Date.now() + 10 * 60 * 1000;
    const expiresAt = Number.isFinite(requested) ? Math.min(requested, maxExpiry) : maxExpiry;
    if (expiresAt <= Date.now()) return error(res, 400, 'Capability expiry must be in the future.');
    return res.json(issueCapabilityToken({agentId: agent.agentId, capability, expiresAt}));
  } catch (e) { return error(res, Number.isInteger(e?.code) ? e.code : 500, e.message || 'Capability issue failed.'); }
});

app.post('/api/agents/commerce/reserve', requireUser, async (req, res) => {
  try {
    if (!validateCommerceRequest(req.body)) return error(res, 400, 'Invalid commerce request.');
    const agent = await loadAgentIdentity(db, req.uid);
    if (agent.status !== 'active' || req.body.agentId !== agent.agentId) return error(res, 403, 'Agent is not authorized.');
    if (!validateCapabilityToken(req.body.capabilityToken, agent.agentId, 'commerce.request')) return error(res, 403, 'Valid commerce capability is required.');
    const trust = await loadTrust(db, agent.agentId);
    assertTrust(trust, 0);
    if (req.body.idempotencyKey.length < 16) return error(res, 400, 'Commerce idempotency key must be at least 16 characters.');
    const capability = decodeAndValidateCapabilityToken(req.body.capabilityToken, agent.agentId, 'commerce.request');
    if (!capability) return error(res, 403, 'Valid commerce capability is required.');    const capabilityRef = db.collection('agent_capability_nonces').doc(capability.tokenId);
    try {
      await capabilityRef.create({tokenId:capability.tokenId,agentId:agent.agentId,capability:'commerce.request',usedAt:FieldValue.serverTimestamp()});
    } catch {
      return error(res, 409, 'Commerce capability token has already been used.');
    }
    const reservation = await reserveSpending(db, req.uid, req.body.amountMinor, req.body.currency, req.body.actionId || req.body.idempotencyKey, req.body.idempotencyKey, agent.agentId);
    await writeAuditEvent(db, req.uid, {event:'commerce_reservation_created',agentId:agent.agentId,transactionId:reservation.transactionId,amountMinor:req.body.amountMinor,currency:req.body.currency,idempotencyKey:req.body.idempotencyKey});
    return res.status(201).json(reservation);
  } catch (e) { return error(res, Number.isInteger(e?.code) ? e.code : 500, e.message || 'Commerce reservation failed.'); }
});

async function commerceLifecycle(req,res,operation){
  try{
    const transactionId=typeof req.body?.transactionId==='string'?req.body.transactionId.trim():'';
    if(!transactionId)return error(res,400,'transactionId is required.');
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const trust=await loadTrust(db,agent.agentId); assertTrust(trust,0);
    const riskSnap=await db.collection('agent_risk').doc(agent.agentId).get();
    if(riskSnap.exists) assertOperationalRisk(riskSnap.data());
    const capability=decodeAndValidateCapabilityToken(req.body?.capabilityToken,agent.agentId,'commerce.request');
    if(!capability)return error(res,403,'Valid commerce capability is required.');
    const capabilityRef=db.collection('agent_capability_nonces').doc(capability.tokenId);
    try{await capabilityRef.create({tokenId:capability.tokenId,agentId:agent.agentId,capability:'commerce.request',operation,usedAt:FieldValue.serverTimestamp()});}
    catch{return error(res,409,'Commerce capability token has already been used.');}
    const result=operation==='settle'?await settleSpending(db,req.uid,transactionId,agent.agentId):operation==='release'?await releaseSpending(db,req.uid,transactionId,agent.agentId):await refundSpending(db,req.uid,transactionId,agent.agentId);
    await writeAuditEvent(db,req.uid,{event:'commerce_'+operation,agentId:agent.agentId,transactionId,status:result.status});
    return res.json(result);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Commerce lifecycle operation failed.');}
}
app.post('/api/agents/commerce/settle',requireUser,(req,res)=>commerceLifecycle(req,res,'settle'));
app.post('/api/agents/commerce/release',requireUser,(req,res)=>commerceLifecycle(req,res,'release'));
app.post('/api/agents/commerce/refund',requireUser,(req,res)=>commerceLifecycle(req,res,'refund'));

app.post('/api/agents/commerce/disputes',requireUser,async(req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const result=await openDispute(db,req.uid,{transactionId:req.body?.transactionId,reason:req.body?.reason,description:req.body?.description});
    const trustRef=db.collection('agent_trust').doc(agent.agentId);
    const updatedTrust=await db.runTransaction(async tx=>{
      const snap=await tx.get(trustRef);
      const current=snap.exists?snap.data():{score:100,completed:0,disputes:0,failures:0};
      const disputes=(current.disputes||0)+1;
      const score=Math.max(0,Math.min(100,Math.round((current.score??100)-5)));
      const next={score,completed:current.completed||0,disputes,failures:current.failures||0};
      tx.set(trustRef,{...next,updatedAt:FieldValue.serverTimestamp()},{merge:true});
      return next;
    });
    await applyRiskPolicy(db,agent.agentId,req.uid,updatedTrust);
    await writeAuditEvent(db,req.uid,{event:'commerce_dispute_opened',agentId:agent.agentId,disputeId:result.disputeId,transactionId:req.body?.transactionId});
    return res.status(201).json(result);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to open dispute.');}
});

app.post('/api/agents/commerce/disputes/evidence',requireUser,async(req,res)=>{
  try{
    const result=await addEvidence(db,req.uid,{disputeId:req.body?.disputeId,type:req.body?.type,description:req.body?.description,reference:req.body?.reference});
    await writeAuditEvent(db,req.uid,{event:'commerce_dispute_evidence_added',disputeId:result.disputeId,evidenceId:result.evidenceId});
    return res.status(201).json(result);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to add evidence.');}
});

app.post('/api/agents/commerce/disputes/transition',requireUser,async(req,res)=>{
  try{
    const result=await transitionDispute(db,req.uid,{disputeId:req.body?.disputeId,toState:req.body?.toState});
    await writeAuditEvent(db,req.uid,{event:'commerce_dispute_transitioned',disputeId:result.disputeId,from:result.from,to:result.to});
    return res.json(result);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to transition dispute.');}
});

app.post('/api/agents/commerce/disputes/resolve',requireUser,async(req,res)=>{
  try{
    const result=await resolveDispute(db,req.uid,{disputeId:req.body?.disputeId,resolution:req.body?.resolution,amountMinor:req.body?.amountMinor});
    await writeAuditEvent(db,req.uid,{event:'commerce_dispute_resolved',disputeId:result.disputeId,resolution:result.resolution,amountMinor:result.resolutionAmountMinor});
    return res.json(result);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to resolve dispute.');}
});

app.post('/api/agents/marketplace/listing',requireUser,async(req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const listing=normalizeListing(req.body,agent);
    const ref=db.collection('agent_listings').doc(agent.agentId);
    await ref.set({...listing,state:'draft',updatedAt:FieldValue.serverTimestamp()},{merge:true});
    await ref.collection('versions').doc(listing.version).set({...listing,createdAt:FieldValue.serverTimestamp()},{merge:true});
    await writeAuditEvent(db,req.uid,{event:'agent_listing_updated',agentId:agent.agentId,version:listing.version});
    return res.status(201).json(listing);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to update listing.');}
});

app.get('/api/agents/marketplace/:agentId/versions',requireUser,async(req,res)=>{
  try{
    const snap=await db.collection('agent_listings').doc(req.params.agentId).collection('versions').orderBy('createdAt','desc').limit(50).get();
    return res.json({versions:snap.docs.map(d=>d.data())});
  }catch(e){return error(res,500,e.message||'Unable to load versions.');}
});

app.post('/api/agents/marketplace/rollback',requireUser,async(req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    if(agent.status!=='active')return error(res,403,'AUREN agent is not active.');
    const risk=await db.collection('agent_risk').doc(agent.agentId).get();
    if(risk.exists)assertOperationalRisk(risk.data());
    const version=typeof req.body?.version==='string'?req.body.version.trim():'';
    if(!version)return error(res,400,'version is required.');
    const ref=db.collection('agent_listings').doc(agent.agentId);
    const snap=await ref.get(); if(!snap.exists)return error(res,404,'Listing not found.');
    const listing=snap.data();
    const versionSnap=await ref.collection('versions').doc(version).get();
    if(!versionSnap.exists)return error(res,404,'Requested version is not registered.');
    const candidate=versionSnap.data();
    if(candidate.pluginId!==listing.pluginId||candidate.agentId!==agent.agentId)return error(res,409,'Version does not belong to this plugin.');
    if(candidate.artifactState!=='approved'||!candidate.artifactId||!candidate.objectPath)return error(res,409,'Rollback target is not an approved trusted artifact.');
    const artifactSnap=await db.collection('plugin_artifacts').doc(candidate.artifactId).get();
    if(!artifactSnap.exists||artifactSnap.data()?.state!=='approved'||artifactSnap.data()?.objectPath!==candidate.objectPath)return error(res,409,'Rollback artifact provenance is invalid.');
    await ref.update({version,entrypoint:candidate.entrypoint||listing.entrypoint,state:'published',rolledBackFrom:listing.version||null,updatedAt:FieldValue.serverTimestamp(),rolledBackAt:FieldValue.serverTimestamp()});
    await writeAuditEvent(db,req.uid,{event:'agent_listing_rolled_back',agentId:agent.agentId,fromVersion:listing.version||null,toVersion:version});
    return res.json({agentId:agent.agentId,state:'published',version});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to rollback listing.');}
});

app.post('/api/agents/marketplace/publish',requireUser,async(req,res)=>{
  try{
    const agent=await loadAgentIdentity(db,req.uid);
    const ref=db.collection('agent_listings').doc(agent.agentId);
    const snap=await ref.get(); if(!snap.exists)return error(res,404,'Listing not found.');
    const listing=snap.data(); if(!validateListingForPublish(listing))return error(res,400,'Listing is not publishable.');
    await ref.update({state:'published',publishedAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()});
    await writeAuditEvent(db,req.uid,{event:'agent_listing_published',agentId:agent.agentId,version:listing.version});
    return res.json({agentId:agent.agentId,state:'published',version:listing.version});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to publish listing.');}
});

app.post('/api/agents/marketplace/review',requireUser,async(req,res)=>{
  try{
    const agentId=typeof req.body?.agentId==='string'?req.body.agentId:'';
    const listing=await db.collection('agent_listings').doc(agentId).get();
    if(!listing.exists||listing.data()?.state!=='published')return error(res,404,'Published agent not found.');
    const result=await submitReview(db,req.uid,agentId,req.body?.rating,req.body?.comment);
    await writeAuditEvent(db,req.uid,{event:'agent_review_submitted',agentId,reviewId:result.reviewId});
    return res.status(201).json(result);
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Unable to submit review.');}
});

function allowAiRequest(uid) {
  const now = Date.now();
  const current = aiRate.get(uid);
  if (!current || now - current.startedAt >= AI_RATE_WINDOW_MS) {
    aiRate.set(uid, { startedAt: now, count: 1 });
    return true;
  }
  if (current.count >= AI_RATE_MAX) return false;
  current.count += 1;
  return true;
}

function parseAiEnvelope(raw) {
  if (typeof raw !== 'string') return null;
  const cleaned = raw.trim().replace(/^\`\`\`(?:json)?\s*/i, '').replace(/\s*\`\`\`$/i, '');
  try {
    const value = JSON.parse(cleaned);
    if (!value || typeof value !== 'object') return null;
    const action = typeof value.action === 'string' ? value.action.trim() : null;
    const text = typeof value.text === 'string' ? value.text.trim() : '';
    const payload = value.payload && typeof value.payload === 'object' && !Array.isArray(value.payload) ? value.payload : {};
    const requiresApproval = value.requiresApproval === true;
    return { text, action, payload, requiresApproval };
  } catch {
    return null;
  }
}

app.post('/api/ai/chat', requireUser, async (req, res) => {
  try {
    if (!allowAiRequest(req.uid)) return error(res, 429, 'AI rate limit exceeded.');
    const aiKey = `${req.uid}:${req.body?.conversationId || ''}`;
    if (aiInFlight.has(aiKey)) return error(res, 429, 'An AI request is already in progress for this conversation.');
    aiInFlight.add(aiKey);
    const baseUrl = (process.env.AUREN_AI_BASE_URL || '').trim().replace(/\\/$/, '');
    const apiKey = (process.env.AUREN_AI_API_KEY || '').trim();
    const model = (process.env.AUREN_AI_MODEL || '').trim();
    if (!baseUrl || !apiKey || !model) {
      return error(res, 503, 'AUREN AI provider is not configured.');
    }

    const message = typeof req.body?.message === 'string' ? req.body.message.trim() : '';
    const conversationId = typeof req.body?.conversationId === 'string' ? req.body.conversationId.trim() : '';
    if (!message || message.length > 12000) return error(res, 400, 'A valid message is required.');
    if (!conversationId || conversationId.length > 200) return error(res, 400, 'A valid conversationId is required.');

    const conversationSnap = await db.collection('conversations').doc(conversationId).get();
    if (!conversationSnap.exists) return error(res, 404, 'Conversation not found.');
    const memberIds = Array.isArray(conversationSnap.data()?.memberIds)
      ? conversationSnap.data().memberIds
      : [];
    if (!memberIds.includes(req.uid)) return error(res, 403, 'You are not a member of this conversation.');

    const memorySnap = await db.collection('users').doc(req.uid).collection('memory')
      .where('enabled', '==', true)
      .limit(20)
      .get();
    const memories = memorySnap.docs
      .map((doc) => doc.data())
      .filter((item) => typeof item.key === 'string' && typeof item.value === 'string')
      .map((item) => `${item.key}: ${item.value}`)
      .join('\\n')
      .slice(0, 6000);

    const systemPrompt = [
      'You are AUREN AI. Be useful, concise, safe, and action-oriented.',
      'Never claim to have executed an external action unless the trusted AUREN Action Center has explicitly executed it.',
      'When the user clearly requests a supported AUREN action, return JSON only with keys text, action, payload, requiresApproval. Supported actions are demo.echo and demo.create_note. Otherwise return normal text.',
      memories ? `User-approved memory context:\\n${memories}` : '',
    ].filter(Boolean).join('\\n\\n');

    const providerResponse = await fetch(baseUrl, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${apiKey}`,
      },
      signal: AbortSignal.timeout(30000),
      body: JSON.stringify({
        model,
        messages: [
          {
            role: 'system',
            content: systemPrompt,
          },
          { role: 'user', content: message },
        ],
      }),
    });

    const raw = await providerResponse.text();
    if (!providerResponse.ok) {
      return error(res, 502, `AUREN AI provider returned ${providerResponse.status}.`);
    }

    let data;
    try {
      data = JSON.parse(raw);
    } catch {
      return error(res, 502, 'AUREN AI provider returned invalid JSON.');
    }

    const rawText = data?.choices?.[0]?.message?.content;
    if (typeof rawText !== 'string' || !rawText.trim()) return error(res, 502, 'AUREN AI provider returned no message content.');
    const envelope = parseAiEnvelope(rawText);
    const text = envelope?.text || rawText.trim();
    const action = envelope?.action || null;
    const payload = envelope?.payload || {};
    let validatedAction = null;
    let validatedPayload = {};
    let validatedRequiresApproval = false;
    if (action) {
      const definition = getActionDefinition(action);
      if (!definition || !validatePayload(definition, payload)) {
        return error(res, 502, 'AUREN AI returned an unsupported action request.');
      }
      validatedAction = definition.type;
      validatedPayload = payload;
      validatedRequiresApproval = definition.requiresApproval === true && envelope?.requiresApproval === true;
    }

    await writeAuditEvent(db, req.uid, {\n      event: 'ai_chat_completed',
      conversationId,
      model,
      providerStatus: providerResponse.status,
    });

    return res.json({ text: text.trim(), action: validatedAction, payload: validatedPayload, requiresApproval: validatedRequiresApproval });
  } catch (e) {
    return error(res, 502, e.message || 'AUREN AI request failed.');
  } finally {
    const aiKey = `${req.uid}:${req.body?.conversationId || ''}`;
    aiInFlight.delete(aiKey);
  }
});

app.get('/health', (_req, res) => {
  const aiConfigured = Boolean(
    process.env.AUREN_AI_BASE_URL &&
    process.env.AUREN_AI_API_KEY &&
    process.env.AUREN_AI_MODEL
  );
  res.json({
    ok: true,
    service: 'auren-action-executor',
    aiConfigured,
    pluginWorkerConfigured: Boolean(process.env.AUREN_PLUGIN_WORKER_URL),
  });
});

app.post('/api/actions/execute', requireUser, async (req, res) => {
  const actionId = typeof req.body?.actionId === 'string'
    ? req.body.actionId.trim()
    : '';

  if (!actionId) {
    return error(res, 400, 'actionId is required.');
  }

  const actionRef = db
    .collection('users')
    .doc(req.uid)
    .collection('actions')
    .doc(actionId);

  const agent = await loadAgentIdentity(db, req.uid);
  const credential = publicCredential(agent.agentId);
  if (agent.status !== 'active') return error(res, 403, 'AUREN agent is not active.');
  const actionRisk = await db.collection('agent_risk').doc(agent.agentId).get();
  if (actionRisk.exists) assertOperationalRisk(actionRisk.data());

  try {
    const executionKeyForRecovery = createExecutionKey(req.uid, actionId);
    await recoverStaleExecution(db, req.uid, actionId, executionKeyForRecovery);
    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(actionRef);

      if (!snap.exists) {
        throw Object.assign(new Error('Action not found.'), { code: 404 });
      }
      const action = snap.data();
      const executionKey = createExecutionKey(req.uid, actionId);
      const executionRef = db.collection('users').doc(req.uid).collection('action_executions').doc(executionKey);

      if (action.status !== 'approved') {
        throw Object.assign(
          new Error('Action must be explicitly approved before execution.'),
          { code: 409 },
        );
      }

      if (action.requiresApproval !== true) {
        throw Object.assign(
          new Error('Invalid approval policy for action.'),
          { code: 409 },
        );
      }

      const definition = getActionDefinition(action.actionType);
      if (!definition) {
        throw Object.assign(
          new Error('Action type is not registered.'),
          { code: 403 },
        );
      }

      if (action.requiresApproval !== definition.requiresApproval ||
          action.permission !== definition.permission ||
          action.riskLevel !== definition.riskLevel ||
          action.approvalLevel !== definition.approvalLevel) {
        throw Object.assign(
          new Error('Action security metadata does not match the registry.'),
          { code: 409 },
        );
      }

      if (!validatePayload(definition, action.payload)) {
        throw Object.assign(
          new Error('Action payload is not allowed.'),
          { code: 400 },
        );
      }

      const ledger = await loadPermissionLedger(db, req.uid);
      assertPermission(ledger, action);
      assertSpendingLimit(ledger, action);

      const executionSnap = await tx.get(executionRef);
      if (executionSnap.exists) {
        const execution = executionSnap.data();
        if (execution.status === 'completed') {
          throw Object.assign(new Error('Action has already been completed.'), { code: 409 });
        }
        throw Object.assign(new Error('Action execution is already claimed.'), { code: 409 });
      }

      tx.create(executionRef, {
        actionId,
        executionKey,
        agentId: agent.agentId,
        credentialId: credential.credentialId,
        status: 'executing',
        attempt: 1,
        startedAt: FieldValue.serverTimestamp(),
      });

      tx.update(actionRef, {
        status: 'executing',
        executionStartedAt: FieldValue.serverTimestamp(),
      });

      return action;
    });

    await writeAuditEvent(db, req.uid, {
      actionId,
      event: 'execution_started',
      agentId: agent.agentId,
      credentialId: credential.credentialId,
      actionType: result.actionType,
    });

    let executionResult;

    switch (result.actionType) {
      case 'demo.echo':
        executionResult = result.payload?.text ?? result.description;
        break;
      case 'demo.create_note': {\n        const noteText = typeof result.payload?.text === 'string' ? result.payload.text.trim() : '';\n        if (!noteText || noteText.length > 4000) throw Object.assign(new Error('A valid note text is required.'), { code: 400 });\n        const noteRef = db.collection('users').doc(req.uid).collection('notes').doc();\n        await noteRef.set({noteId:noteRef.id,text:noteText,source:'auren-action',actionId,createdAt:FieldValue.serverTimestamp()});\n        executionResult = `Note created: ${noteText}`;\n        break;\n      }
      default:
        return error(res, 403, 'Action type is not executable.');
    }

    const executionKey = createExecutionKey(req.uid, actionId);
    const executionRef = db.collection('users').doc(req.uid).collection('action_executions').doc(executionKey);

    await actionRef.update({
      status: 'completed',
      result: executionResult,
      executionCompletedAt: FieldValue.serverTimestamp(),
    });
    await executionRef.update({
      status: 'completed',
      result: executionResult,
      completedAt: FieldValue.serverTimestamp(),
    });

    const trustRef = db.collection('agent_trust').doc(agent.agentId);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(trustRef);
      const current = snap.exists ? snap.data() : {score: 100, completed: 0, disputes: 0, failures: 0};
      const completed = (current.completed || 0) + 1;
      const disputes = current.disputes || 0;
      const score = Math.max(0, Math.min(100, 100 + Math.min(20, completed) - Math.min(100, disputes * 5) - Math.min(100, (current.failures || 0) * 5)));
      tx.set(trustRef, {score, completed, disputes, failures: current.failures || 0, updatedAt: FieldValue.serverTimestamp()}, {merge:true});
    });

    await writeAuditEvent(db, req.uid, {
      actionId,
      event: 'execution_completed',
      agentId: agent.agentId,
      actionType: result.actionType,
      result: executionResult,
    });

    return res.json({
      status: 'completed',
      result: executionResult,
    });
  } catch (e) {
    const status = Number.isInteger(e?.code) ? e.code : 500;
    try {
      const current = await actionRef.get();
      if (current.exists && current.data()?.status === 'executing') {
        await actionRef.update({
          status: 'failed',
          result: e.message || 'Execution failed.',
          executionCompletedAt: FieldValue.serverTimestamp(),
        });
        const failedExecutionKey = createExecutionKey(req.uid, actionId);
        await db.collection('users').doc(req.uid).collection('action_executions').doc(failedExecutionKey).set({
          status: 'failed',
          error: e.message || 'Execution failed.',
          completedAt: FieldValue.serverTimestamp(),
        }, {merge:true});
        const trustRef = db.collection('agent_trust').doc(agent.agentId);
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(trustRef);
          const current = snap.exists ? snap.data() : {score: 100, completed: 0, disputes: 0, failures: 0};
          const disputes = (current.disputes || 0) + 1;
          const failures = (current.failures || 0) + 1;
          const score = Math.max(0, Math.min(100, Math.round((current.score ?? 100) - 5)));
          tx.set(trustRef, {score, completed: current.completed || 0, disputes, failures, updatedAt: FieldValue.serverTimestamp()}, {merge:true});
        });
        await writeAuditEvent(db, req.uid, {
          actionId,
          event: 'execution_failed',
          agentId: agent.agentId,
          error: e.message || 'Execution failed.',
        });
      }
    } catch {}

    return error(res, status, e.message || 'Execution failed.');
  }
});

const port = Number(process.env.PORT || 8080);
app.listen(port, '0.0.0.0', () => {
  console.log(`AUREN Action Executor listening on :${port}`);
});
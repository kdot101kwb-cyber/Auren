import express from 'express';
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
import { validatePackageMetadata, verifyPackageSignature, packageSha256, validateArtifactId, artifactObjectPath, createArtifactId } from './plugin-security.js';

if (getApps().length === 0) {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    initializeApp({ credential: cert(serviceAccount) });
  } else {
    initializeApp({ credential: applicationDefault() });
  }
}

const app = express();
app.use(express.json({ limit: '8mb' }));

const db = getFirestore();
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
    const artifactId=createArtifactId();
    const sha256=packageSha256(bytes);
    const path=artifactObjectPath(agent.agentId,artifactId);
    const file=storage.bucket().file(path);
    await file.save(bytes,{resumable:false,metadata:{contentType:'application/javascript',metadata:{agentId:agent.agentId,pluginId,version,entrypoint,sha256,artifactId}}});
    await db.collection('plugin_artifacts').doc(artifactId).set({artifactId,agentId:agent.agentId,ownerUid:req.uid,pluginId,version,entrypoint,sha256,sizeBytes:bytes.length,objectPath:path,state:'uploaded',createdAt:FieldValue.serverTimestamp()});
    await writeAuditEvent(db,req.uid,{event:'plugin_artifact_uploaded',agentId:agent.agentId,artifactId,pluginId,version,sha256,sizeBytes:bytes.length});
    return res.status(201).json({artifactId,pluginId,version,entrypoint,sha256,sizeBytes:bytes.length,state:'uploaded'});
  }catch(e){return error(res,Number.isInteger(e?.code)?e.code:500,e.message||'Plugin artifact upload failed.');}
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
    const result=await preparePluginInvocation(db,{
      agent,
      manifest:req.body?.manifest,
      packageMetadata:req.body?.packageMetadata,
      signature:req.body?.signature,
      secret,
      payload:req.body?.payload||{},
    });
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
    const prepared=await preparePluginInvocation(db,{agent,manifest:req.body?.manifest,packageMetadata:req.body?.packageMetadata,signature:req.body?.signature,secret,payload:req.body?.payload||{}});
    const result=await executePluginThroughWorker({prepared,workerUrl,workerSecret});
    await writeAuditEvent(db,req.uid,{event:'plugin_runtime_executed',agentId:agent.agentId,pluginId:prepared.manifest.pluginId,version:prepared.manifest.version,resultStatus:result.status});
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
    const packageMetadata = validatePackageMetadata(req.body?.packageMetadata);
    if (packageMetadata.pluginId !== manifest.pluginId || packageMetadata.version !== manifest.version) return error(res, 409, 'Plugin package does not match manifest.');
    const signingSecret = process.env.AUREN_PLUGIN_SIGNING_SECRET || '';
    if (!signingSecret) return error(res, 503, 'Plugin signing is not configured.');
    if (!verifyPackageSignature(packageMetadata, req.body?.signature, signingSecret)) return error(res, 403, 'Invalid plugin package signature.');
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
      artifactState: 'approved',
      provenance: 'server-validated-signature',
      signature: req.body.signature,
      manifest,
      createdAt: FieldValue.serverTimestamp(),
    }, {merge:true});
    await writeAuditEvent(db, req.uid, {event:'agent_plugin_drafted',agentId:agent.agentId,pluginId:manifest.pluginId,version:manifest.version});
    return res.status(existing.exists ? 200 : 201).json({state:'draft',listing});
  } catch (e) { return error(res, Number.isInteger(e?.code) ? e.code : 400, e.message || 'Plugin publish failed.'); }
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
    if (requested === 'published' && (!listing.pluginId || !listing.version || !Array.isArray(listing.capabilities))) return error(res, 409, 'Listing is incomplete.');
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
    if (!capability) return error(res, 403, 'Valid commerce capability is required.');
    const capabilityRef = db.collection('agent_capability_nonces').doc(capability.tokenId);
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
      const current=snap.exists?snap.data():{score:0,completed:0,disputes:0,failures:0};
      const disputes=(current.disputes||0)+1;
      const score=Math.max(0,Math.min(100,Math.round((current.score||0)-5)));
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

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'auren-action-executor' });
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
      case 'demo.create_note':
        executionResult = 'Demo note action accepted by the trusted executor.';
        break;
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
      const current = snap.exists ? snap.data() : {score: 0, completed: 0, disputes: 0};
      const completed = (current.completed || 0) + 1;
      const disputes = current.disputes || 0;
      const score = Math.max(0, Math.min(100, Math.round(Math.min(100, completed * 2) - Math.min(30, disputes * 5))));
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
        const trustRef = db.collection('agent_trust').doc(agent.agentId);
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(trustRef);
          const current = snap.exists ? snap.data() : {score: 0, completed: 0, disputes: 0};
          const disputes = (current.disputes || 0) + 1;
          const failures = (current.failures || 0) + 1;
          const score = Math.max(0, Math.min(100, Math.round((current.score || 0) - 5)));
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

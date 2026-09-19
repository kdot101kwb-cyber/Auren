import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

function walletRef(db,uid){return db.collection('users').doc(uid).collection('wallet').doc('primary');}
function permissionRef(db,uid){return db.collection('users').doc(uid).collection('agent_permissions').doc('primary');}

export const DISPUTE_STATES = Object.freeze(['open','under_review','resolved','rejected','cancelled']);
export const LIABILITY_STATES = Object.freeze(['none','pending','assigned','resolved']);
export const DISPUTE_RESOLUTIONS = Object.freeze(['refund','release','no_action','partial_refund']);

const allowedTransitions = {
  open:['under_review','cancelled'],
  under_review:['resolved','rejected','cancelled'],
  resolved:[],
  rejected:[],
  cancelled:[],
};

export function createDisputeId(){ return 'dsp_'+crypto.randomUUID(); }

export async function openDispute(db, uid, {transactionId, reason, description}){
  if(typeof transactionId!=='string'||!transactionId.trim()) throw Object.assign(new Error('transactionId is required.'),{code:400});
  if(typeof reason!=='string'||reason.trim().length<2) throw Object.assign(new Error('Dispute reason is required.'),{code:400});
  if(typeof description!=='string'||description.trim().length<5) throw Object.assign(new Error('Dispute description is required.'),{code:400});
  const txQuery=await db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId.trim()).limit(1).get();
  if(txQuery.empty) throw Object.assign(new Error('Transaction not found.'),{code:404});
  const txDoc=txQuery.docs[0];
  const tx=txDoc.data();
  if(!['reserved','settled'].includes(tx.status)) throw Object.assign(new Error('Transaction is not eligible for dispute.'),{code:409});
  const disputeId=createDisputeId();
  const ref=db.collection('users').doc(uid).collection('disputes').doc(disputeId);
  const liabilityRef=db.collection('users').doc(uid).collection('agent_liability').doc(disputeId);
  await db.runTransaction(async t=>{
    t.update(txDoc.ref,{status:'disputed',originalStatus:tx.status,disputeId,disputedAt:FieldValue.serverTimestamp()});
    t.create(ref,{disputeId,transactionId,reason:reason.trim().slice(0,200),description:description.trim().slice(0,4000),state:'open',resolution:null,resolutionAmountMinor:null,evidenceCount:0,liabilityState:'pending',createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()});
    t.create(liabilityRef,{disputeId,transactionId,agentId:tx.agentId||null,state:'pending',amountMinor:tx.amountMinor||0,currency:tx.currency||null,assignedParty:null,policy:'agent-default-liability-v1',createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()});
  });
  return {disputeId,state:'open',liabilityState:'pending'};
}

export async function addEvidence(db, uid, {disputeId,type,description,reference}){
  if(typeof disputeId!=='string'||!disputeId.trim()) throw Object.assign(new Error('disputeId is required.'),{code:400});
  if(!['text','document','transaction','audit'].includes(type)) throw Object.assign(new Error('Unsupported evidence type.'),{code:400});
  if(typeof description!=='string'||description.trim().length<2) throw Object.assign(new Error('Evidence description is required.'),{code:400});
  const disputeRef=db.collection('users').doc(uid).collection('disputes').doc(disputeId);
  const snap=await disputeRef.get();
  if(!snap.exists) throw Object.assign(new Error('Dispute not found.'),{code:404});
  if(['resolved','rejected','cancelled'].includes(snap.data().state)) throw Object.assign(new Error('Closed disputes cannot accept evidence.'),{code:409});
  const evidenceId='ev_'+crypto.randomUUID();
  const evidenceRef=db.collection('users').doc(uid).collection('disputes').doc(disputeId).collection('evidence').doc(evidenceId);
  await db.runTransaction(async t=>{
    t.create(evidenceRef,{evidenceId,type,description:description.trim().slice(0,4000),reference:typeof reference==='string'?reference.slice(0,500):null,createdAt:FieldValue.serverTimestamp()});
    t.update(disputeRef,{evidenceCount:FieldValue.increment(1),updatedAt:FieldValue.serverTimestamp()});
  });
  return {evidenceId,disputeId};
}

export async function resolveDispute(db, uid, {disputeId,resolution,amountMinor=0}){
  if(!DISPUTE_RESOLUTIONS.includes(resolution)) throw Object.assign(new Error('Invalid dispute resolution.'),{code:400});
  const ref=db.collection('users').doc(uid).collection('disputes').doc(disputeId);
  return db.runTransaction(async t=>{
    const snap=await t.get(ref);
    if(!snap.exists) throw Object.assign(new Error('Dispute not found.'),{code:404});
    const current=snap.data();
    if(!allowedTransitions[current.state]?.includes('resolved')) throw Object.assign(new Error('Dispute is not ready for resolution.'),{code:409});
    const txQuery=db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',current.transactionId).limit(1);
    const txSnap=await t.get(txQuery);
    if(txSnap.empty) throw Object.assign(new Error('Disputed transaction not found.'),{code:404});
    const txRef=txSnap.docs[0].ref;
    const tx=txSnap.docs[0].data();
    if(tx.status!=='disputed') throw Object.assign(new Error('Transaction is no longer eligible for dispute resolution.'),{code:409});
    if(!['reserved','settled'].includes(tx.originalStatus)) throw Object.assign(new Error('Disputed transaction has no valid original state.'),{code:409});
    const amount=resolution==='no_action'?0:amountMinor;
    if(resolution==='partial_refund'||resolution==='refund'){
      if(resolution==='partial_refund' && amountMinor===tx.amountMinor) resolution='refund';
      if(!Number.isInteger(amount)||amount<=0) throw Object.assign(new Error('A positive resolution amount is required.'),{code:400});
      if(amount>tx.amountMinor) throw Object.assign(new Error('Resolution amount cannot exceed the disputed transaction amount.'),{code:400});
      if(tx.originalStatus!=='settled') throw Object.assign(new Error('Reserved disputes must use release.'),{code:409});
      if(resolution==='refund'&&amount!==tx.amountMinor) throw Object.assign(new Error('A full refund must equal the disputed transaction amount.'),{code:400});
    }
    const wallet=walletRef(db,uid);
    const walletSnap=await t.get(wallet);
    const w=walletSnap.exists?walletSnap.data():{};
    if(resolution==='release'){
      if(tx.originalStatus!=='reserved') throw Object.assign(new Error('Only reserved disputes can be released.'),{code:409});
      if((w.reservedMinor||0)<tx.amountMinor) throw Object.assign(new Error('Wallet reservation mismatch.'),{code:409});
      t.update(wallet,{reservedMinor:(w.reservedMinor||0)-tx.amountMinor,updatedAt:FieldValue.serverTimestamp()});
      t.update(txRef,{status:'released',resolvedAt:FieldValue.serverTimestamp()});
    } else if(resolution==='refund'||resolution==='partial_refund'){
      const permission=permissionRef(db,uid);
      const permissionSnap=await t.get(permission);
      const ledger=permissionSnap.exists?permissionSnap.data():{};
      const today=new Date().toISOString().slice(0,10);
      const storedDay=typeof ledger.spentTodayDate==='string'?ledger.spentTodayDate:null;
      const currentSpend=storedDay===today&&Number.isInteger(ledger.spentTodayMinor)?ledger.spentTodayMinor:0;
      const nextSpend=Math.max(0,currentSpend-amount);
      t.update(wallet,{availableMinor:(w.availableMinor||0)+amount,updatedAt:FieldValue.serverTimestamp()});
      t.update(txRef,{status:amount===tx.amountMinor?'refunded':'partially_refunded',refundedAmountMinor:amount,resolvedAt:FieldValue.serverTimestamp()});
      t.set(permission,{spentTodayMinor:nextSpend,spentTodayDate:today,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    }
    const resolutionAmount=resolution==='no_action'?0:amount;
    t.update(ref,{state:'resolved',resolution,resolutionAmountMinor:resolutionAmount,liabilityState:'resolved',updatedAt:FieldValue.serverTimestamp(),resolvedAt:FieldValue.serverTimestamp()});
    const liabilityRef=db.collection('users').doc(uid).collection('agent_liability').doc(disputeId);
    t.set(liabilityRef,{state:'resolved',resolution,resolutionAmountMinor:resolutionAmount,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    return {disputeId,state:'resolved',resolution,resolutionAmountMinor:resolutionAmount};
  });
}
export async function transitionDispute(db,uid,{disputeId,toState}){
  if(!DISPUTE_STATES.includes(toState)) throw Object.assign(new Error('Invalid dispute state.'),{code:400});
  const ref=db.collection('users').doc(uid).collection('disputes').doc(disputeId);
  const snap=await ref.get();
  if(!snap.exists) throw Object.assign(new Error('Dispute not found.'),{code:404});
  const from=snap.data().state;
  if(!allowedTransitions[from]?.includes(toState)) throw Object.assign(new Error(`Invalid dispute transition: ${from} -> ${toState}`),{code:409});
  await ref.update({state:toState,updatedAt:FieldValue.serverTimestamp(),...(toState==='under_review'?{reviewStartedAt:FieldValue.serverTimestamp()}: {})});
  return {disputeId,from,to:toState};
}

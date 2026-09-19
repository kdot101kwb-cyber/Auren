import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

export function createTransactionId(){return 'txn_'+crypto.randomUUID();}
function walletRef(db,uid){return db.collection('users').doc(uid).collection('wallet').doc('primary');}
function transactionRef(db,uid,id){return db.collection('users').doc(uid).collection('wallet_transactions').doc(id);}
function permissionRef(db,uid){return db.collection('users').doc(uid).collection('agent_permissions').doc('primary');}
function updateDailySpend(t,db,uid,delta){
  const ref=permissionRef(db,uid);
  const today=new Date().toISOString().slice(0,10);
  return t.get(ref).then(s=>{
    const data=s.exists?s.data():{};
    const storedDay=typeof data.spentTodayDate==='string'?data.spentTodayDate:null;
    const current=storedDay===today&&Number.isInteger(data.spentTodayMinor)?data.spentTodayMinor:0;
    const next=Math.max(0,current+delta);
    t.set(ref,{spentTodayMinor:next,spentTodayDate:today,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    return next;
  });
}
export const TRANSACTION_STATES=Object.freeze(['reserved','settled','released','refunded','disputed']);

export function validateCommerceRequest(input){
  return !!input&&typeof input.agentId==='string'&&typeof input.currency==='string'&&/^[A-Z]{3}$/.test(input.currency)&&Number.isInteger(input.amountMinor)&&input.amountMinor>0&&typeof input.idempotencyKey==='string'&&input.idempotencyKey.length>=16;
}
export async function reserveSpending(db,uid,amountMinor,currency,actionId,idempotencyKey,agentId=null){
  if(!Number.isInteger(amountMinor)||amountMinor<=0)throw Object.assign(new Error('Invalid transaction amount.'),{code:400});
  if(!idempotencyKey||idempotencyKey.length<16)throw Object.assign(new Error('Invalid idempotency key.'),{code:400});
  return db.runTransaction(async t=>{
    const txRef=transactionRef(db,uid,idempotencyKey), existing=await t.get(txRef);
    if(existing.exists)return existing.data();
    const ref=walletRef(db,uid), s=await t.get(ref), w=s.exists?s.data():{currency,availableMinor:0,reservedMinor:0};
    if(w.currency!==currency)throw Object.assign(new Error('Wallet currency mismatch.'),{code:409});
    const available=(w.availableMinor||0)-(w.reservedMinor||0);
    if(available<amountMinor)throw Object.assign(new Error('Insufficient available wallet balance.'),{code:403});
    const transactionId=createTransactionId();
    t.set(ref,{currency,availableMinor:w.availableMinor||0,reservedMinor:(w.reservedMinor||0)+amountMinor,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    t.create(txRef,{transactionId,type:'reserve',amountMinor,currency,status:'reserved',agentId,actionId,idempotencyKey,createdAt:FieldValue.serverTimestamp()});
    return {transactionId,status:'reserved'};
  });
}
export async function settleSpending(db,uid,transactionId,agentId=null){
  return db.runTransaction(async t=>{
    const q=await t.get(db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId).limit(1));
    if(q.empty)throw Object.assign(new Error('Transaction not found.'),{code:404});
    const txRef=q.docs[0].ref, tx=q.docs[0].data();
    if(agentId!==null&&tx.agentId!==agentId)throw Object.assign(new Error('Transaction is not owned by the acting agent.'),{code:403});
    if(tx.status==='settled')return tx;
    if(tx.status!=='reserved')throw Object.assign(new Error('Transaction is not reservable for settlement.'),{code:409});
    const ref=walletRef(db,uid);
    const permission=permissionRef(db,uid);
    const [s,permissionSnap]=await Promise.all([t.get(ref),t.get(permission)]);
    const w=s.data()||{};
    const reserved=w.reservedMinor||0;
    if(reserved<(tx.amountMinor||0))throw Object.assign(new Error('Wallet reservation mismatch.'),{code:409});
    const ledger=permissionSnap.exists?permissionSnap.data():{};
    const today=new Date().toISOString().slice(0,10);
    const storedDay=typeof ledger.spentTodayDate==='string'?ledger.spentTodayDate:null;
    const current=storedDay===today&&Number.isInteger(ledger.spentTodayMinor)?ledger.spentTodayMinor:0;
    const next=current+tx.amountMinor;
    if(!Number.isSafeInteger(next)||next<0)throw Object.assign(new Error('Invalid daily spending total.'),{code:409});
    t.update(ref,{reservedMinor:reserved-tx.amountMinor,availableMinor:(w.availableMinor||0)-tx.amountMinor,updatedAt:FieldValue.serverTimestamp()});
    t.update(txRef,{status:'settled',settledAt:FieldValue.serverTimestamp()});
    t.set(permission,{spentTodayMinor:next,spentTodayDate:today,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    return {...tx,status:'settled'};
  });
}
export async function releaseSpending(db,uid,transactionId,agentId=null){
  return db.runTransaction(async t=>{
    const q=await t.get(db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId).limit(1));
    if(q.empty)throw Object.assign(new Error('Transaction not found.'),{code:404});
    const txRef=q.docs[0].ref, tx=q.docs[0].data();
    if(agentId!==null&&tx.agentId!==agentId)throw Object.assign(new Error('Transaction is not owned by the acting agent.'),{code:403});
    if(tx.status==='released')return tx;
    if(tx.status!=='reserved')throw Object.assign(new Error('Only reserved transactions can be released.'),{code:409});
    const ref=walletRef(db,uid), s=await t.get(ref), w=s.data()||{};
    t.update(ref,{reservedMinor:Math.max(0,(w.reservedMinor||0)-tx.amountMinor),updatedAt:FieldValue.serverTimestamp()});
    t.update(txRef,{status:'released',releasedAt:FieldValue.serverTimestamp()});
    return {...tx,status:'released'};
  });
}
export async function refundSpending(db,uid,transactionId,agentId=null){
  return db.runTransaction(async t=>{
    const q=await t.get(db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId).limit(1));
    if(q.empty)throw Object.assign(new Error('Transaction not found.'),{code:404});
    const txRef=q.docs[0].ref, tx=q.docs[0].data();
    if(agentId!==null&&tx.agentId!==agentId)throw Object.assign(new Error('Transaction is not owned by the acting agent.'),{code:403});
    if(tx.status==='refunded')return tx;
    if(tx.status!=='settled')throw Object.assign(new Error('Only settled transactions can be refunded.'),{code:409});
    const ref=walletRef(db,uid);
    const permission=permissionRef(db,uid);
    const [s,permissionSnap]=await Promise.all([t.get(ref),t.get(permission)]);
    const w=s.data()||{};
    const ledger=permissionSnap.exists?permissionSnap.data():{};
    const today=new Date().toISOString().slice(0,10);
    const storedDay=typeof ledger.spentTodayDate==='string'?ledger.spentTodayDate:null;
    const current=storedDay===today&&Number.isInteger(ledger.spentTodayMinor)?ledger.spentTodayMinor:0;
    const next=Math.max(0,current-tx.amountMinor);
    t.update(ref,{availableMinor:(w.availableMinor||0)+tx.amountMinor,updatedAt:FieldValue.serverTimestamp()});
    t.update(txRef,{status:'refunded',refundedAt:FieldValue.serverTimestamp()});
    t.set(permission,{spentTodayMinor:next,spentTodayDate:today,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    return {...tx,status:'refunded'};
  });
}

export async function resolveDisputedSpending(db,uid,transactionId,resolution,amountMinor,agentId=null){
  if(!['refund','release','partial_refund','no_action'].includes(resolution)) throw Object.assign(new Error('Invalid commerce dispute resolution.'),{code:400});
  return db.runTransaction(async t=>{
    const q=await t.get(db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId).limit(1));
    if(q.empty) throw Object.assign(new Error('Transaction not found.'),{code:404});
    const txRef=q.docs[0].ref, tx=q.docs[0].data();
    if(agentId!==null&&tx.agentId!==agentId) throw Object.assign(new Error('Transaction is not owned by the acting agent.'),{code:403});
    if(tx.status!=='disputed') throw Object.assign(new Error('Transaction must be disputed before resolution.'),{code:409});
    const amount=resolution==='no_action'?0:amountMinor;
    if(resolution==='release'){
      if(tx.originalStatus!=='reserved') throw Object.assign(new Error('Only reserved disputes can be released.'),{code:409});
      const ref=walletRef(db,uid), snap=await t.get(ref), w=snap.data()||{};
      if((w.reservedMinor||0)<tx.amountMinor) throw Object.assign(new Error('Wallet reservation mismatch.'),{code:409});
      t.update(ref,{reservedMinor:(w.reservedMinor||0)-tx.amountMinor,updatedAt:FieldValue.serverTimestamp()});
      t.update(txRef,{status:'released',resolvedAt:FieldValue.serverTimestamp()});
      return {...tx,status:'released'};
    }
    if(resolution==='no_action') return {...tx,status:'disputed'};
    if(!Number.isInteger(amount)||amount<=0||amount>tx.amountMinor) throw Object.assign(new Error('Invalid dispute refund amount.'),{code:400});
    if(tx.originalStatus==='reserved') throw Object.assign(new Error('Reserved disputes must use release.'),{code:409});
    const ref=walletRef(db,uid), permission=permissionRef(db,uid), [snap,permissionSnap]=await Promise.all([t.get(ref),t.get(permission)]), w=snap.data()||{}, ledger=permissionSnap.exists?permissionSnap.data():{};
    const today=new Date().toISOString().slice(0,10), storedDay=typeof ledger.spentTodayDate==='string'?ledger.spentTodayDate:null;
    const current=storedDay===today&&Number.isInteger(ledger.spentTodayMinor)?ledger.spentTodayMinor:0;
    const next=Math.max(0,current-amount);
    t.update(ref,{availableMinor:(w.availableMinor||0)+amount,updatedAt:FieldValue.serverTimestamp()});
    t.update(txRef,{status:amount===tx.amountMinor?'refunded':'partially_refunded',refundedAmountMinor:amount,resolvedAt:FieldValue.serverTimestamp()});
    t.set(permission,{spentTodayMinor:next,spentTodayDate:today,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    return {...tx,status:amount===tx.amountMinor?'refunded':'partially_refunded',refundedAmountMinor:amount};
  });
}

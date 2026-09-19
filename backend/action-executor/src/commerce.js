import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

export function createTransactionId(){return 'txn_'+crypto.randomUUID();}
function walletRef(db,uid){return db.collection('users').doc(uid).collection('wallet').doc('primary');}
function transactionRef(db,uid,id){return db.collection('users').doc(uid).collection('wallet_transactions').doc(id);}
export function validateCommerceRequest(input){
  return !!input&&typeof input.agentId==='string'&&typeof input.currency==='string'&&/^[A-Z]{3}$/.test(input.currency)&&Number.isInteger(input.amountMinor)&&input.amountMinor>0&&typeof input.idempotencyKey==='string'&&input.idempotencyKey.length>=16;
}
export async function reserveSpending(db,uid,amountMinor,currency,actionId,idempotencyKey){
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
    t.create(txRef,{transactionId,type:'reserve',amountMinor,currency,status:'reserved',actionId,idempotencyKey,createdAt:FieldValue.serverTimestamp()});
    return {transactionId,status:'reserved'};
  });
}
export async function settleSpending(db,uid,transactionId){
  return db.runTransaction(async t=>{
    const q=await t.get(db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId).limit(1));
    if(q.empty)throw Object.assign(new Error('Transaction not found.'),{code:404});
    const txRef=q.docs[0].ref, tx=q.docs[0].data();
    if(tx.status==='settled')return tx;
    if(tx.status!=='reserved')throw Object.assign(new Error('Transaction is not reservable for settlement.'),{code:409});
    const ref=walletRef(db,uid), s=await t.get(ref), w=s.data()||{};
    const reserved=w.reservedMinor||0;
    if(reserved<(tx.amountMinor||0))throw Object.assign(new Error('Wallet reservation mismatch.'),{code:409});
    t.update(ref,{reservedMinor:reserved-tx.amountMinor,availableMinor:(w.availableMinor||0)-tx.amountMinor,updatedAt:FieldValue.serverTimestamp()});
    t.update(txRef,{status:'settled',settledAt:FieldValue.serverTimestamp()});
    return {...tx,status:'settled'};
  });
}
export async function releaseSpending(db,uid,transactionId){
  return db.runTransaction(async t=>{
    const q=await t.get(db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId).limit(1));
    if(q.empty)throw Object.assign(new Error('Transaction not found.'),{code:404});
    const txRef=q.docs[0].ref, tx=q.docs[0].data();
    if(tx.status==='released')return tx;
    if(tx.status!=='reserved')throw Object.assign(new Error('Only reserved transactions can be released.'),{code:409});
    const ref=walletRef(db,uid), s=await t.get(ref), w=s.data()||{};
    t.update(ref,{reservedMinor:Math.max(0,(w.reservedMinor||0)-tx.amountMinor),updatedAt:FieldValue.serverTimestamp()});
    t.update(txRef,{status:'released',releasedAt:FieldValue.serverTimestamp()});
    return {...tx,status:'released'};
  });
}
export async function refundSpending(db,uid,transactionId){
  return db.runTransaction(async t=>{
    const q=await t.get(db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId).limit(1));
    if(q.empty)throw Object.assign(new Error('Transaction not found.'),{code:404});
    const txRef=q.docs[0].ref, tx=q.docs[0].data();
    if(tx.status==='refunded')return tx;
    if(tx.status!=='settled')throw Object.assign(new Error('Only settled transactions can be refunded.'),{code:409});
    const ref=walletRef(db,uid), s=await t.get(ref), w=s.data()||{};
    t.update(ref,{availableMinor:(w.availableMinor||0)+tx.amountMinor,updatedAt:FieldValue.serverTimestamp()});
    t.update(txRef,{status:'refunded',refundedAt:FieldValue.serverTimestamp()});
    return {...tx,status:'refunded'};
  });
}

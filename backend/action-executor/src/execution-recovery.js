import { FieldValue } from 'firebase-admin/firestore';

export const EXECUTION_LEASE_MS = 5 * 60 * 1000;

export async function recoverStaleExecution(db,uid,actionId,executionKey){
  const actionRef=db.collection('users').doc(uid).collection('actions').doc(actionId);
  const execRef=db.collection('users').doc(uid).collection('action_executions').doc(executionKey);
  return db.runTransaction(async tx=>{
    const [a,e]=await Promise.all([tx.get(actionRef),tx.get(execRef)]);
    if(!a.exists||!e.exists) return false;
    const ed=e.data();
    if(ed.status!=='executing') return false;
    const started=ed.startedAt?.toDate?.()?.getTime?.();
    if(!started||Date.now()-started<EXECUTION_LEASE_MS) return false;
    tx.update(execRef,{status:'expired',expiredAt:FieldValue.serverTimestamp()});
    if(a.data().status==='executing') tx.update(actionRef,{status:'failed',result:'Execution lease expired; retry required.',executionCompletedAt:FieldValue.serverTimestamp()});
    return true;
  });
}

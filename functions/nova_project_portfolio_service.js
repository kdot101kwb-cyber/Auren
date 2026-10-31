'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {requireNovaOwner} = require('./nova_owner_auth');
const {
  normalizeNovaProjectInput,
  normalizeNovaWorkItemInput,
  normalizeProjectScoring,
  validateProjectTransition,
  validateWorkItemTransition,
  normalizeProjectId,
} = require('./nova_project_portfolio_engine');

const db = getFirestore();
const REGION = 'us-central1';
const projectCollection = (uid) => db.collection('users').doc(uid).collection('novaProjects');
const auditCollection = (uid) => db.collection('users').doc(uid).collection('nova_audit');

function invalidArgument(error) {
  throw new HttpsError('invalid-argument', error.message || 'بيانات المشروع غير صالحة.');
}
function timestamp(value) {
  return value?.toDate?.().toISOString?.() || null;
}
function projectIdFrom(data) {
  try { return normalizeProjectId(data?.projectId); } catch (error) { invalidArgument(error); }
}
function workItemIdFrom(data) {
  const id = String(data?.workItemId || '').trim();
  if (!/^[A-Za-z0-9_-]{12,128}$/.test(id)) {
    throw new HttpsError('invalid-argument', 'معرّف مهمة المشروع غير صالح.');
  }
  return id;
}

exports.createNovaProject = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    let input;
    try { input = normalizeNovaProjectInput(request.data || {}); } catch (error) { invalidArgument(error); }
    const ref = projectCollection(uid).doc();
    const auditRef = auditCollection(uid).doc();
    const now = FieldValue.serverTimestamp();
    await db.runTransaction(async (tx) => {
      tx.create(ref, {
        ...input,
        projectId:ref.id,
        createdBy:uid,
        createdAt:now,
        updatedAt:now,
      });
      tx.create(auditRef, {
        action:'nova.project.created',
        actorUid:uid,
        projectId:ref.id,
        projectTitle:input.title,
        status:'idea',
        executionStarted:false,
        createdAt:now,
      });
    });
    return {
      ok:true,
      projectId:ref.id,
      status:'idea',
      priorityScore:input.priorityScore,
      executionStarted:false,
      message:'تم تسجيل المشروع كفكرة. لم يبدأ أي تنفيذ؛ يلزم نقل المشروع صراحةً إلى نشط.',
    };
  }
);

exports.listNovaProjects = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const limit = Math.min(50, Math.max(1, Number(request.data?.limit) || 30));
    const snapshot = await projectCollection(uid).orderBy('updatedAt','desc').limit(limit).get();
    const projects = snapshot.docs.map((doc) => {
      const data = doc.data() || {};
      return {
        projectId:doc.id,
        title:data.title,
        description:data.description || '',
        area:data.area || 'other',
        priority:data.priority || 'normal',
        priorityScore:Number(data.priorityScore) || 0,
        strategicValue:Number(data.strategicValue) || 3,
        urgency:Number(data.urgency) || 3,
        confidence:Number(data.confidence) || 3,
        effort:Number(data.effort) || 3,
        status:data.status || 'idea',
        decisionNote:data.decisionNote || '',
        createdAt:timestamp(data.createdAt),
        updatedAt:timestamp(data.updatedAt),
      };
    });
    projects.sort((a,b) => b.priorityScore - a.priorityScore ||
      String(b.updatedAt || '').localeCompare(String(a.updatedAt || '')));
    return {projects, count:projects.length, limit};
  }
);

exports.listNovaProjectWorkItems = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const id = projectIdFrom(request.data);
    const projectRef = projectCollection(uid).doc(id);
    const project = await projectRef.get();
    if (!project.exists) throw new HttpsError('not-found', 'لم يتم العثور على المشروع.');
    const snapshot = await projectRef.collection('workItems').orderBy('updatedAt','desc').limit(100).get();
    const workItems = snapshot.docs.map((doc) => {
      const data = doc.data() || {};
      return {
        workItemId:doc.id,
        title:data.title,
        description:data.description || '',
        priority:data.priority || 'normal',
        status:data.status || 'backlog',
        requiresOwnerApproval:data.requiresOwnerApproval !== false,
        decisionNote:data.decisionNote || '',
        createdAt:timestamp(data.createdAt),
        updatedAt:timestamp(data.updatedAt),
      };
    });
    return {projectId:id, workItems, count:workItems.length};
  }
);

exports.updateNovaProjectPriority = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const id = projectIdFrom(request.data);
    const projectRef = projectCollection(uid).doc(id);
    const auditRef = auditCollection(uid).doc();
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(projectRef);
      if (!snapshot.exists) throw new HttpsError('not-found', 'لم يتم العثور على المشروع.');
      const current = snapshot.data() || {};
      const scoring = normalizeProjectScoring({
        strategicValue:request.data?.strategicValue ?? current.strategicValue,
        urgency:request.data?.urgency ?? current.urgency,
        confidence:request.data?.confidence ?? current.confidence,
        effort:request.data?.effort ?? current.effort,
        priority:request.data?.priority ?? current.priority,
      });
      tx.update(projectRef, {...scoring, priorityReviewedBy:uid,
        priorityReviewedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
      tx.create(auditRef, {
        action:'nova.project.priority_updated',
        actorUid:uid,
        projectId:id,
        priority:scoring.priority,
        priorityScore:scoring.priorityScore,
        strategicValue:scoring.strategicValue,
        urgency:scoring.urgency,
        confidence:scoring.confidence,
        effort:scoring.effort,
        createdAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, projectId:id, ...scoring};
    });
  }
);

exports.updateNovaProjectStatus = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const id = projectIdFrom(request.data);
    const nextStatus = String(request.data?.status || '').trim();
    const decisionNote = String(request.data?.decisionNote || '').trim();
    const ref = projectCollection(uid).doc(id);
    const auditRef = auditCollection(uid).doc();
    return db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) throw new HttpsError('not-found', 'لم يتم العثور على المشروع.');
      const current = snapshot.data() || {};
      let transition;
      try { transition = validateProjectTransition(current.status || 'idea', nextStatus, decisionNote); }
      catch (error) { throw new HttpsError('failed-precondition', error.message || 'انتقال الحالة غير مسموح.'); }
      tx.update(ref, {
        status:transition.status,
        decisionNote:transition.decisionNote,
        decisionBy:uid,
        decisionAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      });
      tx.create(auditRef, {
        action:'nova.project.status_changed',
        actorUid:uid,
        projectId:id,
        fromStatus:current.status || 'idea',
        toStatus:transition.status,
        decisionNote:transition.decisionNote,
        executionStarted:false,
        createdAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, projectId:id, status:transition.status, executionStarted:false};
    });
  }
);

exports.addNovaProjectWorkItem = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const id = projectIdFrom(request.data);
    let input;
    try { input = normalizeNovaWorkItemInput(request.data || {}); } catch (error) { invalidArgument(error); }
    const projectRef = projectCollection(uid).doc(id);
    const itemRef = projectRef.collection('workItems').doc();
    const auditRef = auditCollection(uid).doc();
    await db.runTransaction(async (tx) => {
      const project = await tx.get(projectRef);
      if (!project.exists) throw new HttpsError('not-found', 'لم يتم العثور على المشروع.');
      const projectData = project.data() || {};
      if (!['idea','active'].includes(projectData.status || 'idea')) {
        throw new HttpsError('failed-precondition', 'لا يمكن إضافة مهمة إلى مشروع متوقف أو مؤجل أو مغلق.');
      }
      tx.create(itemRef, {
        ...input,
        workItemId:itemRef.id,
        projectId:id,
        createdBy:uid,
        createdAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      });
      tx.update(projectRef, {updatedAt:FieldValue.serverTimestamp()});
      tx.create(auditRef, {
        action:'nova.project.work_item_created',
        actorUid:uid,
        projectId:id,
        workItemId:itemRef.id,
        title:input.title,
        status:'backlog',
        createdAt:FieldValue.serverTimestamp(),
      });
    });
    return {ok:true, projectId:id, workItemId:itemRef.id, status:'backlog', executionStarted:false};
  }
);

exports.updateNovaProjectWorkItem = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const id = projectIdFrom(request.data);
    const itemId = workItemIdFrom(request.data);
    const nextStatus = String(request.data?.status || '').trim();
    const decisionNote = String(request.data?.decisionNote || '').trim();
    const projectRef = projectCollection(uid).doc(id);
    const itemRef = projectRef.collection('workItems').doc(itemId);
    const auditRef = auditCollection(uid).doc();
    return db.runTransaction(async (tx) => {
      const project = await tx.get(projectRef);
      if (!project.exists) throw new HttpsError('not-found', 'لم يتم العثور على المشروع.');
      const item = await tx.get(itemRef);
      if (!item.exists) throw new HttpsError('not-found', 'لم يتم العثور على مهمة المشروع.');
      const current = item.data() || {};
      let transition;
      try { transition = validateWorkItemTransition(current.status || 'backlog', nextStatus, decisionNote); }
      catch (error) { throw new HttpsError('failed-precondition', error.message || 'انتقال حالة المهمة غير مسموح.'); }
      tx.update(itemRef, {
        status:transition.status,
        decisionNote:transition.decisionNote,
        decisionBy:uid,
        decisionAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      });
      tx.update(projectRef, {updatedAt:FieldValue.serverTimestamp()});
      tx.create(auditRef, {
        action:'nova.project.work_item_status_changed',
        actorUid:uid,
        projectId:id,
        workItemId:itemId,
        fromStatus:current.status || 'backlog',
        toStatus:transition.status,
        decisionNote:transition.decisionNote,
        createdAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, projectId:id, workItemId:itemId, status:transition.status, executionStarted:false};
    });
  }
);

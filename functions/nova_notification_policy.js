'use strict';

const MILESTONE_STATUSES = new Set([
  'succeeded',
  'completed',
  'failed',
  'blocked',
  'awaiting_approval',
]);

function buildNovaMilestoneNotification(status, taskType) {
  const type = String(taskType || 'المهمة').slice(0, 80);
  if (status === 'succeeded' || status === 'completed') {
    return {title:'🟢 اكتملت مهمة NOVA', body:'اكتملت ' + type + ' بنجاح. NOVA تتابع بقية المهام.'};
  }
  if (status === 'failed') {
    return {title:'تعطلت مهمة في NOVA', body:'تعطلت ' + type + '. افتح مركز المهام لمراجعة السبب.'};
  }
  if (status === 'blocked') {
    return {title:'مهمة NOVA تحتاج متابعة', body:'توقفت ' + type + ' بسبب عائق يحتاج معالجة.'};
  }
  if (status === 'awaiting_approval') {
    return {title:'موافقتك مطلوبة في NOVA', body:'تنتظر ' + type + ' موافقتك قبل الإجراء.'};
  }
  return null;
}

function shouldNotifyNovaCreation(status) {
  return status === 'awaiting_approval';
}

function shouldNotifyNovaTransition(beforeStatus, afterStatus) {
  return beforeStatus !== afterStatus && MILESTONE_STATUSES.has(afterStatus);
}

module.exports = {buildNovaMilestoneNotification, shouldNotifyNovaCreation, shouldNotifyNovaTransition};

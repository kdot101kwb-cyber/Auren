'use strict';

// Produces transparent departmental briefings and an executive roll-up.
// These are structured reports, not claims that a model agent ran or completed work.
const {DEPARTMENTS, routeNovaTask, getDepartment} = require('./nova_department_registry');

const DEPARTMENT_BRIEFS = Object.freeze({
  executive:{mission:'تنسيق الأولويات والقرارات والتقارير ورفع التوصيات للمالك.', plan:['تحديد الهدف والأولوية','مقارنة البدائل والوقت والتكلفة والمخاطر','رفع توصية وطلب قرار المالك']},
  security:{mission:'مراجعة أمن التطبيقات والخادم والصلاحيات والخصوصية.', plan:['تحديد نطاق الفحص المصرح','فرز المخاطر حسب الخطورة','توثيق الإصلاح وإعادة الاختبار']},
  engineering:{mission:'تحويل المتطلبات إلى تغييرات هندسية صغيرة قابلة للمراجعة.', plan:['فحص بنية المشروع','تنفيذ التغيير المحدد','تشغيل الاختبارات والبناء']},
  quality:{mission:'التحقق من المتطلبات بالأدلة والاختبارات وعدم إعلان النجاح دون نتيجة.', plan:['تعريف شروط القبول','تشغيل الاختبارات الملائمة','توثيق النتائج والفشل المتبقي']},
  research:{mission:'جمع المعلومات والتحقق من المصادر ومقارنة البدائل.', plan:['صياغة سؤال البحث','جمع مصادر موثوقة ومتنوعة','تلخيص الأدلة والشكوك والتوصية']},
  product:{mission:'تحويل احتياج المالك إلى تجربة واضحة قابلة للاختبار.', plan:['تحديد المستخدم والاحتياج','ترتيب القيمة والجهد','تحديد معايير القبول']},
  growth:{mission:'تحليل الجمهور والقنوات وتصميم تجارب نمو قابلة للقياس.', plan:['تحديد الجمهور والهدف','اقتراح تجربة منخفضة التكلفة','قياس النتائج قبل التوسع']},
  finance:{mission:'تقييم التكاليف والإيرادات والميزانيات والمخاطر المالية.', plan:['فصل الفعلي عن المتوقع','إعداد سيناريوهات مالية','توضيح الافتراضات والمخاطر']},
  legal:{mission:'رصد مسائل الامتثال والخصوصية والتراخيص وشروط المنصات.', plan:['تحديد الولاية والنطاق','مراجعة المتطلبات المتاحة','توثيق نقاط تحتاج مختصاً بشرياً']},
  operations:{mission:'تنظيم المهام والمتابعات والمسودات والتنسيق بين الإدارات.', plan:['تسجيل المطلوب والموعد','تحديد المسؤوليات والتبعيات','متابعة الحالة والتصعيد عند التعطل']},
  auren:{mission:'تنظيم برنامج AUREN وخارطة الطريق والملفات والتقدم.', plan:['مراجعة الأولويات وملفات المشروع','التحقق من PR وCI والأدلة','اقتراح الخطوة التالية والعوائق']},
});

function cleanText(value, max = 2000) {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}
function buildDepartmentBrief({departmentId, objective, evidence = [], blockers = [], proposedActions = [], status = 'planned', taskType = 'plan', externalSideEffect = false}) {
  const department = getDepartment(departmentId);
  if (!department) throw new TypeError('Unknown departmentId.');
  const context = cleanText(objective, 2000);
  if (!context) throw new TypeError('A clear objective is required.');
  if (!['planned','in_progress','blocked','completed','needs_owner_decision'].includes(status)) throw new TypeError('Unsupported report status.');
  const brief = DEPARTMENT_BRIEFS[departmentId];
  const route = routeNovaTask({type:taskType, externalSideEffect});
  const safeList = (values) => Array.isArray(values) ? values.filter((x) => typeof x === 'string').map((x) => cleanText(x, 500)).filter(Boolean).slice(0, 12) : [];
  const verifiedEvidence = safeList(evidence);
  const unresolvedBlockers = safeList(blockers);
  const actions = safeList(proposedActions);
  const actualStatus = status === 'completed' && verifiedEvidence.length === 0 ? 'in_progress' : status;
  return Object.freeze({
    schemaVersion:1,
    departmentId,
    departmentName:department.id,
    departmentHead:department.head,
    specialists:[...department.specialists],
    introduction:`أنا ${department.head}، رئيس هذه الإدارة. أرفع تقاريري إلى NOVA Chief Executive AI، وهو مسؤول أمامك مباشرة.`,
    mission:brief.mission,
    objective:context,
    plan:[...brief.plan],
    proposedActions:actions,
    evidence:verifiedEvidence,
    blockers:unresolvedBlockers,
    status:actualStatus,
    statusNote:actualStatus === 'in_progress' && status === 'completed'
      ? 'لم يُسجّل التقرير كمنجز لغياب دليل تحقق.'
      : actualStatus === 'completed'
        ? 'حالة منقولة من مقدم التقرير؛ راجع الأدلة قبل اعتماد الإنجاز.'
        : 'حالة تخطيطية/تشغيلية وليست إثباتاً مستقلاً على اكتمال العمل.',
    risk:route.risk,
    approvalRequired:route.approvalRequired,
    mayExecuteExternalAction:false,
    accountableTo:'user',
  });
}

function buildExecutiveRollup({objective, briefs = []}) {
  const goal = cleanText(objective, 2000);
  if (!goal) throw new TypeError('A clear executive objective is required.');
  if (!Array.isArray(briefs)) throw new TypeError('briefs must be an array.');
  const valid = briefs.filter((brief) => brief && getDepartment(brief.departmentId));
  const completed = valid.filter((brief) => brief.status === 'completed' && Array.isArray(brief.evidence) && brief.evidence.length > 0);
  const needsDecision = valid.filter((brief) => brief.approvalRequired || brief.status === 'needs_owner_decision');
  const blocked = valid.filter((brief) => brief.status === 'blocked' || (Array.isArray(brief.blockers) && brief.blockers.length > 0));
  const coveredIds = new Set(valid.map((brief) => brief.departmentId));
  return Object.freeze({
    schemaVersion:1,
    coordinator:'NOVA Chief Executive AI',
    accountableTo:'user',
    objective:goal,
    reportCount:valid.length,
    departmentsCovered:[...coveredIds],
    departmentsMissing:DEPARTMENTS.filter((d) => !coveredIds.has(d.id)).map((d) => d.id),
    verifiedCompletedCount:completed.length,
    blockedDepartments:blocked.map((brief) => ({departmentId:brief.departmentId, blockers:brief.blockers || []})),
    ownerDecisionsRequired:needsDecision.map((brief) => ({departmentId:brief.departmentId, departmentHead:brief.departmentHead, reason:brief.approvalRequired ? 'explicit_approval_required' : 'owner_decision_requested'})),
    nextStep:'Review missing department reports, verify evidence, resolve blockers, and ask the owner to approve any high-impact external action.',
    externalActionsExecuted:false,
  });
}

module.exports = {DEPARTMENT_BRIEFS, buildDepartmentBrief, buildExecutiveRollup};

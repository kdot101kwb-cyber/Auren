import 'package:cloud_firestore/cloud_firestore.dart';
import 'next_move_service.dart';

class AurenAutopilotStep {
  final int order;
  final String title;
  final String action;
  final String module;
  final bool requiresApproval;
  final String status;
  const AurenAutopilotStep({required this.order,required this.title,required this.action,required this.module,required this.requiresApproval,required this.status});
  Map<String,dynamic> toMap()=>{'order':order,'title':title,'action':action,'module':module,'requiresApproval':requiresApproval,'status':status};
  factory AurenAutopilotStep.fromMap(Map<String,dynamic> m)=>AurenAutopilotStep(
    order:(m['order'] as num?)?.toInt()??0,title:m['title']?.toString()??'',action:m['action']?.toString()??'',
    module:m['module']?.toString()??'',requiresApproval:m['requiresApproval']==true,status:m['status']?.toString()??'planned');
}

class AurenAutopilotPlan {
  final String goal;
  final String summary;
  final List<AurenAutopilotStep> steps;
  final DateTime? updatedAt;
  const AurenAutopilotPlan({required this.goal,required this.summary,required this.steps,required this.updatedAt});
  Map<String,dynamic> toMap()=>{'goal':goal,'summary':summary,'steps':steps.map((e)=>e.toMap()).toList(),'updatedAt':FieldValue.serverTimestamp()};
  factory AurenAutopilotPlan.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){
    final m=d.data()??{}; final raw=m['steps'];
    return AurenAutopilotPlan(
      goal:m['goal']?.toString()??'',summary:m['summary']?.toString()??'',
      steps:raw is List?raw.whereType<Map>().map((e)=>AurenAutopilotStep.fromMap(Map<String,dynamic>.from(e))).toList():const [],
      updatedAt:(m['updatedAt'] as Timestamp?)?.toDate());
  }
}

class AutopilotService {
  final FirebaseFirestore _db;
  final NextMoveService _nextMove;
  AutopilotService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance,_nextMove=NextMoveService(firestore:firestore);

  Stream<AurenAutopilotPlan?> watch(String uid)=>_db.collection('users').doc(uid).collection('autopilot').doc('current').snapshots().map((d)=>d.exists?AurenAutopilotPlan.fromDoc(d):null);

  Future<AurenAutopilotPlan> build(String uid) async {
    final clean=uid.trim(); if(clean.isEmpty) throw ArgumentError('uid is required');
    final move=await _nextMove.build(clean);
    final steps=<AurenAutopilotStep>[
      AurenAutopilotStep(order:1,title:'الخطوة التالية',action:move.action,module:move.module,requiresApproval:false,status:'ready'),
      const AurenAutopilotStep(order:2,title:'مراجعة النتيجة',action:'راجع نتيجة الخطوة وحدد هل نكمل للخطوة التالية.',module:'Personal AI',requiresApproval:false,status:'planned'),
      const AurenAutopilotStep(order:3,title:'إجراء حساس',action:'أي تنفيذ حساس يجب أن يمر عبر Action Center بموافقتك الصريحة.',module:'Action Center',requiresApproval:true,status:'approval_required'),
    ];
    final plan=AurenAutopilotPlan(goal:move.title,summary:'AUREN يقودك خطوة بخطوة باستخدام Next Move، مع توقف إلزامي قبل أي إجراء حساس.',steps:steps,updatedAt:DateTime.now());
    await _db.collection('users').doc(clean).collection('autopilot').doc('current').set(plan.toMap(),SetOptions(merge:true));
    return plan;
  }
}
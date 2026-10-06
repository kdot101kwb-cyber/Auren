import 'package:cloud_firestore/cloud_firestore.dart';

class AurenOrganizationItem {
  final String id;
  final String title;
  final String category;
  final String reason;
  const AurenOrganizationItem({required this.id,required this.title,required this.category,required this.reason});
  Map<String,dynamic> toMap()=>{'id':id,'title':title,'category':category,'reason':reason};
}

class AurenOrganizationPlan {
  final List<AurenOrganizationItem> items;
  final int memoryCount;
  final int activeGoalCount;
  const AurenOrganizationPlan({required this.items,required this.memoryCount,required this.activeGoalCount});
  Map<String,dynamic> toMap()=>{'items':items.map((e)=>e.toMap()).toList(),'memoryCount':memoryCount,'activeGoalCount':activeGoalCount,'updatedAt':FieldValue.serverTimestamp()};
}

class AutoOrganizeService {
  final FirebaseFirestore _db;
  AutoOrganizeService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String,dynamic>>> watch(String uid)=>
      _db.collection('users').doc(uid).collection('auto_organize').doc('current').snapshots();

  Future<AurenOrganizationPlan> build(String uid) async {
    final clean=uid.trim(); if(clean.isEmpty) throw ArgumentError('uid is required');
    final memorySnap=await _db.collection('users').doc(clean).collection('memory').orderBy('updatedAt',descending:true).limit(100).get();
    final goalSnap=await _db.collection('users').doc(clean).collection('goals').orderBy('updatedAt',descending:true).limit(100).get();
    final activeGoals=goalSnap.docs.where((d)=>(d.data()['status']?.toString()??'active')=='active').length;
    final items=<AurenOrganizationItem>[];
    for(final d in memorySnap.docs){
      final m=d.data(); final key=(m['key']?.toString()??'Memory').trim(); final value=(m['value']?.toString()??'').trim();
      final lower='$key $value'.toLowerCase();
      final category=lower.contains('work')||lower.contains('business')||lower.contains('job')||lower.contains('عمل')||lower.contains('شغل')?'Work & Business'
          :lower.contains('learn')||lower.contains('skill')||lower.contains('study')||lower.contains('تعلم')||lower.contains('مهارة')?'Learning'
          :lower.contains('travel')||lower.contains('trip')||lower.contains('سفر')||lower.contains('رحل')?'Travel'
          :lower.contains('health')||lower.contains('fitness')||lower.contains('صحة')||lower.contains('رياض')?'Health'
          :'Personal';
      items.add(AurenOrganizationItem(id:d.id,title:key,category:category,reason:'اقتراح تنظيمي مبني على كلمات الذاكرة؛ لم يتم حذف أو تغيير بياناتك.'));
    }
    for(final d in goalSnap.docs.take(20)){
      final m=d.data(); final title=m['title']?.toString()??'هدف';
      items.add(AurenOrganizationItem(id:d.id,title:title,category:'Goals',reason:'هدف محفوظ في مساحة الأهداف.'));
    }
    final plan=AurenOrganizationPlan(items:items,memoryCount:memorySnap.size,activeGoalCount:activeGoals);
    await _db.collection('users').doc(clean).collection('auto_organize').doc('current').set(plan.toMap(),SetOptions(merge:true));
    return plan;
  }
}
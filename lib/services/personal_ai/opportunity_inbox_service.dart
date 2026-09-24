import 'package:cloud_firestore/cloud_firestore.dart';
class AurenOpportunityInboxItem { final String id,title,description,category; const AurenOpportunityInboxItem({required this.id,required this.title,required this.description,required this.category}); }
class OpportunityInboxService {
 final FirebaseFirestore db; OpportunityInboxService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 Stream<List<AurenOpportunityInboxItem>> watch(String uid)=>db.collection('opportunities').where('visibility',isEqualTo:'public').limit(50).snapshots().map((s)=>s.docs.map((d){final x=d.data();return AurenOpportunityInboxItem(id:d.id,title:(x['title']??x['name']??'Opportunity').toString(),description:(x['description']??'').toString(),category:(x['category']??'General').toString());}).toList());
}
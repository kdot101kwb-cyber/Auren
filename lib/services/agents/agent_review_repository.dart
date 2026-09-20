import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/models/agent_review.dart';
class AurenAgentReviewRepository {
 final FirebaseFirestore _db; AurenAgentReviewRepository({FirebaseFirestore? db}):_db=db??FirebaseFirestore.instance;
 Stream<List<AurenAgentReview>> watch(String agentId)=>_db.collection('agent_reviews').where('agentId',isEqualTo:agentId).orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>AurenAgentReview.fromMap(d.id,d.data())).toList());
 Future<void> submit({required String agentId,required int rating,required String text}) async {
  if(rating<1||rating>5||text.trim().isEmpty||text.length>1000) throw ArgumentError('Invalid review');
  await FirebaseFunctions.instanceFor(region:'us-central1').httpsCallable('submitAurenAgentReview').call({'agentId':agentId,'rating':rating,'text':text.trim()});
 }
}

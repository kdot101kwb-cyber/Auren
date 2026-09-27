import 'package:cloud_firestore/cloud_firestore.dart';

class AurenGrowthService {
  final FirebaseFirestore db;
  AurenGrowthService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;

  CollectionReference<Map<String,dynamic>> _campaigns(String businessId)=>db.collection('businesses').doc(businessId).collection('growth_campaigns');
  Stream<List<Map<String,dynamic>>> watchCampaigns(String businessId)=>_campaigns(businessId).orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());

  Future<String> createCampaign({required String businessId,required String ownerId,required String name,required String goal,required String audience,required String channel,required String message})async{
    final n=name.trim(),g=goal.trim(),a=audience.trim(),m=message.trim();
    if(n.isEmpty||g.isEmpty)throw ArgumentError('اسم الحملة والهدف مطلوبان');
    final ref=_campaigns(businessId).doc();
    await ref.set({'businessId':businessId,'ownerId':ownerId,'name':n.length>120?n.substring(0,120):n,'goal':g.length>500?g.substring(0,500):g,'audience':a.length>300?a.substring(0,300):a,'channel':channel,'message':m.length>2000?m.substring(0,2000):m,'status':'draft','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateCampaignStatus({required String businessId,required String campaignId,required String status})async{
    if(!['draft','active','paused','completed'].contains(status))throw ArgumentError('حالة الحملة غير صالحة');
    await _campaigns(businessId).doc(campaignId).update({'status':status,'updatedAt':FieldValue.serverTimestamp()});
  }
}

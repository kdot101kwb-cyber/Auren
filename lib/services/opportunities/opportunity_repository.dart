import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/opportunity.dart';
class OpportunityRepository{final FirebaseFirestore db;OpportunityRepository({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
Stream<List<AurenOpportunity>> watchOpen({String query='',String type='All'}){final q=query.trim().toLowerCase();return db.collection('opportunities').where('status',isEqualTo:'open').limit(100).snapshots().map((s){final list=s.docs.map((d)=>AurenOpportunity.fromMap(d.id,d.data())).where((o)=>type=='All'||o.type==type).where((o)=>q.isEmpty||('${o.title} ${o.description} ${o.category} ${o.city} ${o.country} ${o.skills.join(' ')}').toLowerCase().contains(q)).toList();list.sort((a,b)=>(b.createdAt??DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt??DateTime.fromMillisecondsSinceEpoch(0)));return list;});}
Stream<bool> watchInterested(String uid, String opportunityId) => db.collection('users').doc(uid).collection('savedOpportunities').doc(opportunityId).snapshots().map((d) => d.exists);

Future<void> toggleInterest({required String uid, required String opportunityId, required bool interested, required Map<String, dynamic> snapshot}) async {
  if (uid.trim().isEmpty || opportunityId.trim().isEmpty) throw ArgumentError('بيانات الفرصة غير صالحة');
  final ref = db.collection('users').doc(uid).collection('savedOpportunities').doc(opportunityId);
  if (interested) {
    await ref.delete();
    return;
  }
  await ref.set({
    'opportunityId': opportunityId,
    'title': snapshot['title']?.toString() ?? '',
    'type': snapshot['type']?.toString() ?? 'opportunity',
    'category': snapshot['category']?.toString() ?? '',
    'city': snapshot['city']?.toString() ?? '',
    'country': snapshot['country']?.toString() ?? '',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<String> create({required String ownerId,required String title,required String description,required String type,required String category,required String city,required String country,required List<String> skills})async{final ref=db.collection('opportunities').doc();await ref.set({'ownerId':ownerId,'title':title.trim(),'description':description.trim(),'type':type,'category':category.trim(),'city':city.trim(),'country':country.trim(),'skills':skills.map((e)=>e.trim().toLowerCase()).where((e)=>e.isNotEmpty).take(20).toList(),'status':'open','createdAt':FieldValue.serverTimestamp()});return ref.id;}}
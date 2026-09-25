import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'random_connect_safety_service.dart';

class AurenRandomMatch {
  final String id,uid,displayName,country,language,interest,goal,status;
  const AurenRandomMatch({required this.id,required this.uid,required this.displayName,required this.country,required this.language,required this.interest,required this.goal,required this.status});
  factory AurenRandomMatch.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final m=d.data()??{};return AurenRandomMatch(id:d.id,uid:m['uid'] as String? ?? '',displayName:m['displayName'] as String? ?? 'AUREN User',country:m['country'] as String? ?? '',language:m['language'] as String? ?? '',interest:m['interest'] as String? ?? '',goal:m['goal'] as String? ?? '',status:m['status'] as String? ?? 'waiting');}
}
class AurenRandomConnectService {
 final FirebaseFirestore _db;
 AurenRandomConnectService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> get _c=>_db.collection('random_connect');
 Future<String> join({required String uid,required String displayName,required String country,required String language,required String interest,required String goal}) async {
   if (uid.isEmpty) throw StateError('not_authenticated');
   final callable = FirebaseFunctions.instance.httpsCallable('randomJoin');
   final result = await callable.call({
     'displayName': displayName,
     'country': country,
     'language': language,
     'interest': interest,
     'goal': goal,
   });
   final id = result.data is Map ? result.data['requestId'] as String? : null;
   if (id == null || id.isEmpty) throw StateError('random_join_failed');
   return id;
 }
 Stream<List<AurenRandomMatch>> watchWaiting({String country='',String language='',String interest='',String goal=''})=>_c.where('status',isEqualTo:'waiting').limit(50).snapshots().map((s){final rows=s.docs.map(AurenRandomMatch.fromDoc).toList();rows.sort((a,b)=>_score(b,country,language,interest,goal).compareTo(_score(a,country,language,interest,goal)));return rows.where((x)=>country.trim().isEmpty||x.country.toLowerCase()==country.trim().toLowerCase()||(language.trim().isNotEmpty&&x.language.toLowerCase()==language.trim().toLowerCase())).where((x)=>interest.trim().isEmpty||x.interest.toLowerCase().contains(interest.trim().toLowerCase())).where((x)=>goal.trim().isEmpty||x.goal.toLowerCase().contains(goal.trim().toLowerCase())).take(20).toList();});
 int _score(AurenRandomMatch x,String country,String language,String interest,String goal){var n=0;if(country.trim().isNotEmpty&&x.country.toLowerCase()==country.trim().toLowerCase())n+=25;if(language.trim().isNotEmpty&&x.language.toLowerCase()==language.trim().toLowerCase())n+=40;if(interest.trim().isNotEmpty&&x.interest.toLowerCase().contains(interest.trim().toLowerCase()))n+=20;if(goal.trim().isNotEmpty&&x.goal.toLowerCase().contains(goal.trim().toLowerCase()))n+=15;return n;}
 Future<void> cancel(String uid,String id)async{final r=_c.doc(id);final s=await r.get();if(s.exists&&s.data()?['uid']==uid)await r.update({'status':'cancelled'});}
 Future<String?> connect(String myUid,String id)async{final ref=_c.doc(id);return _db.runTransaction<String?>((tx)async{final snap=await tx.get(ref);final data=snap.data();if(!snap.exists||data==null||data['status']!='waiting')return null;final other=data['uid'] as String? ?? '';if(other.isEmpty||other==myUid)return null;if(await AurenRandomConnectSafetyService(firestore:_db).isBlockedEitherWay(myUid,other))return null;tx.update(ref,{'status':'matched','matchedWith':myUid,'matchedAt':FieldValue.serverTimestamp()});return other;});}
}
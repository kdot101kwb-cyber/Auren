import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'random_connect_safety_service.dart';

class AurenRandomMatch {
  final String id, uid, displayName, country, language, interest, goal, status;
  final int? age;
  final String activity, topic, photoUrl;
  const AurenRandomMatch({
    required this.id, required this.uid, required this.displayName,
    required this.country, required this.language, required this.interest,
    required this.goal, required this.status, this.age,
    this.activity = '', this.topic = '', this.photoUrl = '',
  });
  factory AurenRandomMatch.fromDoc(DocumentSnapshot<Map<String,dynamic>> d) {
    final m=d.data()??{};
    return AurenRandomMatch(
      id:d.id, uid:m['uid'] as String? ?? '',
      displayName:m['displayName'] as String? ?? 'AUREN User',
      country:m['country'] as String? ?? '', language:m['language'] as String? ?? '',
      interest:m['interest'] as String? ?? '', goal:m['goal'] as String? ?? '',
      status:m['status'] as String? ?? 'waiting',
      age:(m['age'] as num?)?.toInt(),
      activity:m['activity'] as String? ?? '', topic:m['topic'] as String? ?? '',
      photoUrl:m['photoUrl'] as String? ?? '',
    );
  }
}

class AurenRandomPresence {
  final bool online;
  final DateTime? lastSeen;
  const AurenRandomPresence({required this.online, this.lastSeen});
  factory AurenRandomPresence.fromDoc(DocumentSnapshot<Map<String,dynamic>> d) {
    final m=d.data()??{};
    final ts=m['lastSeen'];
    return AurenRandomPresence(
      online:m['online'] == true,
      lastSeen:ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class AurenRandomConnectService {
  final FirebaseFirestore _db;
  AurenRandomConnectService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get _c=>_db.collection('random_connect');

  Future<String> join({
    required String uid, required String displayName, required String country,
    required String language, required String interest, required String goal,
    int? age, String activity='', String topic='', String photoUrl='',
  }) async {
    if(uid.isEmpty) throw StateError('not_authenticated');
    final callable=FirebaseFunctions.instance.httpsCallable('randomJoin');
    final result=await callable.call({
      'displayName':displayName.trim(), 'country':country.trim(),
      'language':language.trim(), 'interest':interest.trim(), 'goal':goal.trim(),
      'age':age, 'activity':activity.trim(), 'topic':topic.trim(),
      'photoUrl':photoUrl.trim(),
    });
    final id=result.data is Map ? result.data['requestId'] as String? : null;
    if(id==null||id.isEmpty) throw StateError('random_join_failed');
    return id;
  }

  Stream<List<AurenRandomMatch>> watchWaiting({
    String country='', String language='', String interest='', String goal='',
    int? minAge, int? maxAge, String activity='', String topic='',
  }) => _c.where('status',isEqualTo:'waiting').limit(80).snapshots().map((s){
    final rows=s.docs.map(AurenRandomMatch.fromDoc).toList();
    rows.sort((a,b)=>_score(b,country,language,interest,goal,activity,topic).compareTo(_score(a,country,language,interest,goal,activity,topic)));
    return rows.where((x){
      final qAge=(x.age==null)||(minAge==null||x.age!>=minAge)&&(maxAge==null||x.age!<=maxAge);
      final qCountry=country.trim().isEmpty||x.country.toLowerCase()==country.trim().toLowerCase();
      final qLang=language.trim().isEmpty||x.language.toLowerCase()==language.trim().toLowerCase();
      final qInterest=interest.trim().isEmpty||x.interest.toLowerCase().contains(interest.trim().toLowerCase());
      final qGoal=goal.trim().isEmpty||x.goal.toLowerCase().contains(goal.trim().toLowerCase());
      final qActivity=activity.trim().isEmpty||x.activity.toLowerCase().contains(activity.trim().toLowerCase());
      final qTopic=topic.trim().isEmpty||x.topic.toLowerCase().contains(topic.trim().toLowerCase());
      return qAge&&qCountry&&qLang&&qInterest&&qGoal&&qActivity&&qTopic;
    }).take(30).toList();
  });

  int _score(AurenRandomMatch x,String country,String language,String interest,String goal,String activity,String topic){
    var n=0;
    if(country.trim().isNotEmpty&&x.country.toLowerCase()==country.trim().toLowerCase())n+=20;
    if(language.trim().isNotEmpty&&x.language.toLowerCase()==language.trim().toLowerCase())n+=30;
    if(interest.trim().isNotEmpty&&x.interest.toLowerCase().contains(interest.trim().toLowerCase()))n+=15;
    if(goal.trim().isNotEmpty&&x.goal.toLowerCase().contains(goal.trim().toLowerCase()))n+=15;
    if(activity.trim().isNotEmpty&&x.activity.toLowerCase().contains(activity.trim().toLowerCase()))n+=10;
    if(topic.trim().isNotEmpty&&x.topic.toLowerCase().contains(topic.trim().toLowerCase()))n+=10;
    return n;
  }

  int matchScore(AurenRandomMatch x,{String country='',String language='',String interest='',String goal='',String activity='',String topic=''})=>_score(x,country,language,interest,goal,activity,topic);

  List<String> matchReasons(AurenRandomMatch x,{String country='',String language='',String interest='',String goal='',String activity='',String topic=''}){
    final r=<String>[];
    if(language.trim().isNotEmpty&&x.language.toLowerCase()==language.trim().toLowerCase())r.add('نفس اللغة');
    if(country.trim().isNotEmpty&&x.country.toLowerCase()==country.trim().toLowerCase())r.add('نفس الدولة');
    if(interest.trim().isNotEmpty&&x.interest.toLowerCase().contains(interest.trim().toLowerCase()))r.add('اهتمام مشترك');
    if(goal.trim().isNotEmpty&&x.goal.toLowerCase().contains(goal.trim().toLowerCase()))r.add('هدف متقارب');
    if(activity.trim().isNotEmpty&&x.activity.toLowerCase().contains(activity.trim().toLowerCase()))r.add('نفس النشاط');
    if(topic.trim().isNotEmpty&&x.topic.toLowerCase().contains(topic.trim().toLowerCase()))r.add('موضوع مشترك');
    return r;
  }

  Future<void> setPresence(String uid,{required bool online}) async {
    if(uid.isEmpty)return;
    await _db.collection('users').doc(uid).collection('presence').doc('primary').set(
      {'online':online,'lastSeen':FieldValue.serverTimestamp()},
      SetOptions(merge:true),
    );
  }

  Stream<AurenRandomPresence> watchPresence(String uid) =>
      _db.collection('users').doc(uid).collection('presence').doc('primary')
        .snapshots().map(AurenRandomPresence.fromDoc);

  Future<void> cancel(String uid,String id)async{
    final r=_c.doc(id);final s=await r.get();
    if(s.exists&&s.data()?['uid']==uid)await r.update({'status':'cancelled','endedAt':FieldValue.serverTimestamp()});
  }

  Future<String?> connect(String myUid,String id)async{
    final ref=_c.doc(id);
    return _db.runTransaction<String?>((tx)async{
      final snap=await tx.get(ref);final data=snap.data();
      if(!snap.exists||data==null||data['status']!='waiting')return null;
      final other=data['uid'] as String? ?? '';
      if(other.isEmpty||other==myUid)return null;
      if(await AurenRandomConnectSafetyService(firestore:_db).isBlockedEitherWay(myUid,other))return null;
      tx.update(ref,{'status':'matched','matchedWith':myUid,'matchedAt':FieldValue.serverTimestamp()});
      return other;
    });
  }

  Future<void> finishRequest(String uid,String id)async{
    final ref=_c.doc(id);final s=await ref.get();
    if(!s.exists||s.data()?['uid']!=uid)return;
    final status=s.data()?['status'];
    if(status=='waiting'||status=='matched')await ref.update({'status':'ended','endedAt':FieldValue.serverTimestamp()});
  }

  CollectionReference<Map<String,dynamic>> _history(String uid)=>_db.collection('users').doc(uid).collection('random_sessions');
  Future<void> recordSession({required String uid,required String otherUid,required String otherName,required String action,required String kind}) async {
    if(uid.isEmpty||otherUid.isEmpty||uid==otherUid)return;
    final n=otherName.trim();
    await _history(uid).add({'otherUid':otherUid,'otherName':n.isEmpty?'AUREN User':n.substring(0,n.length>80?80:n.length),'action':action,'kind':kind,'createdAt':FieldValue.serverTimestamp()});
  }
  Stream<List<Map<String,dynamic>>> watchHistory(String uid)=>_history(uid).orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>{...d.data(),'id':d.id}).toList());

  Stream<List<Map<String,dynamic>>> watchNotifications(String uid)=>
      _db.collection('users').doc(uid).collection('random_notifications')
        .orderBy('createdAt',descending:true).limit(30).snapshots()
        .map((s)=>s.docs.map((d)=>{...d.data(),'id':d.id}).toList());

  Future<void> markNotificationRead(String uid,String id) async {
    if(uid.isEmpty||id.isEmpty)return;
    await _db.collection('users').doc(uid).collection('random_notifications').doc(id).update({'read':true});
  }
}

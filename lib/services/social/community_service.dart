import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AurenCommunity {
  final String id, ownerId, name, description, topic, visibility;
  final List<String> memberIds;
  final int memberCount;
  final DateTime createdAt;
  const AurenCommunity({required this.id,required this.ownerId,required this.name,required this.description,required this.topic,required this.visibility,required this.memberIds,required this.memberCount,required this.createdAt});
  factory AurenCommunity.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){
    final m=d.data()??{};
    return AurenCommunity(id:d.id,ownerId:(m['ownerId']??'') as String,name:(m['name']??'') as String,description:(m['description']??'') as String,topic:(m['topic']??'') as String,visibility:(m['visibility']??'public') as String,memberIds:List<String>.from(m['memberIds']??const []),memberCount:(m['memberCount']??0) as int,createdAt:(m['createdAt'] as Timestamp?)?.toDate()??DateTime.fromMillisecondsSinceEpoch(0));
  }
}

class AurenCommunityPoll {
  final String id, communityId, ownerId, question;
  final List<String> options;
  final Map<String,int> votes;
  final Map<String,String> voters;
  final DateTime createdAt;
  const AurenCommunityPoll({required this.id,required this.communityId,required this.ownerId,required this.question,required this.options,required this.votes,required this.voters,required this.createdAt});
  factory AurenCommunityPoll.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final m=d.data()??{};return AurenCommunityPoll(id:d.id,communityId:m['communityId'] as String? ?? '',ownerId:m['ownerId'] as String? ?? '',question:m['question'] as String? ?? '',options:List<String>.from(m['options']??const []),votes:Map<String,int>.from((m['votes']??const {}).map((k,v)=>MapEntry(k.toString(),(v as num).toInt()))),voters:Map<String,String>.from(m['voters']??const {}),createdAt:(m['createdAt'] as Timestamp?)?.toDate()??DateTime.fromMillisecondsSinceEpoch(0));}
}
class AurenCommunityService {
  final FirebaseFirestore _db; final FirebaseAuth _auth;
  AurenCommunityService({FirebaseFirestore? db,FirebaseAuth? auth}):_db=db??FirebaseFirestore.instance,_auth=auth??FirebaseAuth.instance;
  String get uid=>_auth.currentUser?.uid??(throw StateError('Sign in required'));
  Stream<List<AurenCommunity>> watchPublic({String query=''}){final q=query.trim().toLowerCase();return _db.collection('communities').where('visibility',isEqualTo:'public').limit(50).snapshots().map((s){final all=s.docs.map(AurenCommunity.fromDoc);if(q.isEmpty){final list=all.toList();list.sort((a,b)=>b.memberCount.compareTo(a.memberCount));return list;}return all.where((c)=>(c.name+' '+c.description+' '+c.topic).toLowerCase().contains(q)).toList();});}
  Stream<AurenCommunity?> watch(String id) => _db.collection('communities').doc(id).snapshots().map((d) => d.exists ? AurenCommunity.fromDoc(d) : null);

  Future<String> create({required String name,required String description,required String topic}) async{
    final n=name.trim(),d=description.trim(),t=topic.trim();if(n.isEmpty||n.length>80)throw ArgumentError('Community name must be 1–80 characters.');if(d.length>500||t.length>80)throw ArgumentError('Community text is too long.');
    final ref=_db.collection('communities').doc();await ref.set({'ownerId':uid,'name':n,'description':d,'topic':t,'visibility':'public','memberIds':[uid],'memberCount':1,'createdAt':FieldValue.serverTimestamp()});return ref.id;
  }
  Future<void> join(String id) async{final ref=_db.collection('communities').doc(id);await _db.runTransaction((tx)async{final snap=await tx.get(ref);if(!snap.exists)throw StateError('Community not found.');final data=snap.data()!;final members=List<String>.from(data['memberIds']??const []);if(members.contains(uid))return;if(members.length>=10000)throw StateError('Community is full.');members.add(uid);tx.update(ref,{'memberIds':members,'memberCount':members.length});});}
  Future<void> removeMember({required String communityId, required String memberUid}) async{
    if(memberUid.trim().isEmpty || memberUid == uid) throw StateError('Invalid member.');
    final ref=_db.collection('communities').doc(communityId);
    await _db.runTransaction((tx) async{
      final snap=await tx.get(ref); if(!snap.exists) throw StateError('Community not found.');
      final data=snap.data()!;
      if(data['ownerId'] != uid) throw StateError('Only the owner can remove members.');
      final members=List<String>.from(data['memberIds'] ?? const []);
      if(!members.remove(memberUid)) return;
      tx.update(ref, {'memberIds':members,'memberCount':members.length});
    });
  }
  CollectionReference<Map<String,dynamic>> get _polls => _db.collection('community_polls');

  Stream<List<AurenCommunityPoll>> watchPolls(String communityId) => _polls.where('communityId', isEqualTo: communityId).orderBy('createdAt', descending: true).limit(30).snapshots().map((s) => s.docs.map(AurenCommunityPoll.fromDoc).toList());

  Future<String> createPoll({required String communityId, required String question, required List<String> options}) async {
    final q=question.trim();
    final clean=options.map((x)=>x.trim()).where((x)=>x.isNotEmpty).take(6).toList();
    if(q.isEmpty || q.length>240 || clean.length<2) throw ArgumentError('Invalid poll.');
    final ref=_polls.doc();
    await ref.set({'communityId':communityId,'ownerId':uid,'question':q,'options':clean,'votes':<String,int>{for(var i=0;i<clean.length;i++)'$i':0},'voters':<String,String>{},'createdAt':FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> votePoll({required String pollId, required int optionIndex}) async {
    if(optionIndex<0) throw ArgumentError('Invalid option.');
    final ref=_polls.doc(pollId);
    await _db.runTransaction((tx) async {
      final snap=await tx.get(ref); if(!snap.exists) throw StateError('Poll not found.');
      final data=snap.data()!;
      final voters=Map<String,String>.from(data['voters']??const {});
      final options=List<String>.from(data['options']??const []);
      if(optionIndex>=options.length) throw ArgumentError('Invalid option.');
      final communityId=data['communityId'] as String? ?? '';
      final community=await tx.get(_db.collection('communities').doc(communityId));
      final members=List<String>.from(community.data()?['memberIds']??const []);
      if(!members.contains(uid)) throw StateError('Join the community first.');
      if(voters.containsKey(uid)) throw StateError('You already voted.');
      final votes=Map<String,int>.from((data['votes']??const {}).map((k,v)=>MapEntry(k.toString(),(v as num).toInt())));
      final key='$optionIndex'; votes[key]=(votes[key]??0)+1; voters[uid]=key;
      tx.update(ref,{'votes':votes,'voters':voters});
    });
  }

  Future<void> leave(String id) async{final ref=_db.collection('communities').doc(id);await _db.runTransaction((tx)async{final snap=await tx.get(ref);if(!snap.exists)return;final data=snap.data()!;if(data['ownerId']==uid)throw StateError('Owner cannot leave their community.');final members=List<String>.from(data['memberIds']??const []);if(!members.remove(uid))return;tx.update(ref,{'memberIds':members,'memberCount':members.length});});}
}

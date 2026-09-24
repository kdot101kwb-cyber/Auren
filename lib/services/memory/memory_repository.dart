import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/memory_item.dart';
import 'memory_timeline_repository.dart';

class MemoryRepository {
 final FirebaseFirestore _db;
 final MemoryTimelineRepository _timeline;
 MemoryRepository({FirebaseFirestore? firestore})
     : _db=firestore??FirebaseFirestore.instance,
       _timeline=MemoryTimelineRepository(firestore: firestore);

 CollectionReference<Map<String,dynamic>> _items(String uid)=>_db.collection('users').doc(uid).collection('memory');

 Stream<List<AurenMemoryItem>> watch(String uid)=>_items(uid).orderBy('updatedAt',descending:true).snapshots().map((s)=>s.docs.map((d)=>AurenMemoryItem.fromMap(d.id,d.data())).toList());

 Future<void> upsert(String uid,AurenMemoryItem item) async {
   final ref=_items(uid).doc(item.id);
   final existed=(await ref.get()).exists;
   await ref.set(item.toMap());
   await _timeline.record(uid: uid,memoryId:item.id,key:item.key,value:item.value,action:existed?'updated':'created');
 }

 Future<void> delete(String uid,String id) async {
   final ref=_items(uid).doc(id);
   final snap=await ref.get();
   if(!snap.exists) return;
   final data=snap.data()??<String,dynamic>{};
   await ref.delete();
   await _timeline.record(uid:uid,memoryId:id,key:data['key']?.toString()??'Memory',value:data['value']?.toString()??'',action:'deleted');
 }
}
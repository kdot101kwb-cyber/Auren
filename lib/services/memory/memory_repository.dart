import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/memory_item.dart';
class MemoryRepository {
 final FirebaseFirestore _db;
 MemoryRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> _items(String uid)=>_db.collection('users').doc(uid).collection('memory');
 Stream<List<AurenMemoryItem>> watch(String uid)=>_items(uid).orderBy('updatedAt',descending:true).snapshots().map((s)=>s.docs.map((d)=>AurenMemoryItem.fromMap(d.id,d.data())).toList());
 Future<void> upsert(String uid,AurenMemoryItem item)=>_items(uid).doc(item.id).set(item.toMap());
 Future<void> delete(String uid,String id)=>_items(uid).doc(id).delete();
}
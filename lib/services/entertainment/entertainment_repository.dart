import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/entertainment.dart';

class EntertainmentRepository {
  final FirebaseFirestore db;
  EntertainmentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenEntertainmentItem>> searchEntertainment(String query) {
    final terms=query.trim().toLowerCase().split(' ').where((v)=>v.isNotEmpty).toList();
    if(terms.isEmpty) return watchItems();
    return watchItems().map((items)=>items.where((item){
      final hay='${item.title} ${item.description} ${item.type} ${item.country} ${item.language} ${item.year} ${item.genres.join(' ')} ${item.artistName} ${item.albumName} ${item.source}'.toLowerCase();
      return terms.every(hay.contains);
    }).toList()
      ..sort((a, b) {
        final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
      });
  }

  Stream<List<AurenEntertainmentItem>> watchAiRecommendations(String uid) {
    return db.collection('entertainment_items').where('visibility',isEqualTo:'public').limit(100).snapshots().asyncMap((snap) async {
      final items=snap.docs.map((d)=>AurenEntertainmentItem.fromMap(d.id,d.data())).where((i)=>i.mediaUrl.isNotEmpty).toList();
      final signals=await db.collection('users').doc(uid).collection('entertainmentSignals').get();
      final scores=<String,double>{};
      for(final d in signals.docs){final data=d.data();scores[d.id]=((data['watchSeconds'] as num?)?.toDouble()??0)*.02+((data['likes'] as num?)?.toDouble()??0)*5+((data['saves'] as num?)?.toDouble()??0)*4+((data['completions'] as num?)?.toDouble()??0)*3-((data['skips'] as num?)?.toDouble()??0)*2;}
      items.sort((a,b)=>(scores[b.id]??0).compareTo(scores[a.id]??0)); return items;
    });
  }

  Future<String> createWatchTogetherRoom(String uid, {required String itemId, required String title}) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) throw StateError('سجّل الدخول أولاً.');
    if (uid != currentUid) throw StateError('لا يمكن إنشاء غرفة باسم مستخدم آخر.');
    final safeItemId = itemId.trim();
    if (safeItemId.isEmpty) throw StateError('المحتوى المطلوب للمشاهدة غير صالح.');
    final ref = db.collection('watchTogetherRooms').doc();
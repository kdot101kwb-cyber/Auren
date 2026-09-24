import 'package:cloud_firestore/cloud_firestore.dart';

class AurenHabit{
 final String id,name; final bool active; final List<String> dates;
 const AurenHabit({required this.id,required this.name,required this.active,required this.dates});
 int get streak{final s=dates.toSet();var d=DateTime.now().toUtc();var n=0;while(s.contains(_key(d))){n++;d=d.subtract(const Duration(days:1));}return n;}
 static String _key(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
 Map<String,dynamic> toMap()=>{'name':name,'active':active,'dates':dates,'updatedAt':FieldValue.serverTimestamp()};
 static AurenHabit fromMap(String id,Map<String,dynamic> m)=>AurenHabit(id:id,name:m['name'] as String? ?? '',active:m['active'] as bool? ?? true,dates:List<String>.from(m['dates'] as List? ?? const[]));
}
class HabitService{
 final FirebaseFirestore db; HabitService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> _c(String uid)=>db.collection('users').doc(uid).collection('habits');
 Stream<List<AurenHabit>> watch(String uid)=>_c(uid).orderBy('updatedAt',descending:true).snapshots().map((s)=>s.docs.map((d)=>AurenHabit.fromMap(d.id,d.data())).toList());
 Future<void> create(String uid,String name)async{final r=_c(uid).doc();await r.set(AurenHabit(id:r.id,name:name.trim(),active:true,dates:const[]).toMap());}
 Future<void> toggleToday(String uid,AurenHabit h)async{final key=AurenHabit._key(DateTime.now().toUtc());final d=[...h.dates];if(d.contains(key)){d.remove(key);}else{d.add(key);}await _c(uid).doc(h.id).update({'dates':d,'updatedAt':FieldValue.serverTimestamp()});}
 Future<void> setActive(String uid,AurenHabit h,bool value)=>_c(uid).doc(h.id).update({'active':value,'updatedAt':FieldValue.serverTimestamp()});
 Future<void> delete(String uid,String id)=>_c(uid).doc(id).delete();
}
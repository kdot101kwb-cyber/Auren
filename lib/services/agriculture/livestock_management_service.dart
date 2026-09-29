import 'package:cloud_firestore/cloud_firestore.dart';

class LivestockAnimal {
  final String id;
  final String tag;
  final String species;
  final String breed;
  final String sex;
  final String status;
  final DateTime? birthDate;
  final double? weightKg;
  final Map<String,dynamic> data;
  const LivestockAnimal({required this.id,required this.tag,required this.species,required this.breed,required this.sex,required this.status,required this.birthDate,required this.weightKg,required this.data});

  factory LivestockAnimal.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc) {
    final d=doc.data() ?? const {};
    return LivestockAnimal(
      id:doc.id, tag:'${d['tag'] ?? doc.id}', species:'${d['species'] ?? 'unknown'}',
      breed:'${d['breed'] ?? ''}', sex:'${d['sex'] ?? ''}', status:'${d['status'] ?? 'active'}',
      birthDate:(d['birthDate'] as Timestamp?)?.toDate(), weightKg:(d['weightKg'] as num?)?.toDouble(), data:d);
  }
}

class LivestockManagementService {
  final FirebaseFirestore db;
  LivestockManagementService({FirebaseFirestore? firestore}):db=firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String,dynamic>> _animals(String uid)=>db.collection('users').doc(uid).collection('livestockAnimals');
  CollectionReference<Map<String,dynamic>> _events(String uid)=>db.collection('users').doc(uid).collection('livestockEvents');

  Stream<List<LivestockAnimal>> watchAnimals(String uid,{String? species}) {
    Query<Map<String,dynamic>> q=_animals(uid).orderBy('createdAt',descending:true).limit(300);
    if(species!=null && species.isNotEmpty && species!='all') q=q.where('species',isEqualTo:species);
    return q.snapshots().map((s)=>s.docs.map(LivestockAnimal.fromDoc).toList());
  }

  Future<String> addAnimal(String uid,{required String tag,required String species,required String breed,required String sex,DateTime? birthDate,double? weightKg}) async {
    final ref=_animals(uid).doc();
    await ref.set({
      'tag':tag.trim(),'species':species.trim(),'breed':breed.trim(),'sex':sex.trim(),'status':'active',
      if(birthDate!=null)'birthDate':Timestamp.fromDate(birthDate),
      if(weightKg!=null)'weightKg':weightKg,
      'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> recordEvent(String uid,{required String animalId,required String type,required Map<String,dynamic> data}) async {
    final ref=_events(uid).doc();
    await ref.set({
      'animalId':animalId,'type':type,'data':data,'createdAt':FieldValue.serverTimestamp(),
    });
    final updates=<String,dynamic>{'updatedAt':FieldValue.serverTimestamp()};
    if(type=='weight' && data['weightKg'] is num) updates['weightKg']=(data['weightKg'] as num).toDouble();
    if(type=='death') updates['status']='deceased';
    await _animals(uid).doc(animalId).set(updates,SetOptions(merge:true));
  }

  Stream<QuerySnapshot<Map<String,dynamic>>> watchEvents(String uid,String animalId) =>
      _events(uid).where('animalId',isEqualTo:animalId).orderBy('createdAt',descending:true).limit(100).snapshots();

  Future<void> updateAnimal(String uid,String animalId,Map<String,dynamic> updates) =>
      _animals(uid).doc(animalId).set({...updates,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
}

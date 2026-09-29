import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ProductionLifecycleService {
  final FirebaseFirestore db;
  final FirebaseFunctions functions;
  ProductionLifecycleService({FirebaseFirestore? firestore, FirebaseFunctions? cloudFunctions}) : db = firestore ?? FirebaseFirestore.instance, functions = cloudFunctions ?? FirebaseFunctions.instance;
  CollectionReference<Map<String,dynamic>> _history(String uid) => db.collection('users').doc(uid).collection('productionHistory');
  CollectionReference<Map<String,dynamic>> _outputs(String uid) => db.collection('users').doc(uid).collection('outputLibrary');
  Stream<List<Map<String,dynamic>>> watchHistory(String uid) => _history(uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Stream<List<Map<String,dynamic>>> watchOutputs(String uid) => _outputs(uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Future<Map<String,dynamic>> cancel(String taskPath) async => Map<String,dynamic>.from((await functions.httpsCallable('cancelAurenProduction').call({'taskPath':taskPath})).data);
  Future<Map<String,dynamic>> retry(String taskPath) async => Map<String,dynamic>.from((await functions.httpsCallable('retryAurenProduction').call({'taskPath':taskPath})).data);
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AurenContextState {
  final String mode,label,description;
  final DateTime updatedAt;
  const AurenContextState({required this.mode,required this.label,required this.description,required this.updatedAt});
}

class ContextSwitchService {
  final FirebaseFirestore _db;
  ContextSwitchService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;

  Future<AurenContextState> switchTo(String uid,{required String mode,required String label,String description=''}) async {
    if(uid.trim().isEmpty) throw ArgumentError('uid is required');
    const allowed={'work','learning','travel','personal'};
    if(!allowed.contains(mode)) throw ArgumentError('unsupported context');
    final cleanLabel=label.trim();
    if(cleanLabel.isEmpty||cleanLabel.length>80) throw ArgumentError('label is invalid');
    final state=AurenContextState(mode:mode,label:cleanLabel,description:description.trim().substring(0,description.trim().length>300?300:description.trim().length),updatedAt:DateTime.now());
    await _db.collection('users').doc(uid).collection('context_switch').doc('current').set({
      'mode':state.mode,'label':state.label,'description':state.description,'updatedAt':Timestamp.fromDate(state.updatedAt.toUtc()),
    });
    return state;
  }

  Stream<AurenContextState?> watch(String uid)=>_db.collection('users').doc(uid).collection('context_switch').doc('current').snapshots().map((d){
    if(!d.exists||d.data()==null)return null; final x=d.data()!;
    final ts=x['updatedAt']; return AurenContextState(mode:x['mode'] as String,label:x['label'] as String,description:(x['description'] as String?)??'',updatedAt:ts is Timestamp?ts.toDate():DateTime.now());
  });
}
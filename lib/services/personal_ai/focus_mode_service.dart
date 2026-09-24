import 'package:cloud_firestore/cloud_firestore.dart';
class AurenFocusSession{final String goalId,title;final int minutes;final DateTime startedAt;final bool active;
const AurenFocusSession({required this.goalId,required this.title,required this.minutes,required this.startedAt,required this.active});
Map<String,dynamic> toMap()=>{'goalId':goalId,'title':title,'minutes':minutes,'startedAt':Timestamp.fromDate(startedAt.toUtc()),'active':active};}
class FocusModeService{final FirebaseFirestore _db;FocusModeService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
Future<AurenFocusSession> start(String uid,{required String goalId,required String title,required int minutes})async{final s=AurenFocusSession(goalId:goalId,title:title,minutes:minutes,startedAt:DateTime.now(),active:true);await _db.collection('users').doc(uid).collection('focus_sessions').doc('current').set(s.toMap());return s;}
Future<void> stop(String uid)=>_db.collection('users').doc(uid).collection('focus_sessions').doc('current').set({'active':false,'endedAt':Timestamp.now()},SetOptions(merge:true));}
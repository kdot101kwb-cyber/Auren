import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/entertainment/models/auren_production_models.dart';

class AurenProductionService {
  AurenProductionService._();
  static final instance=AurenProductionService._();
  final FirebaseFirestore _db=FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> _jobs(String uid)=>_db.collection('users').doc(uid).collection('production_jobs');
  Stream<List<AurenProductionJob>> watchJobs(String uid)=>_jobs(uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map(AurenProductionJob.fromDoc).toList());
  Future<String> createJob({required String uid,required String title,required AurenProductionType type,required int targetMinutes,AurenVideoEngine engine=AurenVideoEngine.skyReelsV3,String? seriesId,String? episodeId}) async {
    final ref=_jobs(uid).doc();
    await ref.set({'uid':uid,'title':title.trim().isEmpty?'AUREN Production':title.trim(),'type':type.name,'status':AurenProductionStatus.queued.name,'engine':engine.name,'targetMinutes':targetMinutes.clamp(1,240),'progress':0,'seriesId':seriesId,'episodeId':episodeId,'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),'retryCount':0,'cancelRequested':false});
    return ref.id;
  }
  Future<void> requestCancel(String uid,String jobId)=>_jobs(uid).doc(jobId).update({'cancelRequested':true,'status':AurenProductionStatus.cancelled.name,'updatedAt':FieldValue.serverTimestamp()});
  Future<void> retry(String uid,AurenProductionJob job)=>_jobs(uid).doc(job.id).update({'status':AurenProductionStatus.queued.name,'progress':0,'error':null,'cancelRequested':false,'retryCount':FieldValue.increment(1),'updatedAt':FieldValue.serverTimestamp()});
  Future<void> saveWorkerUpdate({required String uid,required String jobId,required AurenProductionStatus status,required int progress,String? outputUrl,String? error})=>_jobs(uid).doc(jobId).update({'status':status.name,'progress':progress.clamp(0,100),if(outputUrl!=null)'outputUrl':outputUrl,if(error!=null)'error':error,'updatedAt':FieldValue.serverTimestamp()});
}
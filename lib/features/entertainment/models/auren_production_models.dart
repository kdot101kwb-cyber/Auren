import 'package:cloud_firestore/cloud_firestore.dart';

enum AurenProductionType { short, film, seriesEpisode }
enum AurenProductionStatus { queued, planning, generating, assembling, review, completed, failed, cancelled }
enum AurenVideoEngine { moneyPrinterTurbo, skyReelsV3, skyReelsV2, ltx2, wan, hunyuan }

class AurenProductionJob {
  final String id, uid, title;
  final AurenProductionType type;
  final AurenProductionStatus status;
  final AurenVideoEngine engine;
  final int targetMinutes, progress;
  final String? episodeId, outputUrl, error;
  final DateTime createdAt;
  const AurenProductionJob({required this.id,required this.uid,required this.title,required this.type,required this.status,required this.engine,required this.targetMinutes,required this.progress,required this.createdAt,this.episodeId,this.outputUrl,this.error});
  factory AurenProductionJob.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc) {
    final d=doc.data()??<String,dynamic>{};
    return AurenProductionJob(
      id:doc.id, uid:d['uid'] as String? ?? '', title:d['title'] as String? ?? 'Untitled',
      type:AurenProductionType.values.firstWhere((v)=>v.name==d['type'],orElse:()=>AurenProductionType.short),
      status:AurenProductionStatus.values.firstWhere((v)=>v.name==d['status'],orElse:()=>AurenProductionStatus.queued),
      engine:AurenVideoEngine.values.firstWhere((v)=>v.name==d['engine'],orElse:()=>AurenVideoEngine.moneyPrinterTurbo),
      targetMinutes:(d['targetMinutes'] as num?)?.toInt()??1, progress:(d['progress'] as num?)?.toInt()??0,
      episodeId:d['episodeId'] as String?, outputUrl:d['outputUrl'] as String?, error:d['error'] as String?,
      createdAt:(d['createdAt'] as Timestamp?)?.toDate()??DateTime.now(),
    );
  }
}
extension AurenProductionLabels on AurenProductionType {
  String get label=>switch(this){AurenProductionType.short=>'Short',AurenProductionType.film=>'Film',AurenProductionType.seriesEpisode=>'Series episode'};
}
extension AurenEngineLabels on AurenVideoEngine {
  String get label=>switch(this){AurenVideoEngine.moneyPrinterTurbo=>'MoneyPrinterTurbo',AurenVideoEngine.skyReelsV3=>'SkyReels V3',AurenVideoEngine.skyReelsV2=>'SkyReels V2',AurenVideoEngine.ltx2=>'LTX-2',AurenVideoEngine.wan=>'Wan',AurenVideoEngine.hunyuan=>'HunyuanVideo'};
}
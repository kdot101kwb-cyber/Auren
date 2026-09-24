import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTalentScoutFinding {
  final String id, ownerId, scoutId, type, title, description, sourceType, sourceId, status;
  final int score;
  final List<String> matchedSkills, missingSkills;
  final DateTime? createdAt, expiresAt;
  const AurenTalentScoutFinding({required this.id,required this.ownerId,required this.scoutId,required this.type,required this.title,required this.description,required this.sourceType,required this.sourceId,required this.status,required this.score,required this.matchedSkills,required this.missingSkills,this.createdAt,this.expiresAt});
  factory AurenTalentScoutFinding.fromMap(String id,Map<String,dynamic> d)=>AurenTalentScoutFinding(
    id:id,ownerId:d['ownerId']?.toString()??'',scoutId:d['scoutId']?.toString()??'',type:d['type']?.toString()??'opportunity',title:d['title']?.toString()??'',description:d['description']?.toString()??'',sourceType:d['sourceType']?.toString()??'',sourceId:d['sourceId']?.toString()??'',status:d['status']?.toString()??'new',
    score:d['score'] is int?d['score'] as int:int.tryParse('${d['score']}')??0,
    matchedSkills:d['matchedSkills'] is List?List<String>.from((d['matchedSkills'] as List).map((e)=>e.toString()).take(30)):const [],
    missingSkills:d['missingSkills'] is List?List<String>.from((d['missingSkills'] as List).map((e)=>e.toString()).take(30)):const [],
    createdAt:d['createdAt'] is Timestamp?(d['createdAt'] as Timestamp).toDate():null,expiresAt:d['expiresAt'] is Timestamp?(d['expiresAt'] as Timestamp).toDate():null);
}

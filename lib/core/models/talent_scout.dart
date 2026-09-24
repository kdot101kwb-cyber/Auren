import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTalentScout {
  final String id, ownerId, name, role, description;
  final bool enabled;
  final List<String> interests, skills;
  final DateTime? updatedAt;
  const AurenTalentScout({required this.id,required this.ownerId,required this.name,required this.role,required this.description,required this.enabled,required this.interests,required this.skills,this.updatedAt});
  factory AurenTalentScout.fromMap(String id,Map<String,dynamic> d)=>AurenTalentScout(id:id,ownerId:d['ownerId']?.toString()??'',name:d['name']?.toString()??'',role:d['role']?.toString()??'opportunity',description:d['description']?.toString()??'',enabled:d['enabled']==true,interests:d['interests'] is List?List<String>.from((d['interests'] as List).map((e)=>e.toString()).take(20)):const [],skills:d['skills'] is List?List<String>.from((d['skills'] as List).map((e)=>e.toString()).take(30)):const [],updatedAt:d['updatedAt'] is Timestamp?(d['updatedAt'] as Timestamp).toDate():null);
}
import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTalent {
  final String id, ownerId, displayName, bio, category, sport, discipline, level, city, country, status;
  final List<String> skills, achievements, goals, sports;
  final DateTime? updatedAt;

  const AurenTalent({
    required this.id, required this.ownerId, required this.displayName, required this.bio,
    required this.category, required this.sport, required this.discipline, required this.level,
    required this.city, required this.country, required this.status, required this.skills, required this.sports,
    required this.achievements, required this.goals, this.updatedAt,
  });

  factory AurenTalent.fromMap(String id, Map<String, dynamic> d) => AurenTalent(
    id: id, ownerId: d['ownerId']?.toString() ?? '', displayName: d['displayName']?.toString() ?? '',
    bio: d['bio']?.toString() ?? '', category: d['category']?.toString() ?? '',
    sport: d['sport']?.toString() ?? d['category']?.toString() ?? '',
    discipline: d['discipline']?.toString() ?? '', level: d['level']?.toString() ?? '',
    city: d['city']?.toString() ?? '', country: d['country']?.toString() ?? '',
    status: d['status']?.toString() ?? 'active',
    skills: d['skills'] is List ? List<String>.from((d['skills'] as List).map((e) => e.toString())) : const [],
    sports: d['sports'] is List ? List<String>.from((d['sports'] as List).map((e) => e.toString()).take(10)) : (d['sport']?.toString().trim().isNotEmpty == true ? [d['sport'].toString()] : const []),
    achievements: d['achievements'] is List ? List<String>.from((d['achievements'] as List).map((e) => e.toString()).take(20)) : const [],
    goals: d['goals'] is List ? List<String>.from((d['goals'] as List).map((e) => e.toString()).take(10)) : const [],
    updatedAt: d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null,
  );
}
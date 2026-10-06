import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/talent.dart';

class TalentRepository {
  final FirebaseFirestore db;
  TalentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenTalent>> watchPublic({String query = '', String skill = '', String sport = ''}) {
    final q = query.trim().toLowerCase();
    final s = skill.trim().toLowerCase();
    final sp = sport.trim().toLowerCase();
    return db.collection('talents').where('status', isEqualTo: 'active').limit(100).snapshots().map((snap) {
      final list = snap.docs.map((d) => AurenTalent.fromMap(d.id, d.data()))
          .where((t) => q.isEmpty || ('${t.displayName} ${t.bio} ${t.category} ${t.sport} ${t.discipline} ${t.level} ${t.city} ${t.country} ${t.skills.join(' ')} ${t.sports.join(' ')} ${t.achievements.join(' ')}').toLowerCase().contains(q))
          .where((t) => s.isEmpty || t.skills.any((x) => x.trim().toLowerCase() == s))
          .where((t) => sp.isEmpty || t.sport.toLowerCase() == sp || t.sports.any((x) => x.toLowerCase() == sp)).toList();
      list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      return list;
    });
  }

  Future<String> save({
    required String ownerId, required String displayName, required String bio, required String category,
    String sport = '', String discipline = '', String level = '', required String city, required String country,
    List<String> skills = const [], List<String> achievements = const [], List<String> goals = const [], List<String> sports = const [],
  }) async {
    final ref = db.collection('talents').doc();
    String clean(String value) => value.trim();
    List<String> list(Iterable<String> values, int max) => values.map(clean).where((x) => x.isNotEmpty).take(max).toList();
    await ref.set({
      'ownerId': ownerId, 'displayName': clean(displayName), 'bio': clean(bio), 'category': clean(category),
      'sport': clean(sport), 'sports': list(sports.isEmpty && sport.trim().isNotEmpty ? [sport] : sports, 10).toList(), 'discipline': clean(discipline), 'level': clean(level), 'city': clean(city), 'country': clean(country),
      'skills': list(skills, 30).map((e) => e.toLowerCase()).toList(), 'achievements': list(achievements, 20), 'goals': list(goals, 10),
      'status': 'active', 'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
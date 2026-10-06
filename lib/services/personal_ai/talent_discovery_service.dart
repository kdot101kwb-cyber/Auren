import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../social/post_repository.dart';
import '../users/user_repository.dart';

class AurenTalentMatch {
  final AurenUserProfile profile;
  final int score;
  final List<String> signals;
  const AurenTalentMatch({required this.profile, required this.score, required this.signals});
}

class AurenTalentDiscoveryService {
  final PostRepository _posts;
  AurenTalentDiscoveryService({PostRepository? posts, UserRepository? users}) : _posts = posts ?? PostRepository();

  Stream<List<AurenTalentMatch>> watch({required String query, String type = 'All'}) {
    return _posts.watchFeed().asyncMap((posts) async {
      final q = query.trim().toLowerCase();
      final byUser = <String, List<AurenPost>>{};
      for (final post in posts) {
        if (type != 'All' && post.contentType != type.toLowerCase()) continue;
        final haystack = '${post.text} ${post.contentType}'.toLowerCase();
        if (q.isNotEmpty && !haystack.contains(q)) continue;
        byUser.putIfAbsent(post.authorId, () => []).add(post);
      }
      final results = <AurenTalentMatch>[];
      for (final entry in byUser.entries) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(entry.key).get();
        if (!snap.exists || snap.data() == null) continue;
        final profile = AurenUserProfile.fromMap(entry.key, snap.data()!);
        final signals = <String>[];
        if (entry.value.length >= 3) signals.add('نشاط متكرر');
        if (entry.value.any((p) => p.contentType == 'project')) signals.add('مشاريع');
        if (entry.value.any((p) => p.contentType == 'opportunity')) signals.add('فرص');
        if (entry.value.any((p) => p.contentType == 'idea')) signals.add('أفكار');
        var score = entry.value.length * 10 + signals.length * 5;
        if (q.isNotEmpty && profile.displayName.toLowerCase().contains(q)) { score += 30; signals.add('الاسم يطابق البحث'); }
        results.add(AurenTalentMatch(profile: profile, score: score, signals: signals));
      }
      results.sort((a,b) => b.score.compareTo(a.score));
      return results.take(50).toList();
    });
  }
}

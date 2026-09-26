import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/search_result.dart';
import '../../core/models/user_profile.dart';
import '../social/safety_repository.dart';

class AurenGlobalSearchRepository {
  final FirebaseFirestore _db;
  AurenGlobalSearchRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<AurenSearchResult>> search(String text, {String? uid}) async {
    final blockedIds = uid == null ? const <String>{} : await AurenSafetyRepository(db: _db).getBlockedIds(uid);
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return [];
    final results = await Future.wait([
      _safe(() => _searchPeople(q, blockedIds)),
      _safe(() => _searchPosts(q, blockedIds)),
      _safe(() => _searchCollection(q, 'businesses', AurenSearchType.businesses, const ['name', 'title'], const ['category', 'description', 'location'], blockedIds)),
      _safe(() => _searchProducts(q, blockedIds)),
      _safe(() => _searchEntertainment(q, blockedIds)),
      _safe(() => _searchCollection(q, 'places', AurenSearchType.places, const ['name', 'title'], const ['city', 'country', 'description'], blockedIds)),
      _safe(() => _searchCollection(q, 'opportunities', AurenSearchType.opportunities, const ['title', 'name'], const ['company', 'category', 'location'], blockedIds)),
    ]);
    return results.expand<AurenSearchResult>((x) => x).toList();
  }

  Future<List<AurenSearchResult>> _safe(Future<List<AurenSearchResult>> Function() task) async {
    try {
      return await task();
    } catch (_) {
      return const <AurenSearchResult>[];
    }
  }

  Future<List<AurenSearchResult>> _searchPeople(String q, Set<String> blockedIds) async {
    final snap = await _db.collection('users').orderBy('displayNameLower').startAt([q]).endAt(['$q\uf8ff']).limit(20).get();
    return snap.docs.where((d) => !blockedIds.contains(d.id)).take(8).map((d) {
      final p = AurenUserProfile.fromMap(d.id, d.data());
      return AurenSearchResult(id: d.id, type: AurenSearchType.people, title: p.displayName, subtitle: 'People', imageUrl: p.photoUrl);
    }).toList();
  }

  Future<List<AurenSearchResult>> _searchPosts(String q, Set<String> blockedIds) async {
    final snap = await _db.collection('posts').orderBy('searchText').startAt([q]).endAt(['$q\uf8ff']).limit(20).get();
    return snap.docs.where((d) => !blockedIds.contains(d.data()['authorId']?.toString() ?? d.data()['uid']?.toString() ?? '')).take(8).map((d) {
      final data = d.data();
      return AurenSearchResult(id: d.id, type: AurenSearchType.posts, title: (data['text'] as String? ?? '').trim(), subtitle: 'Pulse');
    }).where((r) => r.title.isNotEmpty).toList();
  }

  Future<List<AurenSearchResult>> _searchProducts(String q, Set<String> blockedIds) async {
    final snap = await _db.collection('products').where('status', isEqualTo: 'active').orderBy('searchText').startAt([q]).endAt(['$q\uf8ff']).limit(20).get();
    return snap.docs.where((d) => !blockedIds.contains(d.data()['ownerId']?.toString() ?? '')).take(8).map((d) {
      final data = d.data();
      return AurenSearchResult(id: d.id, type: AurenSearchType.products, title: (data['name']?.toString() ?? d.id), subtitle: 'Product • ${(data['category'] ?? '').toString()}', imageUrl: data['imageUrl']?.toString());
    }).toList();
  }

  Future<List<AurenSearchResult>> _searchEntertainment(String q, Set<String> blockedIds) async {
    final snap = await _db.collection('entertainment_items').where('visibility', isEqualTo: 'public').orderBy('searchText').startAt([q]).endAt(['$q\uf8ff']).limit(20).get();
    return snap.docs.where((d) { final data=d.data(); final owner=data['creatorId']?.toString() ?? data['ownerId']?.toString() ?? ''; return owner.isEmpty || !blockedIds.contains(owner); }).take(8).map((d) {
      final data=d.data();
      return AurenSearchResult(id:d.id,type:AurenSearchType.entertainment,title:(data['title']?.toString() ?? d.id),subtitle:'Entertainment • ${(data['type'] ?? '').toString()}',imageUrl:data['imageUrl']?.toString());
    }).toList();
  }
  Future<List<AurenSearchResult>> _searchCollection(String q, String collection, AurenSearchType type, List<String> titleFields, List<String> subtitleFields, Set<String> blockedIds) async {
    final snap = await _db.collection(collection).where('visibility', isEqualTo: 'public').orderBy('searchText').startAt([q]).endAt(['$q\uf8ff']).limit(20).get();
    return snap.docs.where((d) {
      final data = d.data();
      final ownerId = data['ownerId']?.toString() ?? data['creatorId']?.toString() ?? data['authorId']?.toString() ?? data['uid']?.toString() ?? '';
      return ownerId.isEmpty || !blockedIds.contains(ownerId);
    }).take(8).map((d) {
      final data = d.data();
      String value(List<String> fields, String fallback) {
        for (final field in fields) {
          final v = data[field];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return fallback;
      }
      return AurenSearchResult(id: d.id, type: type, title: value(titleFields, d.id), subtitle: value(subtitleFields, type.name), imageUrl: data['imageUrl'] as String?);
    }).toList();
  }
}

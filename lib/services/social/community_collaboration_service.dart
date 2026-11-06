import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data access for collaboration features that are distinct from broad public
/// communities. All writes use the signed-in Firebase user and Firestore rules.
class AurenCollaborationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  AurenCollaborationService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;

  String? get currentUid => _auth.currentUser?.uid;

  String get uid =>
      currentUid ?? (throw StateError('Sign in required'));

  CollectionReference<Map<String, dynamic>> get _clubs =>
      _db.collection('community_clubs');
  CollectionReference<Map<String, dynamic>> get _spaces =>
      _db.collection('collaboration_spaces');
  CollectionReference<Map<String, dynamic>> get _causes =>
      _db.collection('volunteer_causes');

  Stream<List<AurenClub>> watchClubs({String query = ''}) {
    final normalized = query.trim().toLowerCase();
    return _clubs
        .where('visibility', isEqualTo: 'public')
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final clubs = snapshot.docs.map(AurenClub.fromDoc).where((club) {
        return normalized.isEmpty ||
            '${club.name} ${club.description} ${club.category}'
                .toLowerCase()
                .contains(normalized);
      }).toList();
      clubs.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      return clubs;
    });
  }

  Future<String> createClub({
    required String name,
    required String description,
    required String category,
  }) async {
    final cleanName = name.trim();
    final cleanDescription = description.trim();
    final cleanCategory = category.trim();
    if (cleanName.isEmpty || cleanName.length > 80) {
      throw ArgumentError('Club name must be 1–80 characters.');
    }
    if (cleanDescription.length > 500 || cleanCategory.isEmpty ||
        cleanCategory.length > 80) {
      throw ArgumentError('Club description or category is invalid.');
    }
    final ref = _clubs.doc();
    await ref.set({
      'ownerId': uid,
      'name': cleanName,
      'description': cleanDescription,
      'category': cleanCategory,
      'visibility': 'public',
      'memberIds': [uid],
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> joinClub(String clubId) async {
    final memberUid = uid;
    final ref = _clubs.doc(clubId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Club not found.');
      final data = snapshot.data()!;
      if (data['visibility'] != 'public') {
        throw StateError('This club is not publicly joinable.');
      }
      final members = List<String>.from(data['memberIds'] ?? const []);
      if (members.contains(memberUid)) return;
      if (members.length >= 10000) throw StateError('Club is full.');
      members.add(memberUid);
      transaction.update(ref, {
        'memberIds': members,
        'memberCount': members.length,
      });
    });
  }

  Future<void> leaveClub(String clubId) async {
    final memberUid = uid;
    final ref = _clubs.doc(clubId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      if (data['ownerId'] == memberUid) {
        throw StateError('The club owner cannot leave their own club.');
      }
      final members = List<String>.from(data['memberIds'] ?? const []);
      if (!members.remove(memberUid)) return;
      transaction.update(ref, {
        'memberIds': members,
        'memberCount': members.length,
      });
    });
  }

  Stream<List<AurenCollaborationSpace>> watchMySpaces() {
    final memberUid = uid;
    return _spaces
        .where('memberIds', arrayContains: memberUid)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(AurenCollaborationSpace.fromDoc).toList());
  }

  Future<String> createSpace({
    required String title,
    required String description,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120) {
      throw ArgumentError('Space title must be 1–120 characters.');
    }
    if (cleanDescription.length > 2000) {
      throw ArgumentError('Space description must be at most 2000 characters.');
    }
    final ref = _spaces.doc();
    await ref.set({
      'ownerId': uid,
      'title': cleanTitle,
      'description': cleanDescription,
      'memberIds': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> inviteToSpace({
    required String spaceId,
    required String memberUid,
  }) async {
    final actorUid = uid;
    final cleanMemberUid = memberUid.trim();
    if (cleanMemberUid.isEmpty || cleanMemberUid.length > 128 ||
        cleanMemberUid == actorUid) {
      throw ArgumentError('Choose another valid member UID (1–128 characters).');
    }
    final ref = _spaces.doc(spaceId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Collaboration space not found.');
      final data = snapshot.data()!;
      if (data['ownerId'] != actorUid) {
        throw StateError('Only the space owner can invite members.');
      }
      final members = List<String>.from(data['memberIds'] ?? const []);
      if (members.contains(cleanMemberUid)) return;
      if (members.length >= 100) throw StateError('Space is full.');
      members.add(cleanMemberUid);
      transaction.update(ref, {'memberIds': members});
    });
  }

  Stream<List<AurenVolunteerCause>> watchOpenCauses({String category = ''}) {
    final normalized = category.trim().toLowerCase();
    return _causes
        .where('status', isEqualTo: 'open')
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(AurenVolunteerCause.fromDoc)
            .where((cause) =>
                normalized.isEmpty ||
                cause.category.toLowerCase().contains(normalized))
            .toList());
  }

  Future<String> createCause({
    required String title,
    required String description,
    required String category,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCategory = category.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120) {
      throw ArgumentError('Cause title must be 1–120 characters.');
    }
    if (cleanDescription.isEmpty || cleanDescription.length > 2000 ||
        cleanCategory.isEmpty || cleanCategory.length > 80) {
      throw ArgumentError('Cause description or category is invalid.');
    }
    final ref = _causes.doc();
    await ref.set({
      'ownerId': uid,
      'title': cleanTitle,
      'description': cleanDescription,
      'category': cleanCategory,
      'status': 'open',
      'volunteerIds': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> volunteerForCause(String causeId) async {
    final volunteerUid = uid;
    final ref = _causes.doc(causeId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Cause not found.');
      final data = snapshot.data()!;
      if (data['status'] != 'open') {
        throw StateError('This cause is not accepting volunteers.');
      }
      final volunteers =
          List<String>.from(data['volunteerIds'] ?? const []);
      if (volunteers.contains(volunteerUid)) return;
      if (volunteers.length >= 10000) {
        throw StateError('Volunteer capacity reached.');
      }
      volunteers.add(volunteerUid);
      transaction.update(ref, {'volunteerIds': volunteers});
    });
  }

  /// Uses the existing reports collection and its established validation rules.
  Future<String> reportCommunityContent({
    required String reportedUid,
    required String reason,
    String? contentId,
    String? contentType,
  }) async {
    final reporterUid = uid;
    final cleanReportedUid = reportedUid.trim();
    final cleanReason = reason.trim();
    if (cleanReportedUid.isEmpty ||
        cleanReportedUid.length > 128 ||
        cleanReportedUid == reporterUid) {
      throw ArgumentError('Invalid report target.');
    }
    if (cleanReason.isEmpty || cleanReason.length > 500) {
      throw ArgumentError('Report reason must be 1–500 characters.');
    }
    final ref = _db.collection('reports').doc();
    await ref.set({
      'reporterUid': reporterUid,
      'reportedUid': cleanReportedUid,
      'reason': cleanReason,
      'contentId': contentId,
      'contentType': contentType,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}

class AurenClub {
  final String id, ownerId, name, description, category, visibility;
  final List<String> memberIds;
  final int memberCount;

  const AurenClub({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.visibility,
    required this.memberIds,
    required this.memberCount,
  });

  factory AurenClub.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AurenClub(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      visibility: data['visibility'] as String? ?? 'public',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AurenCollaborationSpace {
  final String id, ownerId, title, description;
  final List<String> memberIds;

  const AurenCollaborationSpace({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.memberIds,
  });

  factory AurenCollaborationSpace.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AurenCollaborationSpace(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
    );
  }
}

class AurenVolunteerCause {
  final String id, ownerId, title, description, category, status;
  final List<String> volunteerIds;

  const AurenVolunteerCause({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.volunteerIds,
  });

  factory AurenVolunteerCause.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AurenVolunteerCause(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      volunteerIds: List<String>.from(data['volunteerIds'] ?? const []),
    );
  }
}

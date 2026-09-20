import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/conversation.dart';

class ConversationRepository {
  final FirebaseFirestore _firestore;

  ConversationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  DocumentReference<Map<String, dynamic>> _aiRef(String uid) =>
      _conversations.doc('ai_$uid');

  Future<AurenConversation> createAiConversation(String uid) async {
    final ref = _aiRef(uid);
    final existing = await ref.get();
    if (existing.exists && existing.data() != null) {
      return AurenConversation.fromMap(ref.id, existing.data()!);
    }

    final conversation = AurenConversation(
      id: ref.id,
      memberIds: [uid],
      title: 'AUREN AI',
      isAi: true,
      updatedAt: DateTime.now(),
    );
    await ref.set(conversation.toMap());
    return conversation;
  }

  Future<AurenConversation?> findAiConversation(String uid) async {
    final doc = await _aiRef(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AurenConversation.fromMap(doc.id, doc.data()!);
  }

  Future<AurenConversation> getOrCreateAiConversation(String uid) async {
    return await findAiConversation(uid) ?? createAiConversation(uid);
  }

  Future<AurenConversation> getOrCreateDirectConversation({
    required String uid,
    required String otherUid,
    required String otherTitle,
  }) async {
    if (uid.isEmpty || otherUid.isEmpty || uid == otherUid) {
      throw ArgumentError('Invalid direct conversation members.');
    }
    final members = [uid, otherUid]..sort();
    final ref = _conversations.doc('dm_' + members.join('_'));
    final existing = await ref.get();
    if (existing.exists && existing.data() != null) {
      return AurenConversation.fromMap(ref.id, existing.data()!);
    }
    final conversation = AurenConversation(
      id: ref.id,
      memberIds: members,
      title: otherTitle.trim().isEmpty ? 'Direct message' : otherTitle.trim(),
      isAi: false,
      updatedAt: DateTime.now(),
      type: 'direct',
    );
    await ref.set(conversation.toMap());
    return conversation;
  }

  Future<AurenConversation> createGroup({
    required String uid,
    required String title,
    required List<String> memberIds,
  }) async {
    final members = {...memberIds, uid}.toList();
    if (title.trim().isEmpty || members.length < 3 || members.length > 50) {
      throw ArgumentError('A group needs a title and 3-50 members.');
    }
    final ref = _conversations.doc();
    final conversation = AurenConversation(
      id: ref.id,
      memberIds: members,
      title: title.trim(),
      isAi: false,
      updatedAt: DateTime.now(),
      type: 'group',
      ownerId: uid,
    );
    await ref.set(conversation.toMap());
    return conversation;
  }

  Future<void> updateGroupMembers({required String conversationId, required String ownerUid, required List<String> memberIds}) async {
    final clean = memberIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (ownerUid.isEmpty || !clean.contains(ownerUid) || clean.length < 2 || clean.length > 50) {
      throw ArgumentError('Groups must contain the owner and 3-50 members.');
    }
    final ref = _conversations.doc(conversationId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null || data['type'] != 'group' || data['ownerId'] != ownerUid) {
        throw StateError('Only the group owner can manage members.');
      }
      tx.update(ref, {'memberIds': clean});
    });
  }

  Future<void> addGroupMember({required String conversationId, required String uid, required String memberUid}) async {
    if (conversationId.isEmpty || uid.isEmpty || memberUid.isEmpty) throw ArgumentError('Invalid member.');
    final ref = _conversations.doc(conversationId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null || data['type'] != 'group' || data['ownerId'] != uid) {
        throw StateError('Only the group owner can add members.');
      }
      final members = List<String>.from(data['memberIds'] as List? ?? const []);
      if (members.contains(memberUid)) return;
      if (members.length >= 50) throw StateError('Group member limit reached.');
      members.add(memberUid);
      tx.update(ref, {'memberIds': members});
    });
  }

  Future<void> transferGroupOwnership({
    required String conversationId,
    required String ownerUid,
    required String newOwnerUid,
  }) async {
    if (conversationId.isEmpty || ownerUid.isEmpty || newOwnerUid.isEmpty || ownerUid == newOwnerUid) {
      throw ArgumentError('Invalid ownership transfer.');
    }
    final ref = _conversations.doc(conversationId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null || data['type'] != 'group' || data['ownerId'] != ownerUid) {
        throw StateError('Only the group owner can transfer ownership.');
      }
      final members = List<String>.from(data['memberIds'] as List? ?? const []);
      if (!members.contains(newOwnerUid)) {
        throw StateError('The new owner must already be a group member.');
      }
      tx.update(ref, {'ownerId': newOwnerUid});
    });
  }

  Future<void> removeGroupMember({required String conversationId, required String uid, required String memberUid}) async {
    if (conversationId.isEmpty || uid.isEmpty || memberUid.isEmpty) throw ArgumentError('Invalid member.');
    final ref = _conversations.doc(conversationId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null || data['type'] != 'group' || data['ownerId'] != uid) {
        throw StateError('Only the group owner can remove members.');
      }
      final members = List<String>.from(data['memberIds'] as List? ?? const []);
      if (memberUid == uid) throw StateError('The owner cannot be removed.');
      if (!members.contains(memberUid)) return;
      if (members.length <= 2) throw StateError('A group must keep at least 2 members.');
      members.remove(memberUid);
      tx.update(ref, {'memberIds': members});
    });
  }

  Future<void> leaveGroup({required String conversationId, required String uid}) async {
    final ref = _conversations.doc(conversationId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null || data['type'] != 'group' || !(data['memberIds'] as List).contains(uid)) {
        throw StateError('Group membership not found.');
      }
      if (data['ownerId'] == uid) throw StateError('Transfer ownership before leaving the group.');
      final members = List<String>.from(data['memberIds'] as List);
      members.remove(uid);
      tx.update(ref, {'memberIds': members});
    });
  }

  Future<AurenConversation?> findById(String conversationId) async {
    if (conversationId.trim().isEmpty) return null;
    final doc = await _conversations.doc(conversationId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AurenConversation.fromMap(doc.id, doc.data()!);
  }

  Future<void> markRead(String conversationId, String uid) async {
    if (conversationId.isEmpty || uid.isEmpty) return;
    await _conversations.doc(conversationId).collection('reads').doc(uid).set({
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DateTime?> watchReadAt(String conversationId, String uid) {
    return _conversations.doc(conversationId).collection('reads').doc(uid)
        .snapshots()
        .map((doc) {
          final value = doc.data()?['readAt'];
          return value is Timestamp ? value.toDate() : null;
        });
  }

  Stream<int> watchUnreadCount(String conversationId, String uid) {
    return watchReadAt(conversationId, uid).asyncExpand((readAt) {
      var query = _conversations.doc(conversationId).collection('messages')
          .where('isAi', isEqualTo: false);
      if (readAt != null) {
        query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(readAt));
      }
      return query.snapshots().map((s) =>
          s.docs.where((d) => d.data()['senderId'] != uid).length);
    });
  }

  Stream<List<AurenConversation>> watchForUser(String uid) => _conversations
      .where('memberIds', arrayContains: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => AurenConversation.fromMap(d.id, d.data()))
          .toList());

  Future<void> touch(String conversationId) {
    return _conversations.doc(conversationId).update({
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
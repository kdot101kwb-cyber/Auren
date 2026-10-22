import 'package:cloud_firestore/cloud_firestore.dart';

/// A savings target for planning only. Contributions do not move money and do
/// not debit or credit the family wallet balance.
class AurenFamilySavingsGoal {
  const AurenFamilySavingsGoal({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.targetMinor,
    required this.savedMinor,
    required this.currency,
  });

  final String id;
  final String ownerUid;
  final String title;
  final int targetMinor;
  final int savedMinor;
  final String currency;

  int get remainingMinor => targetMinor - savedMinor;

  double get progress {
    if (targetMinor <= 0) return 0;
    return (savedMinor / targetMinor).clamp(0.0, 1.0).toDouble();
  }

  bool get isComplete => savedMinor >= targetMinor;

  factory AurenFamilySavingsGoal.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final target = data['targetMinor'];
    final saved = data['savedMinor'];
    final targetMinor = target is int && target > 0 ? target : 1;
    final savedMinor = saved is int ? saved.clamp(0, targetMinor).toInt() : 0;
    return AurenFamilySavingsGoal(
      id: id,
      ownerUid: data['ownerUid']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      targetMinor: targetMinor,
      savedMinor: savedMinor,
      currency: (data['currency']?.toString() ?? 'USD').toUpperCase(),
    );
  }
}

class AurenFamilySavingsGoalRepository {
  AurenFamilySavingsGoalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _wallet(String uid) =>
      _db.collection('users').doc(uid).collection('familyWallet').doc('current');

  CollectionReference<Map<String, dynamic>> _goals(String uid) =>
      _wallet(uid).collection('goals');

  Stream<List<AurenFamilySavingsGoal>> watch(String uid) {
    if (uid.trim().isEmpty) return const Stream.empty();
    return _goals(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AurenFamilySavingsGoal.fromMap(doc.id, doc.data()))
            .toList(growable: false));
  }

  Future<String> create({
    required String uid,
    required String title,
    required int targetMinor,
    required String currency,
  }) async {
    final owner = uid.trim();
    final cleanTitle = title.trim();
    final code = currency.trim().toUpperCase();
    if (owner.isEmpty ||
        cleanTitle.isEmpty ||
        cleanTitle.length > 120 ||
        targetMinor <= 0 ||
        targetMinor > 1000000000000 ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      throw ArgumentError('بيانات هدف الادخار غير صالحة.');
    }

    final walletRef = _wallet(owner);
    final goalRef = _goals(owner).doc();
    await _db.runTransaction((transaction) async {
      final wallet = await transaction.get(walletRef);
      if (!wallet.exists || wallet.data()?['ownerUid'] != owner) {
        throw StateError('أنشئ محفظة الأسرة أولاً.');
      }
      transaction.set(goalRef, {
        'ownerUid': owner,
        'title': cleanTitle,
        'targetMinor': targetMinor,
        'savedMinor': 0,
        'currency': code,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return goalRef.id;
  }

  /// Adds a planned allocation to a goal. It never changes wallet balances.
  Future<void> addPlannedSavings({
    required String uid,
    required String goalId,
    required int amountMinor,
  }) async {
    final owner = uid.trim();
    if (owner.isEmpty ||
        goalId.trim().isEmpty ||
        amountMinor <= 0 ||
        amountMinor > 1000000000000) {
      throw ArgumentError('مبلغ الادخار غير صالح.');
    }

    final walletRef = _wallet(owner);
    final goalRef = _goals(owner).doc(goalId);
    await _db.runTransaction((transaction) async {
      final wallet = await transaction.get(walletRef);
      final goal = await transaction.get(goalRef);
      final data = goal.data();
      if (!wallet.exists ||
          wallet.data()?['ownerUid'] != owner ||
          !goal.exists ||
          data == null ||
          data['ownerUid'] != owner) {
        throw StateError('هدف الادخار غير موجود.');
      }
      final target = data['targetMinor'];
      final saved = data['savedMinor'];
      if (target is! int || saved is! int || target <= 0 || saved < 0) {
        throw StateError('بيانات هدف الادخار غير صالحة.');
      }
      if (amountMinor > target - saved) {
        throw StateError('مبلغ الادخار يتجاوز المتبقي لتحقيق الهدف.');
      }
      transaction.update(goalRef, {
        'savedMinor': saved + amountMinor,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> delete({required String uid, required String goalId}) async {
    final owner = uid.trim();
    if (owner.isEmpty || goalId.trim().isEmpty) {
      throw ArgumentError('بيانات هدف الادخار غير صالحة.');
    }
    final goalRef = _goals(owner).doc(goalId);
    await _db.runTransaction((transaction) async {
      final wallet = await transaction.get(_wallet(owner));
      final goal = await transaction.get(goalRef);
      if (!wallet.exists ||
          wallet.data()?['ownerUid'] != owner ||
          !goal.exists ||
          goal.data()?['ownerUid'] != owner) {
        throw StateError('هدف الادخار غير موجود.');
      }
      transaction.delete(goalRef);
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Owner-controlled family budget ledger. This is a planning ledger, not a
/// payment rail: entries never initiate transfers or contact a provider.
class AurenFamilyWallet {
  const AurenFamilyWallet({
    required this.uid,
    required this.balancesMinor,
    required this.currency,
  });

  final String uid;
  final String currency;
  final Map<String, int> balancesMinor;

  factory AurenFamilyWallet.fromMap(String uid, Map<String, dynamic> data) {
    final raw = data['balancesMinor'];
    final balances = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is int) {
          balances[entry.key.toString().toUpperCase()] = entry.value as int;
        }
      }
    }
    final currency = (data['currency']?.toString() ?? 'USD').toUpperCase();
    balances.putIfAbsent(currency, () => 0);
    return AurenFamilyWallet(
      uid: uid,
      currency: currency,
      balancesMinor: Map.unmodifiable(balances),
    );
  }
}

class AurenFamilyWalletRepository {
  AurenFamilyWalletRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _wallet(String uid) =>
      _db.collection('users').doc(uid).collection('familyWallet').doc('current');

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _wallet(uid).collection('entries');

  Stream<AurenFamilyWallet?> watch(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _wallet(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return snapshot.exists && data != null
          ? AurenFamilyWallet.fromMap(uid, data)
          : null;
    });
  }

  Stream<List<Map<String, dynamic>>> watchEntries(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _entries(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<void> initialize({
    required String uid,
    required String currency,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedCurrency = currency.trim().toUpperCase();
    if (normalizedUid.isEmpty ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
      throw ArgumentError('بيانات محفظة الأسرة غير صالحة.');
    }
    final ref = _wallet(normalizedUid);
    await _db.runTransaction((transaction) async {
      final current = await transaction.get(ref);
      if (current.exists) return;
      transaction.set(ref, {
        'ownerUid': normalizedUid,
        'currency': normalizedCurrency,
        'balancesMinor': {normalizedCurrency: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Records a manual income/expense and updates its currency balance atomically.
  /// Amounts are positive integer minor units; no real money is moved.
  Future<void> recordEntry({
    required String uid,
    required String title,
    required int amountMinor,
    required String currency,
    required String kind,
  }) async {
    final cleanTitle = title.trim();
    final code = currency.trim().toUpperCase();
    if (uid.trim().isEmpty ||
        cleanTitle.isEmpty ||
        cleanTitle.length > 160 ||
        amountMinor <= 0 ||
        amountMinor > 1000000000000 ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(code) ||
        !{'income', 'expense'}.contains(kind)) {
      throw ArgumentError('بيانات حركة محفظة الأسرة غير صالحة.');
    }

    final walletRef = _wallet(uid);
    final entryRef = _entries(uid).doc();
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(walletRef);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StateError('أنشئ محفظة الأسرة أولاً.');
      }
      final raw = data['balancesMinor'];
      final balances = <String, int>{};
      if (raw is Map) {
        for (final entry in raw.entries) {
          if (entry.value is int) {
            balances[entry.key.toString().toUpperCase()] = entry.value as int;
          }
        }
      }
      final current = balances[code] ?? 0;
      if (kind == 'expense' && amountMinor > current) {
        throw StateError('الرصيد المتاح غير كافٍ لهذه المصروفات.');
      }
      final next = kind == 'income' ? current + amountMinor : current - amountMinor;
      balances[code] = next;
      transaction.update(walletRef, {
        'balancesMinor': balances,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(entryRef, {
        'ownerUid': uid,
        'title': cleanTitle,
        'amountMinor': amountMinor,
        'currency': code,
        'kind': kind,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

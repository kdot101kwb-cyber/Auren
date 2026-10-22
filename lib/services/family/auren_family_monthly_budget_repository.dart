import 'package:cloud_firestore/cloud_firestore.dart';

/// A monthly spending limit for planning. It never blocks or executes payments.
class AurenFamilyMonthlyBudget {
  const AurenFamilyMonthlyBudget({
    required this.ownerUid,
    required this.periodKey,
    required this.currency,
    required this.limitMinor,
  });

  final String ownerUid;
  final String periodKey;
  final String currency;
  final int limitMinor;

  factory AurenFamilyMonthlyBudget.fromMap(Map<String, dynamic> data) {
    return AurenFamilyMonthlyBudget(
      ownerUid: data['ownerUid']?.toString() ?? '',
      periodKey: data['periodKey']?.toString() ?? '',
      currency: (data['currency']?.toString() ?? 'USD').toUpperCase(),
      limitMinor: data['limitMinor'] is int ? data['limitMinor'] as int : 0,
    );
  }
}

class AurenFamilyBudgetSummary {
  const AurenFamilyBudgetSummary({
    required this.budget,
    required this.spentMinor,
  });

  final AurenFamilyMonthlyBudget? budget;
  final int spentMinor;

  int get remainingMinor => budget == null ? 0 : budget!.limitMinor - spentMinor;
  double get progress {
    final limit = budget?.limitMinor ?? 0;
    if (limit <= 0) return 0;
    return (spentMinor / limit).clamp(0.0, 1.0);
  }

  bool get isOverBudget => budget != null && spentMinor > budget!.limitMinor;
}

class AurenFamilyMonthlyBudgetRepository {
  AurenFamilyMonthlyBudgetRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _wallet(String uid) =>
      _db.collection('users').doc(uid).collection('familyWallet').doc('current');

  DocumentReference<Map<String, dynamic>> _budget(
    String uid,
    String periodKey,
    String currency,
  ) => _wallet(uid).collection('budgets').doc('${periodKey}_${currency}');

  static bool isValidPeriod(String periodKey) =>
      RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(periodKey);

  Stream<AurenFamilyMonthlyBudget?> watchBudget({
    required String uid,
    required String periodKey,
    required String currency,
  }) {
    final owner = uid.trim();
    final code = currency.trim().toUpperCase();
    if (owner.isEmpty || !isValidPeriod(periodKey) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      return const Stream.empty();
    }
    return _budget(owner, periodKey, code).snapshots().map((snapshot) {
      final data = snapshot.data();
      return snapshot.exists && data != null
          ? AurenFamilyMonthlyBudget.fromMap(data)
          : null;
    });
  }

  Stream<int> watchMonthlyExpenses({
    required String uid,
    required String periodKey,
    required String currency,
  }) {
    final owner = uid.trim();
    final code = currency.trim().toUpperCase();
    if (owner.isEmpty || !isValidPeriod(periodKey) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      return const Stream.empty();
    }
    final year = int.parse(periodKey.substring(0, 4));
    final month = int.parse(periodKey.substring(5, 7));
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return _wallet(owner)
        .collection('entries')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs.fold<int>(0, (sum, doc) {
              final data = doc.data();
              if (data['kind'] != 'expense' ||
                  (data['currency']?.toString().toUpperCase() ?? '') != code) {
                return sum;
              }
              final amount = data['amountMinor'];
              return sum + (amount is int && amount > 0 ? amount : 0);
            }));
  }

  Future<void> setMonthlyBudget({
    required String uid,
    required String periodKey,
    required String currency,
    required int limitMinor,
  }) async {
    final owner = uid.trim();
    final code = currency.trim().toUpperCase();
    if (owner.isEmpty ||
        !isValidPeriod(periodKey) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(code) ||
        limitMinor <= 0 ||
        limitMinor > 1000000000000) {
      throw ArgumentError('بيانات ميزانية الأسرة الشهرية غير صالحة.');
    }

    final walletRef = _wallet(owner);
    final budgetRef = _budget(owner, periodKey, code);
    await _db.runTransaction((transaction) async {
      final wallet = await transaction.get(walletRef);
      if (!wallet.exists || wallet.data()?['ownerUid'] != owner) {
        throw StateError('أنشئ محفظة الأسرة أولاً.');
      }
      final current = await transaction.get(budgetRef);
      if (current.exists) {
        final data = current.data();
        if (data == null || data['ownerUid'] != owner) {
          throw StateError('ميزانية الأسرة غير صالحة.');
        }
        transaction.update(budgetRef, {
          'limitMinor': limitMinor,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(budgetRef, {
          'ownerUid': owner,
          'periodKey': periodKey,
          'currency': code,
          'limitMinor': limitMinor,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/family/auren_family_monthly_budget_repository.dart';
import 'package:auren/services/family/auren_family_wallet_repository.dart';

void main() {
  group('AurenFamilyBudgetSummary', () {
    test('calculates remaining amount and caps progress at one', () {
      final summary = AurenFamilyBudgetSummary(
        budget: AurenFamilyMonthlyBudget(
          ownerUid: 'user-1',
          periodKey: '2026-10',
          currency: 'USD',
          limitMinor: 10000,
        ),
        spentMinor: 12000,
      );

      expect(summary.remainingMinor, -2000);
      expect(summary.progress, 1);
      expect(summary.isOverBudget, isTrue);
    });

    test('reports no progress without a configured budget', () {
      const summary = AurenFamilyBudgetSummary(budget: null, spentMinor: 300);
      expect(summary.remainingMinor, 0);
      expect(summary.progress, 0);
      expect(summary.isOverBudget, isFalse);
    });
  });

  group('AurenFamilyMonthlyBudgetRepository', () {
    late FakeFirebaseFirestore firestore;
    late AurenFamilyWalletRepository wallet;
    late AurenFamilyMonthlyBudgetRepository budgets;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      wallet = AurenFamilyWalletRepository(firestore: firestore);
      budgets = AurenFamilyMonthlyBudgetRepository(firestore: firestore);
    });

    test('validates year-month values strictly', () {
      expect(AurenFamilyMonthlyBudgetRepository.isValidPeriod('2026-10'), isTrue);
      expect(AurenFamilyMonthlyBudgetRepository.isValidPeriod('2026-13'), isFalse);
      expect(AurenFamilyMonthlyBudgetRepository.isValidPeriod('26-10'), isFalse);
      expect(AurenFamilyMonthlyBudgetRepository.isValidPeriod('2026-00'), isFalse);
    });

    test('creates and updates one monthly budget without duplicate documents', () async {
      await wallet.initialize(uid: 'user-1', currency: 'USD');
      await budgets.setMonthlyBudget(
        uid: 'user-1',
        periodKey: '2026-10',
        currency: 'usd',
        limitMinor: 20000,
      );
      await budgets.setMonthlyBudget(
        uid: 'user-1',
        periodKey: '2026-10',
        currency: 'USD',
        limitMinor: 25000,
      );

      final docs = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('budgets')
          .get();

      expect(docs.docs, hasLength(1));
      expect(docs.docs.single.id, '2026-10_USD');
      expect(docs.docs.single.data()['limitMinor'], 25000);
      expect(docs.docs.single.data()['periodKey'], '2026-10');
      final observed = await budgets.watchBudget(
        uid: 'user-1',
        periodKey: '2026-10',
        currency: 'usd',
      ).first;
      expect(observed?.limitMinor, 25000);
      expect(observed?.currency, 'USD');
    });

    test('requires an existing wallet and rejects invalid limits', () async {
      await expectLater(
        budgets.setMonthlyBudget(
          uid: 'user-1',
          periodKey: '2026-10',
          currency: 'USD',
          limitMinor: 1000,
        ),
        throwsStateError,
      );
      await wallet.initialize(uid: 'user-1', currency: 'USD');
      await expectLater(
        budgets.setMonthlyBudget(
          uid: 'user-1',
          periodKey: '2026-13',
          currency: 'USD',
          limitMinor: 1000,
        ),
        throwsArgumentError,
      );
      await expectLater(
        budgets.setMonthlyBudget(
          uid: 'user-1',
          periodKey: '2026-10',
          currency: 'USD',
          limitMinor: 0,
        ),
        throwsArgumentError,
      );
    });

    test('counts only current-month expenses in the selected currency', () async {
      final entries = firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('entries');
      await entries.doc('current-expense').set({
        'kind': 'expense',
        'currency': 'USD',
        'amountMinor': 1500,
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 10)),
      });
      await entries.doc('current-income').set({
        'kind': 'income',
        'currency': 'USD',
        'amountMinor': 9000,
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 11)),
      });
      await entries.doc('other-currency').set({
        'kind': 'expense',
        'currency': 'EUR',
        'amountMinor': 3000,
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 12)),
      });
      await entries.doc('previous-month').set({
        'kind': 'expense',
        'currency': 'USD',
        'amountMinor': 500,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30)),
      });

      await expectLater(
        budgets.watchMonthlyExpenses(
          uid: 'user-1',
          periodKey: '2026-10',
          currency: 'usd',
        ),
        emits(1500),
      );
    });

    test('rejects a malformed currency without creating a budget', () async {
      await wallet.initialize(uid: 'user-1', currency: 'USD');
      await expectLater(
        budgets.setMonthlyBudget(
          uid: 'user-1',
          periodKey: '2026-10',
          currency: 'US dollars',
          limitMinor: 1000,
        ),
        throwsArgumentError,
      );
      final docs = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('budgets')
          .get();
      expect(docs.docs, isEmpty);
    });
  });
}

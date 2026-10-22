import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/family/auren_family_savings_goal_repository.dart';
import 'package:auren/services/family/auren_family_wallet_repository.dart';

void main() {
  group('AurenFamilySavingsGoal', () {
    test('calculates remaining amount and bounded progress', () {
      final goal = AurenFamilySavingsGoal.fromMap('goal-1', {
        'ownerUid': 'user-1',
        'title': 'Emergency fund',
        'targetMinor': 10000,
        'savedMinor': 2500,
        'currency': 'usd',
      });

      expect(goal.remainingMinor, 7500);
      expect(goal.progress, 0.25);
      expect(goal.isComplete, isFalse);
      expect(goal.currency, 'USD');
    });

    test('clamps malformed saved amounts to the target', () {
      final goal = AurenFamilySavingsGoal.fromMap('goal-2', {
        'targetMinor': 100,
        'savedMinor': 500,
      });

      expect(goal.savedMinor, 100);
      expect(goal.remainingMinor, 0);
      expect(goal.progress, 1);
      expect(goal.isComplete, isTrue);
    });
  });

  group('AurenFamilySavingsGoalRepository', () {
    late FakeFirebaseFirestore firestore;
    late AurenFamilyWalletRepository walletRepository;
    late AurenFamilySavingsGoalRepository goals;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      walletRepository = AurenFamilyWalletRepository(firestore: firestore);
      goals = AurenFamilySavingsGoalRepository(firestore: firestore);
    });

    Future<Map<String, dynamic>> readWallet() async {
      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .get();
      return snapshot.data()!;
    }

    test('creates a goal only after wallet exists', () async {
      await expectLater(
        goals.create(
          uid: 'user-1',
          title: 'School costs',
          targetMinor: 10000,
          currency: 'SDG',
        ),
        throwsStateError,
      );

      await walletRepository.initialize(uid: 'user-1', currency: 'USD');
      final id = await goals.create(
        uid: 'user-1',
        title: '  School costs  ',
        targetMinor: 10000,
        currency: 'sdg',
      );

      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('goals')
          .doc(id)
          .get();

      expect(snapshot.data()?['title'], 'School costs');
      expect(snapshot.data()?['targetMinor'], 10000);
      expect(snapshot.data()?['savedMinor'], 0);
      expect(snapshot.data()?['currency'], 'SDG');
    });

    test('rejects invalid goal details', () async {
      await walletRepository.initialize(uid: 'user-1', currency: 'USD');
      await expectLater(
        goals.create(
          uid: 'user-1',
          title: ' ',
          targetMinor: 10,
          currency: 'USD',
        ),
        throwsArgumentError,
      );
      await expectLater(
        goals.create(
          uid: 'user-1',
          title: 'Goal',
          targetMinor: 0,
          currency: 'USD',
        ),
        throwsArgumentError,
      );
    });

    test('planned savings progress does not change wallet balance', () async {
      await walletRepository.initialize(uid: 'user-1', currency: 'USD');
      await walletRepository.recordEntry(
        uid: 'user-1',
        title: 'Income',
        amountMinor: 10000,
        currency: 'USD',
        kind: 'income',
      );
      final id = await goals.create(
        uid: 'user-1',
        title: 'Emergency fund',
        targetMinor: 5000,
        currency: 'USD',
      );

      await goals.addPlannedSavings(
        uid: 'user-1',
        goalId: id,
        amountMinor: 1500,
      );

      final wallet = await readWallet();
      final goal = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('goals')
          .doc(id)
          .get();

      expect(wallet['balancesMinor'], {'USD': 10000});
      expect(goal.data()?['savedMinor'], 1500);
    });

    test('rejects planned savings above remaining target without changing it',
        () async {
      await walletRepository.initialize(uid: 'user-1', currency: 'USD');
      final id = await goals.create(
        uid: 'user-1',
        title: 'Laptop',
        targetMinor: 2000,
        currency: 'USD',
      );

      await goals.addPlannedSavings(
        uid: 'user-1',
        goalId: id,
        amountMinor: 1500,
      );
      await expectLater(
        goals.addPlannedSavings(
          uid: 'user-1',
          goalId: id,
          amountMinor: 501,
        ),
        throwsStateError,
      );

      final goal = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('goals')
          .doc(id)
          .get();
      expect(goal.data()?['savedMinor'], 1500);
    });

    test('rejects negative or zero planned savings', () async {
      await expectLater(
        goals.addPlannedSavings(
          uid: 'user-1',
          goalId: 'goal-1',
          amountMinor: 0,
        ),
        throwsArgumentError,
      );
    });

    test('deletes an owned goal but rejects a missing one', () async {
      await walletRepository.initialize(uid: 'user-1', currency: 'USD');
      final id = await goals.create(
        uid: 'user-1',
        title: 'Trip',
        targetMinor: 5000,
        currency: 'USD',
      );
      await goals.delete(uid: 'user-1', goalId: id);
      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('goals')
          .doc(id)
          .get();
      expect(snapshot.exists, isFalse);
      await expectLater(
        goals.delete(uid: 'user-1', goalId: id),
        throwsStateError,
      );
    });
  });
}

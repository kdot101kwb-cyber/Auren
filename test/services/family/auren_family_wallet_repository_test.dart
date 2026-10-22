import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/family/auren_family_wallet_repository.dart';

void main() {
  group('AurenFamilyWallet.fromMap', () {
    test('normalizes currency codes and exposes an immutable balance map', () {
      final wallet = AurenFamilyWallet.fromMap('user-1', {
        'currency': 'usd',
        'balancesMinor': {'usd': 1250, 'SDG': 0, 'bad': 'ignored'},
      });

      expect(wallet.uid, 'user-1');
      expect(wallet.currency, 'USD');
      expect(wallet.balancesMinor, {'USD': 1250, 'SDG': 0});
      expect(
        () => wallet.balancesMinor['EUR'] = 10,
        throwsUnsupportedError,
      );
    });

    test('provides a zero balance for the configured currency when missing', () {
      final wallet = AurenFamilyWallet.fromMap('user-2', {
        'currency': 'EUR',
        'balancesMinor': {'USD': 100},
      });

      expect(wallet.balancesMinor['EUR'], 0);
      expect(wallet.balancesMinor['USD'], 100);
    });
  });

  group('AurenFamilyWalletRepository', () {
    late FakeFirebaseFirestore firestore;
    late AurenFamilyWalletRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = AurenFamilyWalletRepository(firestore: firestore);
    });

    test('initializes a wallet once with a zero balance', () async {
      await repository.initialize(uid: 'user-1', currency: 'usd');
      await repository.initialize(uid: 'user-1', currency: 'EUR');

      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .get();

      expect(snapshot.data()?['ownerUid'], 'user-1');
      expect(snapshot.data()?['currency'], 'USD');
      expect(snapshot.data()?['balancesMinor'], {'USD': 0});
    });

    test('rejects an empty uid or invalid currency when initializing', () {
      expect(
        repository.initialize(uid: ' ', currency: 'USD'),
        throwsArgumentError,
      );
      expect(
        repository.initialize(uid: 'user-1', currency: 'US dollars'),
        throwsArgumentError,
      );
    });

    test('records income and expense atomically in balance and ledger', () async {
      await repository.initialize(uid: 'user-1', currency: 'USD');
      await repository.recordEntry(
        uid: 'user-1',
        title: 'Salary',
        amountMinor: 12500,
        currency: 'usd',
        kind: 'income',
      );
      await repository.recordEntry(
        uid: 'user-1',
        title: 'Groceries',
        amountMinor: 2500,
        currency: 'USD',
        kind: 'expense',
      );

      final wallet = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .get();
      final entries = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('entries')
          .get();

      expect(wallet.data()?['balancesMinor'], {'USD': 10000});
      expect(entries.docs, hasLength(2));
      expect(entries.docs.map((doc) => doc.data()['kind']).toSet(),
          {'income', 'expense'});
    });

    test('keeps balances isolated by currency', () async {
      await repository.initialize(uid: 'user-1', currency: 'USD');
      await repository.recordEntry(
        uid: 'user-1',
        title: 'USD income',
        amountMinor: 1000,
        currency: 'USD',
        kind: 'income',
      );
      await repository.recordEntry(
        uid: 'user-1',
        title: 'EUR income',
        amountMinor: 500,
        currency: 'eur',
        kind: 'income',
      );
      await repository.recordEntry(
        uid: 'user-1',
        title: 'EUR expense',
        amountMinor: 200,
        currency: 'EUR',
        kind: 'expense',
      );

      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .get();
      expect(snapshot.data()?['balancesMinor'], {'USD': 1000, 'EUR': 300});

      await expectLater(
        repository.recordEntry(
          uid: 'user-1',
          title: 'Overspend USD',
          amountMinor: 1001,
          currency: 'USD',
          kind: 'expense',
        ),
        throwsStateError,
      );
    });

    test('rejects an expense above the available balance without writing it',
        () async {
      await repository.initialize(uid: 'user-1', currency: 'USD');

      await expectLater(
        repository.recordEntry(
          uid: 'user-1',
          title: 'Too much',
          amountMinor: 1,
          currency: 'USD',
          kind: 'expense',
        ),
        throwsStateError,
      );

      final entries = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .collection('entries')
          .get();
      expect(entries.docs, isEmpty);
    });

    test('rejects income that would exceed the supported balance ceiling', () async {
      await repository.initialize(uid: 'user-1', currency: 'USD');
      await repository.recordEntry(
        uid: 'user-1',
        title: 'Maximum supported balance',
        amountMinor: 1000000000000,
        currency: 'USD',
        kind: 'income',
      );

      await expectLater(
        repository.recordEntry(
          uid: 'user-1',
          title: 'Overflow attempt',
          amountMinor: 1,
          currency: 'USD',
          kind: 'income',
        ),
        throwsStateError,
      );

      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('familyWallet')
          .doc('current')
          .get();
      expect(snapshot.data()?['balancesMinor'], {'USD': 1000000000000});
    });

    test('rejects invalid entry details', () {
      expect(
        repository.recordEntry(
          uid: 'user-1',
          title: '   ',
          amountMinor: 100,
          currency: 'USD',
          kind: 'income',
        ),
        throwsArgumentError,
      );
      expect(
        repository.recordEntry(
          uid: 'user-1',
          title: 'Other',
          amountMinor: 100,
          currency: 'USD',
          kind: 'transfer',
        ),
        throwsArgumentError,
      );
    });
  });
}

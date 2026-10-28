import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/wallet/nova_finance_models.dart';
import 'package:nova_ai/features/wallet/nova_finance_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('registry supports the four current providers and multiple currencies', () {
    expect(NovaFinanceRegistry.providers.map((p) => p.id).toList(), [
      'bravo', 'mycashi', 'trust_wallet', 'paypal',
    ]);
    expect(
      NovaFinanceRegistry.provider('trust_wallet')!.supportedCurrencies,
      containsAll(['USDT', 'BTC', 'ETH']),
    );
    expect(NovaFinanceRegistry.provider('future_provider'), isNull);
  });

  test('transaction schema preserves extensible metadata and references', () {
    final now = DateTime.utc(2026, 10, 27);
    final transaction = NovaFinanceTransaction(
      id: 'test-1',
      walletId: 'paypal',
      type: 'income',
      amount: 19.5,
      currency: 'USD',
      categoryId: 'affiliate',
      reference: 'receipt-77',
      counterparty: 'Example customer',
      tags: const ['client-work', 'online'],
      occurredAt: now,
      createdAt: now,
      metadata: const {'source': 'manual'},
    );
    final restored = NovaFinanceTransaction.fromJson(transaction.toJson());
    expect(restored.reference, 'receipt-77');
    expect(restored.counterparty, 'Example customer');
    expect(restored.tags, ['client-work', 'online']);
    expect(restored.metadata['source'], 'manual');
    expect(restored.providerVerified, isFalse);
  });

  test('repository saves, reloads, and exports without provider verification claims', () async {
    final repository = SharedPreferencesNovaFinanceRepository();
    final now = DateTime.utc(2026, 10, 27);
    final transaction = NovaFinanceTransaction(
      id: 'local-1',
      walletId: 'bravo',
      type: 'expense',
      amount: 300,
      currency: 'SDG',
      occurredAt: now,
      createdAt: now,
    );
    expect(await repository.saveTransactions([transaction]), isTrue);
    final loaded = await repository.loadTransactions();
    expect(loaded, hasLength(1));
    expect(loaded.single.amount, 300);
    final exported = await repository.exportJson();
    expect(exported, contains('"verifiedProviderData": false'));
    expect(exported, contains('"schemaVersion": 2'));
  });

  test('repository migrates old local ledger entries to the new storage key', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesNovaFinanceRepository.legacyStorageKey: [
        '{"id":"legacy-1","walletId":"bravo","type":"income","amount":42,"currency":"SDG","note":"old entry","createdAt":"2026-10-26T12:00:00.000Z"}',
      ],
    });
    final repository = SharedPreferencesNovaFinanceRepository();
    final entries = await repository.loadTransactions();
    expect(entries, hasLength(1));
    expect(entries.single.id, 'legacy-1');
    expect(entries.single.note, 'old entry');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(SharedPreferencesNovaFinanceRepository.storageKey), isNotEmpty);
  });
}

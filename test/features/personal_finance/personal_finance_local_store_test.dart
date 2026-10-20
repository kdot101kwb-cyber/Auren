import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/personal_finance/data/personal_finance_local_store.dart';
import 'package:auren/features/personal_finance/domain/personal_finance_models.dart';

void main() {
  test('snapshot JSON round-trips entries, notes, currency and budget', () {
    final original = PersonalFinanceSnapshot(
      currency: 'SDG',
      budgetLimit: 120000,
      entries: [
        FinanceEntry(
          id: 'entry-1',
          type: FinanceEntryType.expense,
          amount: 75.5,
          currency: 'SDG',
          category: 'مواصلات',
          occurredAt: DateTime.utc(2026, 10, 20, 14, 30),
          note: 'رحلة للعمل',
        ),
        FinanceEntry(
          id: 'entry-2',
          type: FinanceEntryType.income,
          amount: 500,
          currency: 'SDG',
          category: 'راتب',
          occurredAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );

    final restored = PersonalFinanceSnapshot.fromJson(original.toJson());

    expect(restored.currency, 'SDG');
    expect(restored.budgetLimit, 120000);
    expect(restored.entries, hasLength(2));
    expect(restored.entries.first.category, 'مواصلات');
    expect(restored.entries.first.amount, 75.5);
    expect(restored.entries.first.note, 'رحلة للعمل');
    expect(restored.entries.first.occurredAt, DateTime.utc(2026, 10, 20, 14, 30));
    expect(restored.entries.last.type, FinanceEntryType.income);
  });

  test('rejects unsupported or malformed saved snapshots', () {
    expect(
      () => PersonalFinanceSnapshot.fromJson({'version': 99, 'entries': []}),
      throwsFormatException,
    );
    expect(
      () => PersonalFinanceSnapshot.fromJson({
        'version': 1,
        'currency': 'SDG',
        'budgetLimit': 100,
        'entries': [
          {
            'id': 'bad',
            'type': 'expense',
            'amount': 0,
            'currency': 'SDG',
            'category': 'food',
            'occurredAt': '2026-10-20T00:00:00.000',
          }
        ],
      }),
      throwsArgumentError,
    );
  });
}

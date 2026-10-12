import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/trust/domain/trust_signal_assessor.dart';

void main() {
  const assessor = TrustSignalAssessor();
  final now = DateTime.utc(2026, 10, 12);

  test('deduplicates signals and explains eligible evidence', () {
    final signal = TrustSignal(
      id: 'tx-1',
      kind: TrustSignalKind.completedTransaction,
      occurredAt: now.subtract(const Duration(days: 2)),
      evidenceReference: 'receipt-hash',
    );
    final result = assessor.assess(signals: [signal, signal], now: now);
    expect(result.evidenceCount, 1);
    expect(result.score, 56);
    expect(result.explanations, contains('Completed transaction signal recorded'));
  });

  test('negative signals reduce score more than positive review signals add', () {
    final positive = assessor.assess(
      signals: [TrustSignal(
        id: 'review',
        kind: TrustSignalKind.helpfulReview,
        occurredAt: now,
        evidenceReference: 'review-id',
      )],
      now: now,
    );
    final negative = assessor.assess(
      signals: [TrustSignal(
        id: 'violation',
        kind: TrustSignalKind.policyViolation,
        occurredAt: now,
        evidenceReference: 'case-id',
      )],
      now: now,
    );
    expect(positive.score, greaterThan(50));
    expect(negative.score, lessThan(positive.score));
    expect(negative.label, 'Caution: negative signals');
  });

  test('missing, future, invalid-weight, and blank-ID signals are ignored', () {
    final result = assessor.assess(
      signals: [
        TrustSignal(id: '', kind: TrustSignalKind.policyViolation, occurredAt: now),
        TrustSignal(id: 'future', kind: TrustSignalKind.policyViolation, occurredAt: now.add(const Duration(days: 1))),
        TrustSignal(id: 'bad-weight', kind: TrustSignalKind.policyViolation, occurredAt: now, weight: double.nan),
      ],
      now: now,
    );
    expect(result.score, 50);
    expect(result.evidenceCount, 0);
    expect(result.label, 'Not enough evidence');
  });

  test('rejects whitespace-padded signal IDs', () { final result = assessor.assess(signals: [TrustSignal(id: ' tx-1 ', kind: TrustSignalKind.policyViolation, occurredAt: now), TrustSignal(id: 'tx-1', kind: TrustSignalKind.completedTransaction, occurredAt: now)], now: now); expect(result.evidenceCount, 1); expect(result.score, 56); });

  test('scores remain bounded', () {
    final result = assessor.assess(
      signals: List.generate(20, (i) => TrustSignal(
        id: 'violation-$i',
        kind: TrustSignalKind.policyViolation,
        occurredAt: now,
        weight: 2,
        evidenceReference: 'case-$i',
      )),
      now: now,
    );
    expect(result.score, 0);
  });
}

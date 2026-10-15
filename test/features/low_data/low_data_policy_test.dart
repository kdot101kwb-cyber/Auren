import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/low_data/domain/low_data_policy.dart';

void main() {
  const policy = LowDataPolicy();

  test('offline blocks network and all prefetch', () {
    final result = policy.decide(
      connection: DataConnection.offline,
      content: DataContentKind.video,
      lowDataMode: false,
      userRequested: true,
    );
    expect(result.allowNetwork, isFalse);
    expect(result.allowPrefetch, isFalse);
    expect(result.maxBytes, 0);
  });

  test('metered connection does not fetch media without user action', () {
    final result = policy.decide(
      connection: DataConnection.metered,
      content: DataContentKind.video,
      lowDataMode: false,
      userRequested: false,
    );
    expect(result.allowNetwork, isFalse);
    expect(result.allowAutoplay, isFalse);
    expect(result.quality, DataQuality.minimal);
  });

  test('explicit request allows bounded media at minimal quality', () {
    final result = policy.decide(
      connection: DataConnection.metered,
      content: DataContentKind.video,
      lowDataMode: true,
      userRequested: true,
    );
    expect(result.allowNetwork, isTrue);
    expect(result.allowAutoplay, isFalse);
    expect(result.allowPrefetch, isFalse);
    expect(result.maxBytes, 2 * 1024 * 1024);
  });

  test('unknown connection defaults to no automatic media transfer', () { final result = policy.decide(connection: DataConnection.unknown, content: DataContentKind.video, lowDataMode: false, userRequested: false); expect(result.allowNetwork, isFalse); expect(result.allowAutoplay, isFalse); expect(result.allowPrefetch, isFalse); expect(result.maxBytes, 0); });

  test('text remains available in low-data mode with a smaller budget', () {
    final result = policy.decide(
      connection: DataConnection.metered,
      content: DataContentKind.text,
      lowDataMode: true,
      userRequested: false,
    );
    expect(result.allowNetwork, isTrue);
    expect(result.maxBytes, 128 * 1024);
    expect(result.allowPrefetch, isFalse);
  });
}

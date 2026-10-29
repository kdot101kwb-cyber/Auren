import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/earnings/earning_platforms.dart';

void main() {
  group('earning platform catalogue', () {
    test('contains ten distinct platform entries', () {
      expect(earningPlatforms, hasLength(10));
      expect(earningPlatforms.map((item) => item.id).toSet(), hasLength(10));
    });

    test('filters by name without changing the source catalogue', () {
      final result = filterEarningPlatforms(query: 'Honeygain');
      expect(result.map((item) => item.id), contains('honeygain'));
      expect(result, hasLength(1));
      expect(earningPlatforms, hasLength(10));
    });

    test('crypto filter does not label unverified methods as direct crypto', () {
      final result = filterEarningPlatforms(cryptoOnly: true);
      expect(result.map((item) => item.id), containsAll(['microworkjobs', 'jumptask', 'honeygain']));
      expect(result.any((item) => item.id == 'paidwork'), isFalse);
    });

    test('empty query returns all platforms', () {
      expect(filterEarningPlatforms(), hasLength(10));
    });
  });
}

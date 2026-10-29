import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/earnings/sudan_priority_platforms.dart';

void main() {
  group('Sudan priority earning workflow', () {
    test('keeps the five requested platforms in the configured priority list', () {
      expect(
        sudanPriorityPlatforms.map((platform) => platform.id),
        ['pixels', 'grass', 'honeygain', 'publish0x', 'hive'],
      );
    });

    test('each entry has an official HTTPS destination and a verification warning', () {
      for (final platform in sudanPriorityPlatforms) {
        expect(platform.officialUrl, startsWith('https://'));
        expect(platform.verificationWarning, isNotEmpty);
        expect(platform.suggestedRoutine, isNotEmpty);
      }
    });

    test('filters the priority list by platform name', () {
      final results = filterSudanPriorityPlatforms('honeygain');
      expect(results, hasLength(1));
      expect(results.single.id, 'honeygain');
    });

    test('does not mutate the source list when searching', () {
      filterSudanPriorityPlatforms('hive');
      expect(sudanPriorityPlatforms, hasLength(5));
    });
  });
}

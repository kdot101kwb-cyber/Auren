import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/social/profile_mode_service.dart';

void main() {
  group('AurenProfileModeService.validateContactVisibility', () {
    test('allows links when contact sharing is enabled', () {
      expect(
        () => AurenProfileModeService.validateContactVisibility(
          links: const ['https://example.com'],
          showContact: true,
        ),
        returnsNormally,
      );
    });

    test('allows hidden contact when there are no links', () {
      expect(
        () => AurenProfileModeService.validateContactVisibility(
          links: const [],
          showContact: false,
        ),
        returnsNormally,
      );
    });

    test('rejects links when contact sharing is disabled', () {
      expect(
        () => AurenProfileModeService.validateContactVisibility(
          links: const ['https://example.com'],
          showContact: false,
        ),
        throwsArgumentError,
      );
    });

    test('ignores blank link entries after cleaning', () {
      expect(
        () => AurenProfileModeService.validateContactVisibility(
          links: const ['  '],
          showContact: false,
        ),
        returnsNormally,
      );
    });
  });
}

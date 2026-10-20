import 'package:flutter_test/flutter_test.dart';

import 'package:auren/services/knowledge/knowledge_information_service.dart';

void main() {
  group('KnowledgeInformationService input validation', () {
    test('requiredText trims and collapses whitespace', () {
      expect(
        KnowledgeInformationService.requiredText('  one\n  two ', 'title', 20),
        'one two',
      );
    });

    test('requiredText rejects empty and oversized values', () {
      expect(
        () => KnowledgeInformationService.requiredText('  ', 'title', 20),
        throwsArgumentError,
      );
      expect(
        () => KnowledgeInformationService.requiredText('abcd', 'title', 3),
        throwsArgumentError,
      );
    });

    test('validHttpUrl accepts HTTP and HTTPS URLs', () {
      expect(
        KnowledgeInformationService.validHttpUrl('https://example.com/path'),
        'https://example.com/path',
      );
      expect(
        KnowledgeInformationService.validHttpUrl('http://example.com'),
        'http://example.com',
      );
    });

    test('validHttpUrl rejects unsafe schemes, credentials, and missing hosts', () {
      for (final value in [
        'javascript:alert(1)',
        'ftp://example.com/file',
        'https://user:password@example.com/private',
        'https://',
      ]) {
        expect(
          () => KnowledgeInformationService.validHttpUrl(value),
          throwsArgumentError,
          reason: 'Should reject $value',
        );
      }
    });
  });
}

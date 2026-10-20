import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/knowledge/knowledge_information_service.dart';

void main() {
  group('KnowledgeInformationService input contracts', () {
    test('required text normalizes whitespace and rejects empty values', () {
      expect(KnowledgeInformationService.requiredText('  A   source  ', 'title', 20), 'A source');
      expect(() => KnowledgeInformationService.requiredText(' ', 'title', 20), throwsArgumentError);
      expect(() => KnowledgeInformationService.requiredText(List.filled(21, 'x').join(), 'title', 20), throwsArgumentError);
    });

    test('HTTP source URLs are required and credentials are rejected', () {
      expect(KnowledgeInformationService.validHttpUrl('https://example.org/path'), 'https://example.org/path');
      expect(KnowledgeInformationService.validHttpUrl('http://example.org'), 'http://example.org');
      expect(() => KnowledgeInformationService.validHttpUrl('javascript:alert(1)'), throwsArgumentError);
      expect(() => KnowledgeInformationService.validHttpUrl('ftp://example.org/file'), throwsArgumentError);
      expect(() => KnowledgeInformationService.validHttpUrl('https://user:pass@example.org'), throwsArgumentError);
      expect(() => KnowledgeInformationService.validHttpUrl('https://'), throwsArgumentError);
    });
  });
}

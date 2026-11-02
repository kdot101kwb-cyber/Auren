import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/opportunities/nova_tor_research.dart';

void main() {
  group('NovaTorResearch proxy policy', () {
    test('routes HTTPS through Orbot HTTP CONNECT proxy', () {
      expect(
        NovaTorResearch.proxyFor(Uri.parse('https://example.com/search')),
        'PROXY 127.0.0.1:8118',
      );
    });

    test('rejects plaintext HTTP', () {
      expect(
        () => NovaTorResearch.proxyFor(Uri.parse('http://example.com')),
        throwsArgumentError,
      );
    });

    test('rejects non-web schemes', () {
      expect(
        () => NovaTorResearch.proxyFor(Uri.parse('file:///etc/passwd')),
        throwsArgumentError,
      );
    });

    test('rejects empty search queries', () async {
      await expectLater(NovaTorResearch.searchHtml('  '), throwsArgumentError);
    });
  });
}

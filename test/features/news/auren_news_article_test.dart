import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/news/domain/auren_news_article.dart';

AurenNewsArticle _article({
  String sourceUrl = 'https://news.example.org/story/1',
  String? imageUrl,
  String title = 'AUREN news domain test',
  String languageCode = 'en',
  DateTime? publishedAt,
  AurenNewsVerificationState verificationState =
      AurenNewsVerificationState.unreviewed,
}) {
  final fetchedAt = DateTime.utc(2026, 10, 16, 12);
  return AurenNewsArticle(
    id: 'story-1',
    title: title,
    summary: 'A test summary.',
    sourceName: 'Example News',
    sourceUrl: sourceUrl,
    languageCode: languageCode,
    publishedAt: publishedAt ?? fetchedAt.subtract(const Duration(hours: 2)),
    fetchedAt: fetchedAt,
    category: AurenNewsCategory.world,
    imageUrl: imageUrl,
    verificationState: verificationState,
  );
}

void main() {
  group('AurenNewsArticle', () {
    test('retains source attribution and defaults to unreviewed', () {
      final article = _article();

      expect(article.sourceUri.toString(),
          'https://news.example.org/story/1');
      expect(article.sourceName, 'Example News');
      expect(
        article.verificationState,
        AurenNewsVerificationState.unreviewed,
      );
      expect(article.imageUri, isNull);
    });

    test('accepts HTTPS source and image URLs', () {
      final article = _article(
        imageUrl: 'https://cdn.example.org/images/story-1.jpg',
        verificationState: AurenNewsVerificationState.corroborated,
      );

      expect(article.imageUri?.scheme, 'https');
      expect(
        article.verificationState,
        AurenNewsVerificationState.corroborated,
      );
    });

    test('rejects non-HTTPS source URLs', () {
      expect(
        () => _article(sourceUrl: 'http://news.example.org/story/1'),
        throwsArgumentError,
      );
    });

    test('rejects source URLs containing embedded credentials', () {
      expect(
        () => _article(
          sourceUrl: 'https://user:password@news.example.org/story/1',
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-HTTPS image URLs', () {
      expect(
        () => _article(imageUrl: 'http://cdn.example.org/story.jpg'),
        throwsArgumentError,
      );
    });

    test('rejects blank titles and malformed language tags', () {
      expect(() => _article(title: '  '), throwsArgumentError);
      expect(() => _article(languageCode: 'english'), throwsArgumentError);
    });

    test('freshness respects the configured age window', () {
      final now = DateTime.utc(2026, 10, 16, 12);
      final fresh = _article(
        publishedAt: now.subtract(const Duration(hours: 12)),
      );
      final old = _article(
        publishedAt: now.subtract(const Duration(days: 3)),
      );

      expect(fresh.isFreshAt(now), isTrue);
      expect(old.isFreshAt(now), isFalse);
      expect(
        fresh.isFreshAt(now, maxAge: const Duration(hours: 6)),
        isFalse,
      );
    });

    test('future-dated stories are not marked fresh', () {
      final now = DateTime.utc(2026, 10, 16, 12);
      final scheduled = _article(
        publishedAt: now.add(const Duration(minutes: 5)),
      );

      expect(scheduled.isFreshAt(now), isFalse);
    });
  });
}

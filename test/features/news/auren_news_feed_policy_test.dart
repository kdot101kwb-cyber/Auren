import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/news/domain/auren_news_article.dart';
import 'package:auren/features/news/domain/auren_news_feed_policy.dart';

AurenNewsArticle _article({
  required String id,
  required DateTime publishedAt,
  bool isBreaking = false,
}) {
  return AurenNewsArticle(
    id: id,
    title: 'Headline $id',
    summary: 'Summary $id',
    sourceName: 'Example News',
    sourceUrl: 'https://news.example.org/$id',
    languageCode: 'en',
    publishedAt: publishedAt,
    fetchedAt: DateTime.utc(2026, 10, 16, 12),
    category: AurenNewsCategory.world,
    isBreaking: isBreaking,
  );
}

void main() {
  group('AurenNewsFeedPolicy', () {
    final now = DateTime.utc(2026, 10, 16, 12);

    test('puts breaking stories first without mutating the input', () {
      final older = _article(
        id: 'older',
        publishedAt: now.subtract(const Duration(hours: 2)),
      );
      final breaking = _article(
        id: 'breaking',
        publishedAt: now.subtract(const Duration(days: 4)),
        isBreaking: true,
      );
      final input = <AurenNewsArticle>[older, breaking];

      final result = const AurenNewsFeedPolicy().sortForDisplay(
        input,
        now: now,
      );

      expect(result.map((item) => item.id), ['breaking', 'older']);
      expect(input.first.id, 'older');
    });

    test('places fresh stories before older non-breaking stories', () {
      final old = _article(
        id: 'old',
        publishedAt: now.subtract(const Duration(days: 5)),
      );
      final fresh = _article(
        id: 'fresh',
        publishedAt: now.subtract(const Duration(hours: 1)),
      );

      final result = const AurenNewsFeedPolicy().sortForDisplay(
        [old, fresh],
        now: now,
      );

      expect(result.map((item) => item.id), ['fresh', 'old']);
    });

    test('uses publication time and stable id as tie breakers', () {
      final later = _article(
        id: 'z-story',
        publishedAt: now.subtract(const Duration(hours: 3)),
      );
      final earlier = _article(
        id: 'a-story',
        publishedAt: now.subtract(const Duration(hours: 3)),
      );

      final result = const AurenNewsFeedPolicy().sortForDisplay(
        [later, earlier],
        now: now,
      );

      expect(result.map((item) => item.id), ['a-story', 'z-story']);
    });

    test('does not classify future-dated stories as fresh', () {
      final future = _article(
        id: 'future',
        publishedAt: now.add(const Duration(minutes: 10)),
      );
      final fresh = _article(
        id: 'fresh',
        publishedAt: now.subtract(const Duration(hours: 1)),
      );

      final result = const AurenNewsFeedPolicy().sortForDisplay(
        [future, fresh],
        now: now,
      );

      expect(result.map((item) => item.id), ['fresh', 'future']);
    });
  });
}

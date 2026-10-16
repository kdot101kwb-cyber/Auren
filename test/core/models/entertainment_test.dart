import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/models/entertainment.dart';

void main() {
  group('AurenEntertainmentItem episode metadata', () {
    test('parses linked series and episode ordering metadata', () {
      final item = AurenEntertainmentItem.fromMap('episode-2', {
        'title': 'Episode Two',
        'type': 'Global Series',
        'seriesId': 'series-1',
        'seasonNumber': 2,
        'episodeNumber': 3,
        'episodeOrder': 12,
        'nextEpisodeId': 'episode-3',
      });

      expect(item.id, 'episode-2');
      expect(item.seriesId, 'series-1');
      expect(item.seasonNumber, 2);
      expect(item.episodeNumber, 3);
      expect(item.episodeOrder, 12);
      expect(item.nextEpisodeId, 'episode-3');
    });

    test('supports parentSeriesId when seriesId is absent', () {
      final item = AurenEntertainmentItem.fromMap('episode-1', {
        'parentSeriesId': 'series-parent',
        'seasonNumber': 1,
        'episodeOrder': 4,
      });

      expect(item.seriesId, 'series-parent');
      expect(item.seasonNumber, 1);
      expect(item.episodeOrder, 4);
    });

    test('defaults missing episode metadata safely', () {
      final item = AurenEntertainmentItem.fromMap('standalone', {
        'title': 'Standalone',
      });

      expect(item.seriesId, isEmpty);
      expect(item.nextEpisodeId, isEmpty);
      expect(item.seasonNumber, 0);
      expect(item.episodeNumber, 0);
      expect(item.episodeOrder, 0);
    });
  });
}

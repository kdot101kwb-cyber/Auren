import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/entertainment/presentation/auren_entertainment_job_detail_screen.dart';

void main() {
  Map<String, dynamic> episode(dynamic video) => {
        'episodeNumber': 1,
        'media': {'video': video},
      };

  test('finds the next playable episode after skipped/unplayable entries', () {
    final episodes = [
      episode({'url': 'https://example.com/1.mp4'}),
      episode({'url': ''}),
      episode(null),
      episode({'url': 'https://example.com/4.mp4'}),
    ];
    expect(aurenFindNextPlayableEpisodeIndex(episodes, 1), 3);
  });

  test('accepts string video URLs', () {
    final episodes = [episode('https://example.com/1.mp4')];
    expect(aurenFindNextPlayableEpisodeIndex(episodes, 0), 0);
  });

  test('does not scan beyond the configured episode window', () {
    final episodes = List<dynamic>.generate(
      21,
      (i) => episode(i == 20 ? 'https://example.com/21.mp4' : ''),
    );
    expect(aurenFindNextPlayableEpisodeIndex(episodes, 0), -1);
  });

  test('returns -1 when there is no playable episode', () {
    expect(
      aurenFindNextPlayableEpisodeIndex([
        episode(null),
        episode({'url': ''}),
      ], 0),
      -1,
    );
  });
}

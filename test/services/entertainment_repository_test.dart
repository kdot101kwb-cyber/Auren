import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/entertainment/entertainment_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EntertainmentRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = EntertainmentRepository(firestore: firestore);
  });

  Future<void> addEpisode(
    String id, {
    String? seriesId,
    String? parentSeriesId,
    int season = 1,
    int episode = 1,
    int order = 0,
    String visibility = 'public',
    String? title,
  }) async {
    await firestore.collection('entertainment_items').doc(id).set({
      'title': title ?? 'Episode $id',
      'type': 'Episode',
      'visibility': visibility,
      if (seriesId != null) 'seriesId': seriesId,
      if (parentSeriesId != null) 'parentSeriesId': parentSeriesId,
      'seasonNumber': season,
      'episodeNumber': episode,
      'episodeOrder': order,
    });
  }

  test('loads public episodes linked through either series field in order', () async {
    await addEpisode('late', seriesId: 'series-1', season: 2, episode: 1);
    await addEpisode('first', parentSeriesId: 'series-1', season: 1, episode: 1);
    await addEpisode('middle', seriesId: 'series-1', season: 1, episode: 2);
    await addEpisode('private', parentSeriesId: 'series-1', visibility: 'private');

    final episodes = await repository.watchSeriesEpisodes('series-1')
        .firstWhere((items) => items.length == 3);

    expect(episodes.map((item) => item.id).toList(),
        ['first', 'middle', 'late']);
    expect(episodes.every((item) => item.id != 'private'), isTrue);
  });

  test('deduplicates records matching both series fields', () async {
    await addEpisode(
      'shared',
      seriesId: 'series-1',
      parentSeriesId: 'series-1',
    );

    final episodes = await repository.watchSeriesEpisodes('series-1')
        .firstWhere((items) => items.isNotEmpty);

    expect(episodes.map((item) => item.id).toList(), ['shared']);
  });

  test('uses episodeOrder before episodeNumber within a season', () async {
    await addEpisode('number-first', seriesId: 'series-1', episode: 1);
    await addEpisode('order-first', seriesId: 'series-1', episode: 9, order: 2);
    await addEpisode('order-second', seriesId: 'series-1', episode: 1, order: 3);

    final episodes = await repository.watchSeriesEpisodes('series-1')
        .firstWhere((items) => items.length == 3);

    expect(episodes.map((item) => item.id).toList(),
        ['number-first', 'order-first', 'order-second']);
  });

  test('uses title and id as stable ordering fallbacks', () async {
    await addEpisode('z-id', seriesId: 'series-1', title: 'Same title');
    await addEpisode('a-id', parentSeriesId: 'series-1', title: 'Same title');
    await addEpisode('beta', seriesId: 'series-1', title: 'Beta');

    final episodes = await repository.watchSeriesEpisodes('series-1')
        .firstWhere((items) => items.length == 3);

    expect(episodes.map((item) => item.id).toList(),
        ['beta', 'a-id', 'z-id']);
  });

  test('returns an empty stream for a blank series id', () async {
    expect(await repository.watchSeriesEpisodes('  ').first, isEmpty);
  });
}

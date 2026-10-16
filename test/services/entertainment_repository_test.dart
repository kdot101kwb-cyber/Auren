import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:auren/core/models/entertainment.dart';
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

  AurenEntertainmentItem makeItem({String id = 'item-1', String title = 'Test item'}) =>
      AurenEntertainmentItem(
        id: id,
        title: title,
        type: 'Episode',
        description: '',
        imageUrl: 'https://example.com/poster.jpg',
        mediaUrl: 'https://example.com/video.mp4',
        mediaKind: 'video',
        seriesId: 'series-1',
        seasonNumber: 1,
        episodeNumber: 2,
      );

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

  test('updates the episode list when a linked episode is added', () async {
    await addEpisode('episode-1', seriesId: 'series-live');

    final future = repository.watchSeriesEpisodes('series-live')
        .firstWhere((items) => items.length == 2);

    await addEpisode('episode-2', parentSeriesId: 'series-live', episode: 2);

    final episodes = await future;
    expect(episodes.map((item) => item.id).toList(),
        ['episode-1', 'episode-2']);
  });

  test('watchItem exposes public items but hides private or missing items', () async {
    await firestore.collection('entertainment_items').doc('public-item').set({
      'title': 'Public episode', 'type': 'Episode', 'visibility': 'public',
    });
    await firestore.collection('entertainment_items').doc('private-item').set({
      'title': 'Private episode', 'type': 'Episode', 'visibility': 'private',
    });

    final publicItem = await repository.watchItem('public-item')
        .firstWhere((item) => item != null);
    expect(publicItem!.title, 'Public episode');
    expect(await repository.watchItem('private-item').first, isNull);
    expect(await repository.watchItem('missing-item').first, isNull);
  });

  test('records watch history progress with episode metadata', () async {
    final item = makeItem();
    await repository.recordWatchProgress(
      'user-1', item,
      seconds: 25,
      durationSeconds: 100,
      completed: false,
    );

    final doc = await firestore.collection('users').doc('user-1')
        .collection('watchHistory').doc('item-1').get();
    final data = doc.data()!;
    expect(data['itemId'], 'item-1');
    expect(data['seriesId'], 'series-1');
    expect(data['seasonNumber'], 1);
    expect(data['episodeNumber'], 2);
    expect(data['lastPositionSeconds'], 25);
    expect(data['durationSeconds'], 100);
    expect(data['progress'], 0.25);
    expect(data['completed'], isFalse);
  });

  test('clears Continue Watching when playback reaches completion threshold', () async {
    final item = makeItem();
    final ref = firestore.collection('users').doc('user-1')
        .collection('continueWatching').doc('item-1');
    await repository.saveWatchProgress(
      'user-1', item, const Duration(seconds: 40), const Duration(seconds: 100));
    expect((await ref.get()).exists, isTrue);

    await repository.saveWatchProgress(
      'user-1', item, const Duration(seconds: 95), const Duration(seconds: 100));
    expect((await ref.get()).exists, isFalse);
  });

  test('saves episode context and normalized Continue Watching progress', () async {
    final item = makeItem();
    await repository.saveWatchProgress(
      'user-1', item, const Duration(seconds: 40), const Duration(seconds: 100));

    final doc = await firestore.collection('users').doc('user-1')
        .collection('continueWatching').doc('item-1').get();
    final data = doc.data()!;
    expect(data['itemId'], 'item-1');
    expect(data['seriesId'], 'series-1');
    expect(data['seasonNumber'], 1);
    expect(data['episodeNumber'], 2);
    expect(data['positionSeconds'], 40);
    expect(data['durationSeconds'], 100);
    expect(data['progress'], 0.4);
  });

  test('does not write watch progress when uid or item id is blank', () async {
    await repository.saveWatchProgress(
      '', makeItem(), const Duration(seconds: 10), const Duration(seconds: 100));
    await repository.saveWatchProgress(
      'user-1', makeItem(id: ''), const Duration(seconds: 10), const Duration(seconds: 100));

    final progress = await firestore.collection('users').doc('user-1')
        .collection('continueWatching').get();
    expect(progress.docs, isEmpty);
  });

  test('streams Continue Watching records when progress is saved', () async {
    final future = repository.watchContinueWatching('user-1')
        .firstWhere((entries) => entries.any((entry) => entry['itemId'] == 'item-1'));
    await repository.saveWatchProgress(
      'user-1', makeItem(), const Duration(seconds: 20), const Duration(seconds: 100));

    final entries = await future;
    expect(entries.single['itemId'], 'item-1');
    expect(entries.single['positionSeconds'], 20);
  });

  test('returns an empty stream for a blank series id', () async {
    expect(await repository.watchSeriesEpisodes('  ').first, isEmpty);
  });
}

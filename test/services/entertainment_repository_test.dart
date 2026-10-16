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

  test('clamps watch history progress to valid playback bounds', () async {
    final item = makeItem();
    await repository.recordWatchProgress(
      'user-1', item,
      seconds: 140,
      durationSeconds: 100,
      completed: false,
    );

    final doc = await firestore.collection('users').doc('user-1')
        .collection('watchHistory').doc('item-1').get();
    final data = doc.data()!;
    expect(data['lastPositionSeconds'], 100);
    expect(data['durationSeconds'], 100);
    expect(data['progress'], 1.0);

    await repository.recordWatchProgress(
      'user-1', item,
      seconds: -10,
      durationSeconds: 100,
      completed: false,
    );
    final rewound = await firestore.collection('users').doc('user-1')
        .collection('watchHistory').doc('item-1').get();
    expect(rewound.data()?['lastPositionSeconds'], 0);
    expect(rewound.data()?['progress'], 0.0);
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

  test('ignores invalid generated-series progress deletion inputs', () async {
    await repository.clearSeriesWatchProgress('', 'job-1', 1);
    await repository.clearSeriesWatchProgress('user-1', '  ', 1);
    await repository.clearSeriesWatchProgress('user-1', 'job-1', 0);

    final records = await firestore.collection('users').doc('user-1')
        .collection('seriesWatchProgress').get();
    expect(records.docs, isEmpty);
  });

  test('clears a generated-series episode progress record', () async {
    await repository.saveSeriesWatchProgress(
      'user-1', 'job-1', 2,
      positionSeconds: 15,
      durationSeconds: 90,
      title: 'Episode Two',
    );
    expect(await repository.getSeriesWatchProgress('user-1', 'job-1', 2), isNotNull);

    await repository.clearSeriesWatchProgress('user-1', 'job-1', 2);
    expect(await repository.getSeriesWatchProgress('user-1', 'job-1', 2), isNull);
  });

  test('stores and clamps generated-series episode progress', () async {
    await repository.saveSeriesWatchProgress(
      'user-1', 'job-1', 3,
      positionSeconds: 140,
      durationSeconds: 100,
      title: 'Episode Three',
      videoUrl: 'https://example.com/episode-3.mp4',
    );

    final progress = await repository.getSeriesWatchProgress('user-1', 'job-1', 3);
    expect(progress, isNotNull);
    expect(progress!['episodeNumber'], 3);
    expect(progress['title'], 'Episode Three');
    expect(progress['positionSeconds'], 100);
    expect(progress['progress'], 1.0);
    expect(progress['completed'], isFalse);
  });

  test('returns null for missing watch progress and the saved record otherwise', () async {
    expect(await repository.getWatchProgress('user-1', 'item-1'), isNull);

    await repository.saveWatchProgress(
      'user-1', makeItem(), const Duration(seconds: 30), const Duration(seconds: 120));
    final progress = await repository.getWatchProgress('user-1', 'item-1');
    expect(progress, isNotNull);
    expect(progress!['positionSeconds'], 30);
    expect(progress['durationSeconds'], 120);
  });

  test('records a watch start with episode context', () async {
    await repository.recordWatchStarted('user-1', makeItem());

    final doc = await firestore.collection('users').doc('user-1')
        .collection('watchHistory').doc('item-1').get();
    final data = doc.data()!;
    expect(data['itemId'], 'item-1');
    expect(data['title'], 'Test item');
    expect(data['type'], 'Episode');
    expect(data['seriesId'], 'series-1');
    expect(data['seasonNumber'], 1);
    expect(data['episodeNumber'], 2);
    expect(data['views'], 1);
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

  test('aggregates Short actions and preserves action history', () async {
    await repository.trackShortAction('user-1', 'short-1', action: 'like', mood: 'ضحك');
    await repository.trackShortAction('user-1', 'short-1', action: 'save', mood: 'ضحك');
    await repository.trackShortAction('user-1', 'short-1', action: 'skip', mood: 'موسيقى');

    final signal = await firestore.collection('users').doc('user-1')
        .collection('entertainmentSignals').doc('short-1').get();
    final data = signal.data()!;
    expect(data['likes'], 1);
    expect(data['saves'], 1);
    expect(data['skips'], 1);
    expect(data['mood'], 'موسيقى');

    final actions = await signal.reference.collection('actions').get();
    expect(actions.docs, hasLength(3));
    expect(actions.docs.map((doc) => doc.data()['action']).toSet(),
        {'like', 'save', 'skip'});
  });

  test('aggregates Short watch time, views, and completions', () async {
    await repository.trackShortView(
      'user-1', 'short-1', seconds: 7, completed: false, mood: 'تسلية');
    await repository.trackShortView(
      'user-1', 'short-1', seconds: 8, completed: true, mood: 'موسيقى');

    final signal = await firestore.collection('users').doc('user-1')
        .collection('entertainmentSignals').doc('short-1').get();
    final data = signal.data()!;
    expect(data['watchSeconds'], 15);
    expect(data['views'], 2);
    expect(data['completions'], 1);
    expect(data['mood'], 'موسيقى');
  });

  test('does not write Short action analytics for blank identifiers', () async {
    await repository.trackShortAction('', 'short-1', action: 'like', mood: 'تسلية');
    await repository.trackShortAction('user-1', '  ', action: 'save', mood: 'تسلية');

    final signals = await firestore.collection('users').doc('user-1')
        .collection('entertainmentSignals').get();
    expect(signals.docs, isEmpty);
  });

  test('does not write Short view analytics for blank identifiers', () async {
    await repository.trackShortView('', 'short-1', seconds: 5, completed: false, mood: 'تسلية');
    await repository.trackShortView('user-1', '  ', seconds: 5, completed: false, mood: 'تسلية');

    final signals = await firestore.collection('users').doc('user-1')
        .collection('entertainmentSignals').get();
    expect(signals.docs, isEmpty);
  });

  test('rejects empty and oversized Short comments', () async {
    await repository.addShortComment('user-1', 'short-1', '   ');
    await repository.addShortComment('user-1', 'short-1', 'x' * 1001);

    final comments = await firestore.collection('entertainment_items')
        .doc('short-1').collection('comments').get();
    expect(comments.docs, isEmpty);
    final signal = await firestore.collection('users').doc('user-1')
        .collection('entertainmentSignals').doc('short-1').get();
    expect(signal.exists, isFalse);
  });

  test('trims Short comments and records comment analytics', () async {
    await repository.addShortComment('user-1', 'short-1', '  Nice clip  ', mood: 'ضحك');

    final comments = await firestore.collection('entertainment_items')
        .doc('short-1').collection('comments').get();
    expect(comments.docs, hasLength(1));
    expect(comments.docs.single.data()['text'], 'Nice clip');
    expect(comments.docs.single.data()['uid'], 'user-1');

    final signal = await firestore.collection('users').doc('user-1')
        .collection('entertainmentSignals').doc('short-1').get();
    expect(signal.data()?['mood'], 'ضحك');
    final actions = await signal.reference.collection('actions').get();
    expect(actions.docs.single.data()['action'], 'comment');
  });

  test('updates the like stream when a Short is liked and unliked', () async {
    final liked = repository.watchLiked('user-1', 'short-1');
    expect(await liked.first, isFalse);

    final becomesLiked = repository.watchLiked('user-1', 'short-1')
        .firstWhere((value) => value);
    await repository.toggleLike('user-1', 'short-1', true);
    expect(await becomesLiked, isTrue);

    final becomesUnliked = repository.watchLiked('user-1', 'short-1')
        .firstWhere((value) => !value);
    await repository.toggleLike('user-1', 'short-1', false);
    expect(await becomesUnliked, isFalse);
  });

  test('shows only public items in saved entertainment', () async {
    await firestore.collection('entertainment_items').doc('public-item').set({
      'title': 'Public item', 'type': 'Movie', 'visibility': 'public',
    });
    await firestore.collection('entertainment_items').doc('private-item').set({
      'title': 'Private item', 'type': 'Movie', 'visibility': 'private',
    });
    await firestore.collection('users').doc('user-1')
        .collection('savedEntertainment').doc('public-item').set({'itemId': 'public-item'});
    await firestore.collection('users').doc('user-1')
        .collection('savedEntertainment').doc('private-item').set({'itemId': 'private-item'});
    await firestore.collection('users').doc('user-1')
        .collection('savedEntertainment').doc('missing-item').set({'itemId': 'missing-item'});

    final items = await repository.watchSavedItems('user-1').first;
    expect(items.map((item) => item.id).toList(), ['public-item']);
  });

  test('streams watch history after playback starts', () async {
    final future = repository.watchHistory('user-1')
        .firstWhere((entries) => entries.any((entry) => entry['itemId'] == 'item-1'));
    await repository.recordWatchStarted('user-1', makeItem());

    final entries = await future;
    expect(entries.single['itemId'], 'item-1');
    expect(entries.single['title'], 'Test item');
    expect(entries.single['views'], 1);
  });

  test('returns an empty watch history stream for a blank user id', () async {
    expect(await repository.watchHistory('').first, isEmpty);
  });

  test('returns an empty Continue Watching stream for a blank user id', () async {
    expect(await repository.watchContinueWatching('  ').first, isEmpty);
  });

  test('returns an empty stream for a blank series id', () async {
    expect(await repository.watchSeriesEpisodes('  ').first, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/entertainment/auren_radio_favorites_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves, restores and removes a favorite station locally', () async {
    final service = AurenRadioFavoritesService();
    const station = AurenRadioFavorite(
      id: 'station-1',
      name: 'Example Radio',
      streamUrl: 'https://radio.example/stream',
      country: 'SD',
      language: 'ar',
      tags: 'news,music',
    );

    await service.save(station);
    expect(await service.contains('station-1'), isTrue);
    expect((await service.list()).single.name, 'Example Radio');

    await service.remove('station-1');
    expect(await service.list(), isEmpty);
  });

  test('rejects invalid stream schemes and ignores malformed cache', () async {
    final service = AurenRadioFavoritesService();
    await expectLater(
      service.save(const AurenRadioFavorite(
        id: 'station-2',
        name: 'Unsafe Radio',
        streamUrl: 'javascript:alert(1)',
      )),
      throwsArgumentError,
    );
    SharedPreferences.setMockInitialValues({
      'auren.radio_favorites.v1': '{broken',
    });
    expect(await AurenRadioFavoritesService().list(), isEmpty);
  });

  test('updating the same station does not create duplicate favorites', () async {
    final service = AurenRadioFavoritesService();
    await service.save(const AurenRadioFavorite(
      id: 'station-3',
      name: 'First title',
      streamUrl: 'https://radio.example/stream',
    ));
    await service.save(const AurenRadioFavorite(
      id: 'station-3',
      name: 'Updated title',
      streamUrl: 'https://radio.example/live',
    ));

    final favorites = await service.list();
    expect(favorites, hasLength(1));
    expect(favorites.single.name, 'Updated title');
  });
}

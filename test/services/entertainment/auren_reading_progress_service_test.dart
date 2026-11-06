import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/entertainment/auren_reading_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reading status persists and updates without duplicate entries', () async {
    final service = AurenReadingProgressService();
    await service.setStatus(
      itemId: 'book-1',
      title: 'A Book',
      status: AurenReadingStatus.wantToRead,
    );
    await service.setStatus(
      itemId: 'book-1',
      title: 'A Book',
      status: AurenReadingStatus.inProgress,
    );

    final rows = await service.list();
    expect(rows, hasLength(1));
    expect(rows.single.status, AurenReadingStatus.inProgress);
    expect((await service.get('book-1'))?.title, 'A Book');
  });

  test('rejects invalid metadata and removes a saved item', () async {
    final service = AurenReadingProgressService();
    await expectLater(
      service.setStatus(
        itemId: '',
        title: 'No ID',
        status: AurenReadingStatus.completed,
      ),
      throwsArgumentError,
    );
    await service.setStatus(
      itemId: 'book-2',
      title: 'Another Book',
      status: AurenReadingStatus.completed,
    );
    await service.remove('book-2');
    expect(await service.get('book-2'), isNull);
  });

  test('malformed local data safely returns an empty shelf', () async {
    SharedPreferences.setMockInitialValues({
      'auren.reading_progress.v1': '{broken',
    });
    expect(await AurenReadingProgressService().list(), isEmpty);
  });
}

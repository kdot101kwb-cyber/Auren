import 'dart:io';

import 'package:auren/services/platform/auren_platform_tools_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('help topics are stable and cover common local-first questions', () {
    final ids = AurenPlatformToolsService.helpTopics.map((topic) => topic.id);
    expect(ids.toSet(), containsAll(['offline', 'privacy', 'troubleshooting', 'storage']));
    expect(ids.toSet(), hasLength(ids.length));
    expect(
      AurenPlatformToolsService.helpTopics
          .firstWhere((topic) => topic.id == 'storage')
          .body,
      contains('لن نحذف'),
    );
  });

  test('feedback drafts save, restore, update and remove locally', () async {
    final service = AurenPlatformToolsService();
    await service.saveFeedback(
      id: 'draft-1',
      kind: 'bug',
      title: 'Screen freezes',
      details: 'The page stops responding after opening.',
      createdAt: DateTime.utc(2026, 10, 23),
    );
    await service.saveFeedback(
      id: 'draft-1',
      kind: 'feedback',
      title: 'Updated title',
      details: 'Updated details',
      createdAt: DateTime.utc(2026, 10, 24),
    );

    final drafts = await service.feedbackDrafts();
    expect(drafts, hasLength(1));
    expect(drafts.single.kind, 'feedback');
    expect(drafts.single.title, 'Updated title');

    await service.removeFeedback('draft-1');
    expect(await service.feedbackDrafts(), isEmpty);
  });

  test('feedback rejects empty, oversized and unsupported drafts', () async {
    final service = AurenPlatformToolsService();
    await expectLater(
      service.saveFeedback(
        id: 'bad',
        kind: 'message',
        title: 'Unsupported destination',
        details: 'Must not be sent.',
      ),
      throwsArgumentError,
    );
    await expectLater(
      service.saveFeedback(
        id: 'bad-2',
        kind: 'bug',
        title: '',
        details: 'No title',
      ),
      throwsArgumentError,
    );
  });

  test('storage inspection and cleanup are restricted to owned cache folder',
      () async {
    final root = await Directory.systemTemp.createTemp('auren-platform-tools-');
    addTearDown(() => root.delete(recursive: true));
    final owned = Directory('${root.path}${Platform.pathSeparator}auren_platform_tools_cache');
    await owned.create();
    await File('${owned.path}${Platform.pathSeparator}sample.bin')
        .writeAsBytes([1, 2, 3, 4, 5]);
    final unrelated = File('${root.path}${Platform.pathSeparator}keep.txt');
    await unrelated.writeAsString('preserve');

    final service = AurenPlatformToolsService(
      temporaryDirectoryProvider: () async => root,
    );
    final snapshot = await service.inspectCache();
    expect(snapshot.fileCount, 1);
    expect(snapshot.bytes, 5);

    await service.clearOwnedCache();
    expect((await service.inspectCache()).bytes, 0);
    expect(await unrelated.readAsString(), 'preserve');
  });

  test('connectivity report describes network type without claiming internet', () {
    final offline = AurenPlatformToolsService.reportFor(
      const [ConnectivityResult.none],
    );
    expect(offline.summary, contains('لا يوجد اتصال'));
    expect(offline.internetVerified, isFalse);

    final wifi = AurenPlatformToolsService.reportFor(
      const [ConnectivityResult.wifi],
    );
    expect(wifi.summary, contains('Wi-Fi'));
    expect(wifi.summary, contains('لا يؤكد'));
    expect(wifi.internetVerified, isFalse);
  });

  test('byte formatting uses readable units', () {
    expect(AurenPlatformToolsService.formatBytes(42), '42 B');
    expect(AurenPlatformToolsService.formatBytes(2048), '2.0 KB');
    expect(AurenPlatformToolsService.formatBytes(2 * 1024 * 1024), '2.0 MB');
  });
}

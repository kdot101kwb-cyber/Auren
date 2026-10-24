import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/offline/auren_offline_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('enqueue returns existing ID for duplicate idempotency key', () async {
    final service = AurenOfflineSyncService.instance;
    final first = await service.enqueue(
      type: 'save', payload: {'value': 1}, idempotencyKey: 'operation-1',
    );
    final second = await service.enqueue(
      type: 'save', payload: {'value': 2}, idempotencyKey: 'operation-1',
    );
    expect(second, first);
    expect((await service.pending()).length, 1);
    await service.clear();
  });

  test('full queue rejects new work without evicting pending records', () async {
    final service = AurenOfflineSyncService.instance;
    for (var i = 0; i < 100; i++) {
      await service.enqueue(type: 'save', payload: {'index': i});
    }
    await expectLater(
      service.enqueue(type: 'save', payload: {'index': 100}),
      throwsStateError,
    );
    final pending = await service.pending();
    expect(pending.length, 100);
    expect((pending.first['payload'] as Map)['index'], 0);
    expect((pending.last['payload'] as Map)['index'], 99);
    await service.clear();
  });

  test('successful replay does not erase an item enqueued during handler', () async {
    final service = AurenOfflineSyncService.instance;
    final entered = Completer<void>();
    final release = Completer<void>();
    await service.enqueue(type: 'slow', payload: {'old': true});
    service.registerHandler('slow', (_) async {
      entered.complete();
      await release.future;
    });
    final flushing = service.flush();
    await entered.future;
    await service.enqueue(type: 'later', payload: {'new': true});
    release.complete();
    await flushing;
    final pending = await service.pending();
    expect(pending.length, 1);
    expect(pending.single['type'], 'later');
    service.unregisterHandler('slow');
    await service.clear();
  });
}

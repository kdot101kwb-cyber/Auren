import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auren/features/everyday_life/data/everyday_life_local_store.dart';
import 'package:auren/features/everyday_life/domain/everyday_life_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  EverydayLifeItem item({
    String id = 'one',
    EverydayLifeKind kind = EverydayLifeKind.task,
    String title = 'Buy supplies',
    bool confirmed = false,
  }) => EverydayLifeItem(
    id: id,
    kind: kind,
    title: title,
    informationConfirmed: confirmed,
  );

  test('saves, reads, updates and deletes local records', () async {
    final store = EverydayLifeLocalStore();
    await store.save(item());
    expect((await store.readAll()).single.title, 'Buy supplies');

    await store.save(item(title: 'Restock cleaning supplies'));
    expect((await store.readAll()).single.title, 'Restock cleaning supplies');

    await store.delete('one');
    expect(await store.readAll(), isEmpty);
  });

  test('supports all four systems without merging their record types', () async {
    final store = EverydayLifeLocalStore();
    await store.save(item(id: 'task', kind: EverydayLifeKind.task));
    await store.save(item(id: 'home', kind: EverydayLifeKind.household));
    await store.save(item(id: 'draft', kind: EverydayLifeKind.appointmentDraft));
    await store.save(item(id: 'service', kind: EverydayLifeKind.localService));

    final items = await store.readAll();
    expect(items.map((entry) => entry.kind).toSet(), EverydayLifeKind.values.toSet());
  });

  test('local service details are unconfirmed unless explicitly marked', () {
    final unconfirmed = EverydayLifeItem.fromJson(
      item(kind: EverydayLifeKind.localService).toJson(),
    );
    expect(unconfirmed.informationConfirmed, isFalse);
    expect(unconfirmed.copyWith(informationConfirmed: true).informationConfirmed, isTrue);
  });

  test('rejects blank titles instead of persisting unusable records', () async {
    final store = EverydayLifeLocalStore();
    await expectLater(
      store.save(item(title: '   ')),
      throwsArgumentError,
    );
    expect(await store.readAll(), isEmpty);
  });

  test('skips malformed records while preserving valid local data', () async {
    SharedPreferences.setMockInitialValues({
      EverydayLifeLocalStore.storageKey:
          '[{"id":"ok","kind":"task","title":"Valid"},'
          '{"id":"","kind":"task","title":"Broken"}]',
    });
    final items = await EverydayLifeLocalStore().readAll();
    expect(items.map((entry) => entry.title), ['Valid']);
  });

  test('appointment drafts do not have implicit provider or confirmation', () {
    final draft = item(kind: EverydayLifeKind.appointmentDraft);
    expect(draft.providerName, isEmpty);
    expect(draft.dueAt, isNull);
    expect(draft.informationConfirmed, isFalse);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/everyday/appointment_draft_service.dart';
import 'package:auren/services/everyday/appointment_draft_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  AurenAppointmentDraft makeDraft({String title = 'Visit'}) =>
      AurenAppointmentDraft(
        id: 'visit',
        title: title,
        startsAt: DateTime.now().add(const Duration(days: 3)),
      );

  test('isolates records by UID', () async {
    final store = AurenAppointmentDraftStore();
    await store.saveDraft('user-a', makeDraft());
    expect((await store.loadDrafts('user-a')).single.id, 'visit');
    expect(await store.loadDrafts('user-b'), isEmpty);
  });

  test('rejects blank UID and invalid input', () async {
    final store = AurenAppointmentDraftStore();
    await expectLater(store.loadDrafts(' '), throwsArgumentError);
    await expectLater(
      store.saveDraft('user-a', makeDraft(title: '')),
      throwsArgumentError,
    );
  });

  test('stores completed appointment status and rejects reopening', () async {
    final store = AurenAppointmentDraftStore();
    await store.saveDraft('user-a', makeDraft());
    await store.transitionDraft('user-a', 'visit', AppointmentDraftStatus.completed);
    expect((await store.loadDrafts('user-a')).single.status, AppointmentDraftStatus.completed);
    await expectLater(store.transitionDraft('user-a', 'visit', AppointmentDraftStatus.planned), throwsStateError);
    expect((await store.loadDrafts('user-a')).single.status, AppointmentDraftStatus.completed);
  });

  test('rejects malformed explicit versions and preserves stored bytes', () async {
    final store = AurenAppointmentDraftStore();
    final prefs = await SharedPreferences.getInstance();
    final key = 'auren_appointment_drafts_v1_${base64Url.encode(utf8.encode('user-a'))}';

    for (final versionJson in ['null', '"1"', '1.0', '2']) {
      final original = '{"version":$versionJson,"items":[]}';
      await prefs.setString(key, original);

      await expectLater(store.loadDrafts('user-a'), throwsFormatException);
      await expectLater(store.saveDraft('user-a', makeDraft()), throwsFormatException);
      expect(prefs.getString(key), original);
    }
  });
}

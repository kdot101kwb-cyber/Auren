import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/everyday/appointment_draft_service.dart';
import 'package:auren/services/everyday/appointment_draft_store.dart';
void main() {
 setUp(() => SharedPreferences.setMockInitialValues({}));
 AurenAppointmentDraft makeDraft({String title = 'Visit'}) => AurenAppointmentDraft(id: 'visit', title: title, startsAt: DateTime.now().add(const Duration(days: 3)));
 test('isolates records by UID', () async { final store = AurenAppointmentDraftStore(); await store.saveDraft('user-a', makeDraft()); expect((await store.loadDrafts('user-a')).single.id, 'visit'); expect(await store.loadDrafts('user-b'), isEmpty); });
 test('rejects blank UID and invalid input', () async { final store = AurenAppointmentDraftStore(); await expectLater(store.loadDrafts(' '), throwsArgumentError); await expectLater(store.saveDraft('user-a', makeDraft(title: '')), throwsArgumentError); });
}

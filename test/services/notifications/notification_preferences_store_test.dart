import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/notifications/domain/notification_preferences.dart';
import 'package:auren/services/notifications/notification_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists preferences independently per user', () async {
    const store = AurenNotificationPreferencesStore();
    await store.save('user-a', const AurenNotificationPreferences(
      mutedCategories: {'social'}, unreadOnly: true, showInAppBanners: false,
    ));
    await store.save('user-b', const AurenNotificationPreferences(
      mutedCategories: {'sports'},
    ));
    expect((await store.load('user-a')).mutedCategories, {'social'});
    expect((await store.load('user-a')).unreadOnly, isTrue);
    expect((await store.load('user-b')).mutedCategories, {'sports'});
  });

  test('malformed stored data falls back safely', () async {
    SharedPreferences.setMockInitialValues({
      'auren_notification_preferences_v1_user-a': '{not-json',
    });
    const store = AurenNotificationPreferencesStore();
    expect((await store.load('user-a')).showInAppBanners, isTrue);
  });

  test('rejects invalid user identifiers', () async {
    const store = AurenNotificationPreferencesStore();
    await expectLater(store.load('../other'), throwsArgumentError);
    await expectLater(store.save('', const AurenNotificationPreferences()), throwsArgumentError);
  });
}

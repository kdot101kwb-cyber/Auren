import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/notifications/domain/notification_preferences.dart';

void main() {
  test('filters muted categories and optionally read items', () {
    const prefs = AurenNotificationPreferences(mutedCategories: {'social'}, unreadOnly: true);
    expect(prefs.shouldDisplay(category: 'social', isRead: false), isFalse);
    expect(prefs.shouldDisplay(category: 'sports', isRead: true), isFalse);
    expect(prefs.shouldDisplay(category: 'sports', isRead: false), isTrue);
  });

  test('round trips and ignores malformed preference fields', () {
    final decoded = AurenNotificationPreferences.fromJson({
      'mutedCategories': ['sports', 12, List<String>.filled(65, 'x').join()],
      'unreadOnly': true,
      'showInAppBanners': false,
    });
    expect(decoded.mutedCategories, {'sports'});
    expect(decoded.unreadOnly, isTrue);
    expect(decoded.showInAppBanners, isFalse);
    expect(AurenNotificationPreferences.fromJson({}).showInAppBanners, isTrue);
  });
}

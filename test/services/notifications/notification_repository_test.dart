import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/notifications/notification_repository.dart';

void main() {
  test('notification repository rejects invalid user ids', () {
    final repository = NotificationRepository();

    expect(() => repository.watch(''), throwsArgumentError);
    expect(() => repository.watch('   '), throwsArgumentError);
    expect(() => repository.watch('x' * 129), throwsArgumentError);
  });

  test('notification repository rejects invalid notification ids', () {
    final repository = NotificationRepository();

    expect(() => repository.markRead('uid', ''), throwsArgumentError);
    expect(() => repository.markRead('uid', '   '), throwsArgumentError);
    expect(() => repository.markRead('uid', 'x' * 129), throwsArgumentError);
  });

  test('notification parser keeps safe defaults for missing fields', () {
    final notification = AurenNotification.fromMap('n1', {});

    expect(notification.id, 'n1');
    expect(notification.title, isEmpty);
    expect(notification.body, isEmpty);
    expect(notification.read, isFalse);
    expect(notification.type, 'system');
    expect(notification.actorUid, isNull);
  });
}

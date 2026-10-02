/// Compatibility service for the canonical notification repository.
///
/// Older callers can keep using this API without a second notification model
/// or Firestore implementation.
library;

import '../notifications/notification_repository.dart' as canonical;

typedef AurenNotification = canonical.AurenNotification;

class AurenNotificationService {
  final canonical.NotificationRepository _repo;

  AurenNotificationService({dynamic db}) : _repo = canonical.NotificationRepository();

  Stream<List<AurenNotification>> watch(String uid, {int limit = 100}) =>
      _repo.watch(uid).map((items) => items.take(limit.clamp(1, 100)).toList());

  Stream<int> watchUnreadCount(String uid) => _repo.watchUnreadCount(uid);
  Future<void> markRead(String uid, String id) => _repo.markRead(uid, id);
  Future<void> markUnread(String uid, String id) => _repo.markUnread(uid, id);
  Future<void> markAllRead(String uid) => _repo.markAllRead(uid);
}

/// Compatibility entry point for the canonical notification center.
///
/// AUREN previously had two notification UIs. Keep this import stable while
/// routing everything through the canonical screen.
library;

import 'notifications_screen.dart';

typedef AurenNotificationCenterScreen = AurenNotificationsScreen;

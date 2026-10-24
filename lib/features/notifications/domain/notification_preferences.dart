/// In-app display preferences only; does not change FCM or Messenger delivery.
class AurenNotificationPreferences {
  const AurenNotificationPreferences({
    this.mutedCategories = const {},
    this.unreadOnly = false,
    this.showInAppBanners = true,
  });

  final Set<String> mutedCategories;
  final bool unreadOnly;
  final bool showInAppBanners;

  bool shouldDisplay({
    required String category,
    required bool isRead,
  }) =>
      !mutedCategories.contains(category) && (!unreadOnly || !isRead);

  AurenNotificationPreferences copyWith({
    Set<String>? mutedCategories,
    bool? unreadOnly,
    bool? showInAppBanners,
  }) =>
      AurenNotificationPreferences(
        mutedCategories: Set.unmodifiable(mutedCategories ?? this.mutedCategories),
        unreadOnly: unreadOnly ?? this.unreadOnly,
        showInAppBanners: showInAppBanners ?? this.showInAppBanners,
      );

  Map<String, Object?> toJson() => {
        'mutedCategories': mutedCategories.toList()..sort(),
        'unreadOnly': unreadOnly,
        'showInAppBanners': showInAppBanners,
      };

  factory AurenNotificationPreferences.fromJson(Map<String, Object?> json) {
    final rawMuted = json['mutedCategories'];
    return AurenNotificationPreferences(
      mutedCategories: Set.unmodifiable(
        rawMuted is List
            ? rawMuted.whereType<String>().where((value) => value.length <= 64)
            : const <String>[],
      ),
      unreadOnly: json['unreadOnly'] == true,
      showInAppBanners: json['showInAppBanners'] != false,
    );
  }
}

/// Shared validation for direct Shorts uploads.
class AurenShortUploadPolicy {
  AurenShortUploadPolicy._();

  static const maxBytes = 25 * 1024 * 1024;
  static const maxDuration = Duration(seconds: 180);
  static const categories = <String>[
    'كرتون',
    'كوميديا',
    'فلوقات',
    'موسيقى',
    'ألعاب',
    'تعليمي',
    'رياضة',
    'منوعات',
  ];
  static const moods = <String>[
    'تسلية',
    'ضحك',
    'موسيقى',
    'أفلام',
    'Gaming',
    'اكتشاف',
  ];

  static bool isMp4FileName(String name) =>
      name.trim().toLowerCase().split('.').last == 'mp4';

  static bool isValidFileSize(int bytes) => bytes > 0 && bytes <= maxBytes;

  static bool isValidDuration(Duration duration) =>
      duration > Duration.zero && duration <= maxDuration;

  static String? validateTitle(String title) {
    final value = title.trim();
    if (value.isEmpty) return 'العنوان مطلوب.';
    if (value.length > 160) return 'العنوان أطول من 160 حرفاً.';
    return null;
  }

  static String? validateDescription(String description) =>
      description.length > 3000 ? 'الوصف أطول من 3000 حرف.' : null;

  static bool isAllowedCategory(String category) =>
      categories.contains(category);

  static bool isAllowedMood(String mood) => moods.contains(mood);

  static List<String> parseTags(String input) => input
      .split(RegExp(r'[,،#\s]+'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .take(20)
      .toList();
}

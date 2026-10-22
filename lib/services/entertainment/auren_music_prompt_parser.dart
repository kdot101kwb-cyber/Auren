/// Shared parsing rules for Arabic and English music-session prompts.
class AurenMusicPromptParser {
  const AurenMusicPromptParser._();

  static String normalizeDigits(String input) => input.replaceAllMapped(
        RegExp(r'[٠-٩]'),
        (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0x0660 + 0x30),
      );

  /// Returns a duration in minutes, clamped to the supported 10–240 range.
  /// Returns null when the prompt contains no recognizable duration.
  static int? durationMinutes(String input) {
    final text = normalizeDigits(input.toLowerCase());
    final hours = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:ساعة|ساعات|hour|hours|hr|hrs)',
    ).firstMatch(text);
    final minutes = RegExp(
      r'(\d+)\s*(?:دقيقة|دقائق|minute|minutes|min|mins)',
    ).firstMatch(text);

    int? parsed;
    if (hours != null) {
      parsed = ((double.tryParse(hours.group(1)!) ?? 1) * 60).round();
    } else if (text.contains('ساعتين')) {
      parsed = 120;
    } else if (text.contains('نصف ساعة')) {
      parsed = 30;
    } else if (text.contains('ساعة')) {
      parsed = 60;
    } else if (minutes != null) {
      parsed = int.tryParse(minutes.group(1)!);
    }
    return parsed == null ? null : parsed.clamp(10, 240).toInt();
  }

  /// Matches a prompt against searchable metadata, including content type.
  /// A prompt with no meaningful tokens does not filter the source list.
  static bool matchesPrompt(String prompt, String searchableText) {
    final words = searchableWords(prompt);
    if (words.isEmpty) return true;
    final normalized = normalizeDigits(searchableText).toLowerCase();
    return words.any(normalized.contains);
  }

  /// Splits on real whitespace (including newlines) and drops short tokens.
  static List<String> searchableWords(String input) => input
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .toList(growable: false);
}

/// Core, dependency-free domain model for AUREN News & Information.
///
/// This model stores source attribution and editorial state; it does not claim
/// that a story is verified merely because it has a source URL.
enum AurenNewsCategory {
  world,
  local,
  politics,
  business,
  science,
  health,
  climate,
  technology,
  sports,
  culture,
  humanitarian,
  events,
  other,
}

enum AurenNewsVerificationState {
  unreviewed,
  corroborated,
  disputed,
  corrected,
}

class AurenNewsArticle {
  final String id;
  final String title;
  final String summary;
  final String sourceName;
  final Uri sourceUri;
  final String languageCode;
  final DateTime publishedAt;
  final DateTime fetchedAt;
  final AurenNewsCategory category;
  final String? regionCode;
  final Uri? imageUri;
  final bool isBreaking;
  final AurenNewsVerificationState verificationState;

  AurenNewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.sourceName,
    required String sourceUrl,
    required this.languageCode,
    required this.publishedAt,
    required this.fetchedAt,
    required this.category,
    this.regionCode,
    String? imageUrl,
    this.isBreaking = false,
    this.verificationState = AurenNewsVerificationState.unreviewed,
  })  : sourceUri = _requireHttpsUri(sourceUrl, 'sourceUrl'),
        imageUri = imageUrl == null || imageUrl.trim().isEmpty
            ? null
            : _requireHttpsUri(imageUrl, 'imageUrl') {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Must not be empty.');
    }
    if (sourceName.trim().isEmpty) {
      throw ArgumentError.value(
        sourceName,
        'sourceName',
        'Must not be empty.',
      );
    }
    if (!RegExp(r'^[a-zA-Z]{2,3}([_-][a-zA-Z0-9]{2,8})*$')
        .hasMatch(languageCode.trim())) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Use a language tag such as en, ar, or pt-BR.',
      );
    }
  }

  /// Returns whether the story is within [maxAge] at [now].
  ///
  /// Future-dated stories are not considered fresh. This is a freshness hint,
  /// not a guarantee that the story is accurate or still current.
  bool isFreshAt(
    DateTime now, {
    Duration maxAge = const Duration(hours: 48),
  }) {
    final age = now.difference(publishedAt);
    return !age.isNegative && age <= maxAge;
  }

  static Uri _requireHttpsUri(String value, String fieldName) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Must be a valid HTTPS URL without embedded credentials.',
      );
    }
    return uri;
  }
}

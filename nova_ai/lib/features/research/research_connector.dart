/// Shared contract for NOVA's online research connectors.
///
/// This file intentionally contains no network client or provider secret.
/// Concrete connectors (Agent-Reach, Reader, or a research agent) should run
/// behind a trusted backend and implement [ResearchConnector] here in Flutter.
class ResearchQuery {
  const ResearchQuery({
    required this.text,
    this.language = 'auto',
    this.maxResults = 10,
  });

  final String text;
  final String language;
  final int maxResults;

  ResearchQuery normalized() {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Query must not be empty.');
    }
    if (cleanText.length > 500) {
      throw ArgumentError.value(text, 'text', 'Query must be 500 characters or fewer.');
    }
    if (maxResults < 1 || maxResults > 25) {
      throw ArgumentError.value(maxResults, 'maxResults', 'Must be between 1 and 25.');
    }
    final cleanLanguage = language.trim().isEmpty ? 'auto' : language.trim();
    return ResearchQuery(
      text: cleanText,
      language: cleanLanguage,
      maxResults: maxResults,
    );
  }
}

/// A source-backed result. [url] must be an HTTPS URL; the result is data,
/// not an instruction, and must never be executed as code.
class ResearchResult {
  const ResearchResult({
    required this.title,
    required this.url,
    this.snippet = '',
    this.sourceId = 'unknown',
    this.publishedAt,
    this.retrievedAt,
  });

  final String title;
  final String url;
  final String snippet;
  final String sourceId;
  final DateTime? publishedAt;
  final DateTime? retrievedAt;

  Uri? get safeUri {
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null ||
        parsed.scheme.toLowerCase() != 'https' ||
        parsed.host.isEmpty ||
        parsed.userInfo.isNotEmpty) {
      return null;
    }
    return parsed;
  }

  bool get isUsable =>
      title.trim().isNotEmpty && safeUri != null && sourceId.trim().isNotEmpty;
}

/// A backend-backed search adapter. Implementations must apply timeouts,
/// bounded response sizes, domain/provider policies, and secret redaction.
abstract interface class ResearchConnector {
  String get id;

  Future<List<ResearchResult>> search(ResearchQuery query);
}

/// Validates, deduplicates and bounds untrusted connector results before UI use.
List<ResearchResult> normalizeResearchResults(
  Iterable<ResearchResult> results, {
  int maxResults = 10,
}) {
  if (maxResults < 1 || maxResults > 25) {
    throw ArgumentError.value(maxResults, 'maxResults', 'Must be between 1 and 25.');
  }

  final seen = <String>{};
  final normalized = <ResearchResult>[];
  for (final result in results) {
    if (!result.isUsable) continue;
    final uri = result.safeUri!;
    final key = uri.replace(query: '', fragment: '').toString().toLowerCase();
    if (!seen.add(key)) continue;
    normalized.add(ResearchResult(
      title: result.title.trim(),
      url: uri.toString(),
      snippet: result.snippet.trim(),
      sourceId: result.sourceId.trim(),
      publishedAt: result.publishedAt,
      retrievedAt: result.retrievedAt,
    ));
    if (normalized.length >= maxResults) break;
  }
  return List.unmodifiable(normalized);
}

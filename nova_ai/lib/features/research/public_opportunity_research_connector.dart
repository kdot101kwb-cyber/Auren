import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'research_connector.dart';

/// Read-only adapters for public remote-job APIs. These endpoints require no
/// API key; never put authenticated provider credentials in the mobile app.
/// Each source is isolated by timeout, response-size checks, host allowlists,
/// and defensive JSON parsing. Listing data is untrusted and never executed.
class PublicOpportunityResearchConnector implements ResearchConnector {
  PublicOpportunityResearchConnector({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
    this.maxResponseBytes = 2 * 1024 * 1024,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  final int maxResponseBytes;

  @override
  String get id => 'public_remote_jobs';

  @override
  Future<List<ResearchResult>> search(ResearchQuery query) async {
    final normalized = query.normalized();
    final responses = await Future.wait([
      _getJson(Uri.https('remotive.com', '/api/remote-jobs', {
        'search': normalized.text,
        'limit': '${normalized.maxResults}',
      })),
      _getJson(Uri.https('www.arbeitnow.com', '/api/job-board-api')),
    ]);

    final results = <ResearchResult>[];
    final terms = normalized.text.toLowerCase().split(RegExp(r'\s+'))
        .where((term) => term.length > 2).toList();

    final remotive = responses[0];
    if (remotive is Map<String, dynamic>) {
      final jobs = remotive['jobs'];
      if (jobs is List) {
        for (final row in jobs.whereType<Map>()) {
          final item = Map<String, dynamic>.from(row);
          final title = _text(item['title']);
          final url = _httpsUrl(item['url'], 'remotive.com');
          if (title.isEmpty || url == null) continue;
          final description = _plainText(item['description']);
          results.add(ResearchResult(
            title: title,
            url: url,
            snippet: description.substring(
              0, description.length.clamp(0, 500).toInt(),
            ),
            sourceId: 'remotive',
            publishedAt: DateTime.tryParse(_text(item['publication_date'])),
            retrievedAt: DateTime.now().toUtc(),
          ));
        }
      }
    }

    final arbeitnow = responses[1];
    if (arbeitnow is Map<String, dynamic>) {
      final rows = arbeitnow['data'];
      if (rows is List) {
        for (final row in rows.whereType<Map>()) {
          final item = Map<String, dynamic>.from(row);
          final title = _text(item['title']);
          final description = _plainText(item['description']);
          final url = _httpsUrl(item['url'], 'www.arbeitnow.com');
          if (title.isEmpty || url == null) continue;
          final haystack = '$title $description ${_text(item['company_name'])} '
              '${_text(item['location'])} ${_text(item['tags'])}'.toLowerCase();
          if (terms.isNotEmpty && !terms.any(haystack.contains)) continue;
          results.add(ResearchResult(
            title: title,
            url: url,
            snippet: description.substring(
              0, description.length.clamp(0, 500).toInt(),
            ),
            sourceId: 'arbeitnow',
            publishedAt: DateTime.tryParse(_text(item['created_at'])),
            retrievedAt: DateTime.now().toUtc(),
          ));
        }
      }
    }

    if (remotive == null && arbeitnow == null) {
      throw const ResearchSourceUnavailableException();
    }
    return normalizeResearchResults(results, maxResults: normalized.maxResults);
  }

  Future<dynamic> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri, headers: const {
        'accept': 'application/json',
        'user-agent': 'NOVA-Personal-Research/1.0',
      }).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300 ||
          response.bodyBytes.length > maxResponseBytes) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } on http.ClientException {
      return null;
    }
  }

  static String? _httpsUrl(Object? value, String expectedHost) {
    final uri = Uri.tryParse(_text(value));
    if (uri == null || uri.scheme != 'https' ||
        uri.host.toLowerCase() != expectedHost || uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static String _plainText(Object? value) => _text(value)
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'&nbsp;|&#160;'), ' ')
      .replaceAll(RegExp(r'&amp;'), '&')
      .replaceAll(RegExp(r'&quot;'), '"')
      .replaceAll(RegExp(r'&#39;|&apos;'), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class ResearchSourceUnavailableException implements Exception {
  const ResearchSourceUnavailableException();

  @override
  String toString() => 'All public opportunity sources are unavailable.';
}

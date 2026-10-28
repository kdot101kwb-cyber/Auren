import 'dart:convert';

import 'package:http/http.dart' as http;

/// Read-only GitHub source inspection for public AUREN repository files.
/// This client never writes to GitHub and never accepts or stores credentials.
class NovaRepositoryInspector {
  NovaRepositoryInspector({http.Client? client}) : _client = client ?? http.Client();

  static const repository = 'kdot101kwb-cyber/Auren';
  static const defaultRef = 'feat/nova-engineering-orchestrator-v1';
  static const maxFileBytes = 300 * 1024;

  final http.Client _client;

  Future<NovaInspectedSource> inspect(String requestedPath, {String ref = defaultRef}) async {
    final path = _validatePath(requestedPath);
    final normalizedRef = ref.trim();
    if (normalizedRef.isEmpty || normalizedRef.length > 120 ||
        normalizedRef.contains('..') || normalizedRef.startsWith('/') ||
        normalizedRef.contains('?') || normalizedRef.contains('#')) {
      throw ArgumentError.value(ref, 'ref', 'Invalid branch or ref.');
    }

    final uri = Uri.https(
      'api.github.com',
      '/repos/$repository/contents/$path',
      {'ref': normalizedRef},
    );
    final response = await _client.get(uri, headers: const {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'NOVA-ReadOnly-Source-Inspector',
    }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
      throw const NovaRepositoryInspectionException('لم يُعثر على الملف في هذا الفرع، أو لا يمكن الوصول إليه علناً.');
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw const NovaRepositoryInspectionException('رفض GitHub الطلب أو تجاوز حد القراءة. لا يوجد رمز وصول داخل التطبيق.');
    }
    if (response.statusCode != 200) {
      throw NovaRepositoryInspectionException('تعذر جلب الملف من GitHub (HTTP ${response.statusCode}).');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const NovaRepositoryInspectionException('استجابة GitHub ليست JSON صالحاً.');
    }
    if (decoded is! Map<String, dynamic> || decoded['type'] != 'file' ||
        decoded['encoding'] != 'base64' || decoded['content'] is! String ||
        decoded['sha'] is! String) {
      throw const NovaRepositoryInspectionException('نوع الملف أو صيغة الاستجابة غير مدعومة.');
    }

    final bytes = base64.decode((decoded['content'] as String).replaceAll(RegExp(r'\\s'), ''));
    if (bytes.length > maxFileBytes) {
      throw const NovaRepositoryInspectionException('الملف أكبر من الحد المسموح للمعاينة (300 KiB).');
    }
    String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      throw const NovaRepositoryInspectionException('الملف ليس نصاً UTF-8 قابلاً للمعاينة.');
    }

    return NovaInspectedSource(
      path: path,
      ref: normalizedRef,
      sha: decoded['sha'] as String,
      content: content,
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  String _validatePath(String requestedPath) {
    final path = requestedPath.trim();
    if (path.isEmpty || path.startsWith('/') || path.contains('\\') ||
        path.contains('?') || path.contains('#') ||
        path.split('/').any((part) => part.isEmpty || part == '.' || part == '..')) {
      throw ArgumentError.value(requestedPath, 'path', 'Invalid repository path.');
    }
    if (!(path.startsWith('nova_ai/lib/') || path.startsWith('nova_ai/test/') ||
          path.startsWith('lib/') || path.startsWith('test/'))) {
      throw ArgumentError.value(requestedPath, 'path', 'Only AUREN/NOVA source and test files may be inspected.');
    }
    return path;
  }

  void close() => _client.close();
}

class NovaInspectedSource {
  const NovaInspectedSource({
    required this.path,
    required this.ref,
    required this.sha,
    required this.content,
    required this.fetchedAt,
  });

  final String path;
  final String ref;
  final String sha;
  final String content;
  final DateTime fetchedAt;
}

class NovaRepositoryInspectionException implements Exception {
  const NovaRepositoryInspectionException(this.message);
  final String message;

  @override
  String toString() => message;
}

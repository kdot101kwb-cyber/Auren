import 'package:cloud_functions/cloud_functions.dart';

/// Client adapter for AUREN's user-scoped Knowledge & Information callables.
/// Authentication is enforced again by the server; this class only validates
/// inputs early and keeps callable names in one place.
class KnowledgeInformationService {
  final FirebaseFunctions functions;

  KnowledgeInformationService({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instance;

  static String requiredText(String value, String field, int maxLength) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty || clean.length > maxLength) {
      throw ArgumentError('$field must contain 1-$maxLength characters.');
    }
    return clean;
  }

  static String validHttpUrl(String value) {
    final clean = requiredText(value, 'URL', 2000);
    final uri = Uri.tryParse(clean);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('URL must be a valid HTTP(S) address without credentials.');
    }
    return uri.toString();
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final result = await functions.httpsCallable(name).call<Map<dynamic, dynamic>>(payload);
    return result.data.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<List<Map<String, dynamic>>> _list(String callable) async {
    final result = await _call(callable, {'action': 'list'});
    final items = result['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map((item) =>
        item.map((key, value) => MapEntry(key.toString(), value))).toList();
  }

  Future<List<Map<String, dynamic>>> listKnowledge() => _list('captureAurenKnowledgeItem');
  Future<List<Map<String, dynamic>>> listEvidence() => _list('saveAurenEvidenceRecord');
  Future<List<Map<String, dynamic>>> listSourceProfiles() => _list('saveAurenSourceProfile');
  Future<List<Map<String, dynamic>>> listReadingQueue() => _list('upsertAurenReadingQueueItem');
  Future<List<Map<String, dynamic>>> listGlossary() => _list('saveAurenGlossaryEntry');

  Future<Map<String, dynamic>> captureKnowledge({
    required String title,
    String body = '',
    String sourceUrl = '',
    List<String> tags = const [],
  }) {
    final cleanTitle = requiredText(title, 'title', 180);
    final cleanBody = body.trim();
    if (cleanBody.length > 6000) throw ArgumentError('body exceeds 6000 characters.');
    if (cleanBody.isEmpty && sourceUrl.trim().isEmpty) {
      throw ArgumentError('Provide body text or a source URL.');
    }
    return _call('captureAurenKnowledgeItem', {
      'title': cleanTitle,
      'body': cleanBody,
      'sourceUrl': sourceUrl.trim().isEmpty ? '' : validHttpUrl(sourceUrl),
      'tags': tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).take(12).toList(),
    });
  }

  Future<Map<String, dynamic>> saveEvidence({
    required String claim,
    required List<String> sourceUrls,
    String verdict = 'unverified',
    String notes = '',
  }) {
    if (!{'unverified', 'supported', 'disputed', 'mixed'}.contains(verdict)) {
      throw ArgumentError('Unsupported evidence verdict.');
    }
    if (sourceUrls.isEmpty || sourceUrls.length > 12) {
      throw ArgumentError('Provide 1-12 source URLs.');
    }
    return _call('saveAurenEvidenceRecord', {
      'claim': requiredText(claim, 'claim', 1200),
      'sourceUrls': sourceUrls.map(validHttpUrl).toSet().toList(),
      'verdict': verdict,
      'notes': notes.trim().length > 3000 ? notes.trim().substring(0, 3000) : notes.trim(),
    });
  }

  Future<Map<String, dynamic>> saveSourceProfile({
    required String url,
    String label = '',
    String sourceType = 'other',
    String ownerOrPublisher = '',
    String notes = '',
  }) =>
      _call('saveAurenSourceProfile', {
        'url': validHttpUrl(url),
        'label': label.trim().isEmpty ? '' : requiredText(label, 'label', 180),
        'sourceType': sourceType,
        'ownerOrPublisher': ownerOrPublisher.trim(),
        'notes': notes.trim(),
      });

  Future<Map<String, dynamic>> saveReadingQueueItem({
    String id = '',
    required String title,
    required String url,
    String status = 'to_read',
    String priority = 'normal',
    String notes = '',
  }) {
    if (!{'to_read', 'reading', 'read'}.contains(status)) {
      throw ArgumentError('Unsupported reading status.');
    }
    if (!{'low', 'normal', 'high'}.contains(priority)) {
      throw ArgumentError('Unsupported reading priority.');
    }
    return _call('upsertAurenReadingQueueItem', {
      'id': id.trim(),
      'title': requiredText(title, 'title', 180),
      'url': validHttpUrl(url),
      'status': status,
      'priority': priority,
      'notes': notes.trim(),
    });
  }

  Future<Map<String, dynamic>> translateText({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    String context = '',
  }) {
    final cleanText = requiredText(text, 'text', 12000);
    final target = requiredText(targetLanguage, 'targetLanguage', 24);
    final source = requiredText(sourceLanguage, 'sourceLanguage', 24);
    if (source.toLowerCase() == target.toLowerCase() && source != 'auto') {
      throw ArgumentError('Source and target languages must differ.');
    }
    return _call('translateAurenText', {
      'text': cleanText,
      'sourceLanguage': source,
      'targetLanguage': target,
      'context': context.trim().length > 500
          ? context.trim().substring(0, 500)
          : context.trim(),
    });
  }

  Future<Map<String, dynamic>> removeReadingQueueItem({
    required String id,
  }) =>
      _call('upsertAurenReadingQueueItem', {
        'action': 'remove',
        'id': requiredText(id, 'id', 128),
      });

  Future<Map<String, dynamic>> saveGlossaryEntry({
    required String sourceTerm,
    required String translatedTerm,
    required String sourceLanguage,
    required String targetLanguage,
    String context = '',
    List<String> alternatives = const [],
  }) =>
      _call('saveAurenGlossaryEntry', {
        'sourceTerm': requiredText(sourceTerm, 'sourceTerm', 240),
        'translatedTerm': requiredText(translatedTerm, 'translatedTerm', 240),
        'sourceLanguage': requiredText(sourceLanguage, 'sourceLanguage', 24),
        'targetLanguage': requiredText(targetLanguage, 'targetLanguage', 24),
        'context': context.trim(),
        'alternatives': alternatives.map((v) => v.trim()).where((v) => v.isNotEmpty).take(8).toList(),
      });
}

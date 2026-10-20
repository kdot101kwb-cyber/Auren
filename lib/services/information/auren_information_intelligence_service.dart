import 'dart:convert';

class CitationRecord {
  const CitationRecord({required this.title, this.author = '', this.year = '', this.publisher = '', this.url = '', this.accessedDate = ''});
  final String title, author, year, publisher, url, accessedDate;
}

enum CitationStyle { apa7, mla9, chicago, bibtex, ris }

class CitationExportStudio {
  static String format(CitationRecord record, CitationStyle style) {
    final title = _required(record.title, 'title');
    final author = _clean(record.author);
    final year = _clean(record.year);
    final publisher = _clean(record.publisher);
    final url = _safeUrl(record.url);
    switch (style) {
      case CitationStyle.apa7:
        return [if (author.isNotEmpty) '$author.', if (year.isNotEmpty) '($year).', '$title.', if (publisher.isNotEmpty) '$publisher.', if (url.isNotEmpty) url].join(' ').trim();
      case CitationStyle.mla9:
        return [if (author.isNotEmpty) '$author.', '"$title."', if (publisher.isNotEmpty) '$publisher,', if (year.isNotEmpty) '$year,', if (url.isNotEmpty) '$url.'].join(' ').trim();
      case CitationStyle.chicago:
        return [if (author.isNotEmpty) '$author.', '$title.', if (publisher.isNotEmpty) '$publisher,', if (year.isNotEmpty) '$year.', if (url.isNotEmpty) url].join(' ').trim();
      case CitationStyle.bibtex:
        final key = _citationKey(author, year, title);
        final lines = <String>['@misc{' + key + ',', '  title = {' + _bibEscape(title) + '},'];
        if (author.isNotEmpty) lines.add('  author = {' + _bibEscape(author) + '},');
        if (year.isNotEmpty) lines.add('  year = {' + _bibEscape(year) + '},');
        if (publisher.isNotEmpty) lines.add('  howpublished = {' + _bibEscape(publisher) + '},');
        if (url.isNotEmpty) lines.add('  url = {' + _bibEscape(url) + '},');
        lines.add('}');
        return lines.join('\n');
      case CitationStyle.ris:
        return ['TY  - GEN', if (author.isNotEmpty) 'AU  - $author', 'TI  - $title', if (publisher.isNotEmpty) 'PB  - $publisher', if (year.isNotEmpty) 'PY  - $year', if (url.isNotEmpty) 'UR  - $url', if (_clean(record.accessedDate).isNotEmpty) 'Y2  - ' + _clean(record.accessedDate), 'ER  -'].join('\n');
    }
  }

  static String _citationKey(String author, String year, String title) {
    final seed = author.isNotEmpty ? author.split(RegExp(r'\s+')).last : title;
    final normalized = seed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return (normalized.isEmpty ? 'source' : normalized) + year.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _bibEscape(String value) => value.replaceAll(r'\', r'\textbackslash{}').replaceAll('{', r'\{').replaceAll('}', r'\}');

  static String _safeUrl(String value) {
    final clean = _clean(value);
    if (clean.isEmpty) return '';
    final uri = Uri.tryParse(clean);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) || uri.userInfo.isNotEmpty) {
      throw ArgumentError('URL must be HTTP(S), have a host, and contain no credentials.');
    }
    return uri.toString();
  }
}

class InformationItem {
  const InformationItem({required this.id, required this.title, this.summary = '', this.sourceUrl = ''});
  final String id, title, summary, sourceUrl;
}

class TopicWatchMatch {
  const TopicWatchMatch({required this.item, required this.matchedTopics});
  final InformationItem item;
  final List<String> matchedTopics;
}

class TopicWatchlistEngine {
  static List<TopicWatchMatch> match({required List<String> topics, required List<InformationItem> items}) {
    final normalizedTopics = <String>[];
    final seenTopics = <String>{};
    for (final rawTopic in topics) {
      final topic = _clean(rawTopic);
      if (topic.isNotEmpty && seenTopics.add(topic.toLowerCase())) {
        normalizedTopics.add(topic);
      }
    }
    final matches = <TopicWatchMatch>[];
    for (final item in items) {
      final searchable = (item.title + ' ' + item.summary).toLowerCase();
      final hits = normalizedTopics.where((topic) => searchable.contains(topic.toLowerCase())).toList();
      if (hits.isNotEmpty) matches.add(TopicWatchMatch(item: item, matchedTopics: hits));
    }
    return matches;
  }
}

enum SourceFreshnessStatus { unknown, fresh, reviewSoon, stale }

class SourceFreshnessAssessment {
  const SourceFreshnessAssessment({required this.status, required this.daysSinceCheck, required this.nextCheckAt});
  final SourceFreshnessStatus status;
  final int? daysSinceCheck;
  final DateTime? nextCheckAt;
}

class SourceFreshnessRadar {
  static SourceFreshnessAssessment assess({required DateTime? lastCheckedAt, required DateTime now, int freshForDays = 7, int staleAfterDays = 30}) {
    if (freshForDays < 0 || staleAfterDays < freshForDays) throw ArgumentError('Freshness thresholds are invalid.');
    if (lastCheckedAt == null) {
      return const SourceFreshnessAssessment(status: SourceFreshnessStatus.unknown, daysSinceCheck: null, nextCheckAt: null);
    }
    final days = now.difference(lastCheckedAt).inDays.clamp(0, 365000).toInt();
    final status = days <= freshForDays ? SourceFreshnessStatus.fresh : days <= staleAfterDays ? SourceFreshnessStatus.reviewSoon : SourceFreshnessStatus.stale;
    return SourceFreshnessAssessment(status: status, daysSinceCheck: days, nextCheckAt: lastCheckedAt.add(Duration(days: freshForDays + 1)));
  }
}

class KnowledgePackItem {
  const KnowledgePackItem({required this.id, required this.title, this.body = '', this.sourceUrl = ''});
  final String id, title, body, sourceUrl;
  Map<String, Object> toJson() => {'id': id, 'title': title, 'body': body, 'sourceUrl': sourceUrl};
}

class KnowledgePackManifest {
  const KnowledgePackManifest({required this.items, required this.estimatedBytes, required this.createdAt});
  final List<KnowledgePackItem> items;
  final int estimatedBytes;
  final DateTime createdAt;
  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'itemCount': items.length,
    'estimatedBytes': estimatedBytes,
    'items': items.map((item) => item.toJson()).toList(),
  };
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class OfflineKnowledgePackPlanner {
  static KnowledgePackManifest build({required List<KnowledgePackItem> items, required DateTime now, int maxItems = 100, int maxEstimatedBytes = 5 * 1024 * 1024}) {
    if (items.isEmpty) throw ArgumentError('Select at least one item.');
    if (items.length > maxItems) throw ArgumentError('Pack exceeds the $maxItems item limit.');
    final ids = <String>{};
    var estimatedBytes = 0;
    for (final item in items) {
      final id = _required(item.id, 'id');
      _required(item.title, 'title');
      if (!ids.add(id)) throw ArgumentError('Duplicate item id: $id');
      final url = _clean(item.sourceUrl);
      if (url.isNotEmpty) CitationExportStudio._safeUrl(url);
      estimatedBytes += utf8.encode(item.title + '\n' + item.body + '\n' + url).length;
    }
    if (estimatedBytes > maxEstimatedBytes) throw ArgumentError('Pack exceeds the estimated byte limit.');
    return KnowledgePackManifest(items: List.unmodifiable(items), estimatedBytes: estimatedBytes, createdAt: now);
  }
}

class RevisionDiff {
  const RevisionDiff({required this.addedLines, required this.removedLines});
  final List<String> addedLines, removedLines;
  bool get hasChanges => addedLines.isNotEmpty || removedLines.isNotEmpty;
}

class KnowledgeRevisionLedger {
  static RevisionDiff compare(String previous, String current) {
    final oldLines = _lines(previous), newLines = _lines(current);
    final oldSet = oldLines.toSet(), newSet = newLines.toSet();
    return RevisionDiff(
      addedLines: List.unmodifiable(newLines.where((line) => !oldSet.contains(line))),
      removedLines: List.unmodifiable(oldLines.where((line) => !newSet.contains(line))),
    );
  }
  static List<String> _lines(String value) => value.replaceAll('\r\n', '\n').split('\n').map((line) => line.trimRight()).where((line) => line.trim().isNotEmpty).toList();
}

String _clean(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');
String _required(String value, String label) {
  final result = _clean(value);
  if (result.isEmpty) throw ArgumentError('$label is required.');
  return result;
}

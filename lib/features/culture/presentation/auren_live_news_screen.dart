import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// A lightweight live-news reader backed by the public GDELT DOC API.
/// No API key or paid service is required. Results are external reporting,
/// not independently verified facts.
class AurenLiveNewsScreen extends StatefulWidget {
  const AurenLiveNewsScreen({super.key, this.client});

  /// Injectable client keeps the network boundary testable.
  final http.Client? client;

  @override
  State<AurenLiveNewsScreen> createState() => _AurenLiveNewsScreenState();
}

class _AurenLiveNewsScreenState extends State<AurenLiveNewsScreen> {
  static const _topics = <_NewsTopic>[
    _NewsTopic('World', 'world OR international', Icons.public_outlined),
    _NewsTopic('Sudan & Africa', 'Sudan OR Africa', Icons.public),
    _NewsTopic('Science & Tech', 'technology OR science', Icons.memory_outlined),
  ];

  late final http.Client _client = widget.client ?? http.Client();
  bool _ownsClient = false;
  int _selectedTopic = 0;
  bool _loading = false;
  String? _error;
  List<_NewsArticle> _articles = const [];

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.client == null;
    _loadArticles();
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final topic = _topics[_selectedTopic];
    final uri = Uri.https(
      'api.gdeltproject.org',
      '/api/v2/doc/doc',
      {
        'query': topic.query,
        'mode': 'ArtList',
        'format': 'json',
        'maxrecords': '25',
        'sort': 'DateDesc',
      },
    );

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode != 200) {
        throw Exception('News service returned HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected news response.');
      }
      final rawArticles = decoded['articles'];
      final articles = rawArticles is List
          ? rawArticles
              .whereType<Map<String, dynamic>>()
              .map(_NewsArticle.fromJson)
              .where((article) => article.title.isNotEmpty && article.url.isNotEmpty)
              .toList(growable: false)
          : const <_NewsArticle>[];

      if (!mounted) return;
      setState(() {
        _articles = articles;
        _loading = false;
        _error = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'انتهت مهلة الاتصال. جرّب مرة أخرى عند توفر الإنترنت.';
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'وصلتنا استجابة أخبار غير مفهومة. حاول التحديث.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل الأخبار الآن. تحقق من الاتصال ثم أعد المحاولة.';
      });
    }
  }

  Future<void> _openArticle(_NewsArticle article) async {
    final uri = Uri.tryParse(article.url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط الخبر غير صالح.')),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح رابط الخبر.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Live News'),
        actions: [
          IconButton(
            tooltip: 'Refresh news',
            onPressed: _loading ? null : _loadArticles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'الأخبار من مصادر العالم',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'عناوين وروابط حديثة من خدمة GDELT العامة. افتح المصدر لقراءة التفاصيل؛ '
            'وجود الخبر هنا لا يعني أن AUREN تحقّق من صحته.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < _topics.length; index++)
                ChoiceChip(
                  label: Text(_topics[index].label),
                  selected: _selectedTopic == index,
                  onSelected: _loading
                      ? null
                      : (selected) {
                          if (!selected || _selectedTopic == index) return;
                          setState(() => _selectedTopic = index);
                          _loadArticles();
                        },
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_outlined, size: 32),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadArticles,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          else if (_articles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'لا توجد نتائج لهذا القسم حالياً. جرّب قسماً آخر أو حدّث القائمة.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            Text(
              '${_articles.length} articles · GDELT',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            for (final article in _articles)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text(
                    article.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      [
                        if (article.domain.isNotEmpty) article.domain,
                        if (article.dateLabel.isNotEmpty) article.dateLabel,
                      ].join(' · '),
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openArticle(article),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NewsTopic {
  const _NewsTopic(this.label, this.query, this.icon);

  final String label;
  final String query;
  final IconData icon;
}

class _NewsArticle {
  const _NewsArticle({
    required this.title,
    required this.url,
    required this.domain,
    required this.dateLabel,
  });

  final String title;
  final String url;
  final String domain;
  final String dateLabel;

  factory _NewsArticle.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['seendate'] ?? '').toString();
    return _NewsArticle(
      title: (json['title'] ?? '').toString().trim(),
      url: (json['url'] ?? '').toString().trim(),
      domain: (json['domain'] ?? '').toString().trim(),
      dateLabel: rawDate.length > 14
          ? '${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)}'
          : rawDate,
    );
  }
}

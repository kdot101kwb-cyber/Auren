import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Read-only browser for the public AUREN repository. It never embeds a token
/// and never writes files or starts workflows.
class AurenRepositoryBrowserScreen extends StatefulWidget {
  const AurenRepositoryBrowserScreen({super.key});

  @override
  State<AurenRepositoryBrowserScreen> createState() =>
      _AurenRepositoryBrowserScreenState();
}

class _AurenRepositoryBrowserScreenState
    extends State<AurenRepositoryBrowserScreen> {
  static const repository = 'kdot101kwb-cyber/Auren';
  static const branch = 'feat/nova-free-game-development-toolkit';
  static const _treeUrl =
      'https://api.github.com/repos/' + repository + '/git/trees/' + branch + '?recursive=1';

  final _search = TextEditingController();
  bool _loading = false;
  String? _error;
  List<_RepoEntry> _entries = const [];
  _RepoEntry? _selected;
  String? _source;
  bool _sourceLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadTree() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse(_treeUrl),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('GitHub رجع رمز HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['tree'] is! List) {
        throw const FormatException('صيغة شجرة المستودع غير متوقعة.');
      }
      final entries = (decoded['tree'] as List)
          .whereType<Map<String, dynamic>>()
          .where((item) => item['type'] == 'blob' && item['path'] is String)
          .map((item) => _RepoEntry(
                path: item['path'] as String,
                size: item['size'] is int ? item['size'] as int : 0,
              ))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            'تعذر تحميل ملفات AUREN. تحقق من الإنترنت وحالة GitHub ثم أعد المحاولة. ($error)');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFile(_RepoEntry entry) async {
    if (_sourceLoading) return;
    setState(() {
      _selected = entry;
      _source = null;
      _sourceLoading = true;
      _error = null;
    });
    try {
      // GitHub contents API returns base64 for ordinary repository files.
      final uri = Uri.https(
        'api.github.com',
        '/repos/$repository/contents/${entry.path.split('/').map(Uri.encodeComponent).join('/')}',
        {'ref': branch},
      );
      final response = await http.get(uri, headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      }).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('GitHub رجع رمز HTTP ${response.statusCode}.');
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['content'] is! String) {
        throw const FormatException('لم يرجع GitHub محتوى نصياً لهذا الملف.');
      }
      if (entry.size > 250000) {
        throw const FormatException('الملف أكبر من حد العرض الآمن (250 KB). افتحه على GitHub.');
      }
      final encoded = (data['content'] as String).replaceAll(RegExp(r'\\s'), '');
      final bytes = base64.decode(base64.normalize(encoded));
      final source = utf8.decode(bytes);
      if (!mounted) return;
      setState(() => _source = source);
    } catch (error) {
      if (mounted) {
        setState(() => _source =
            'تعذر عرض الملف داخل NOVA. يمكنك فتحه على GitHub.\n\n$error');
      }
    } finally {
      if (mounted) setState(() => _sourceLoading = false);
    }
  }

  Future<void> _openOnGitHub(_RepoEntry entry) async {
    final uri = Uri.https(
      'github.com',
      '/$repository/blob/$branch/${entry.path.split('/').map(Uri.encodeComponent).join('/')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = _entries.where((entry) => entry.path.toLowerCase().contains(query)).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NOVA Builder · ملفات AUREN'),
          actions: [
            IconButton(
              tooltip: 'تحديث قائمة الملفات',
              onPressed: _loading ? null : _loadTree,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              child: const Text(
                'اتصال مباشر للقراءة فقط بالمستودع العام. يقرأ NOVA أسماء الملفات ويعرض الملفات النصية دون رمز وصول أو صلاحية كتابة.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  labelText: 'ابحث عن ملف أو مسار',
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(_error!, textDirection: TextDirection.rtl),
              ),
            if (_loading)
              const LinearProgressIndicator(),
            Expanded(
              child: _selected == null
                  ? ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(entry.path, textDirection: TextDirection.ltr),
                          subtitle: Text(entry.size > 0 ? '${entry.size} bytes' : 'حجم غير متاح'),
                          onTap: () => _openFile(entry),
                        );
                      },
                    )
                  : Column(
                      children: [
                        ListTile(
                          leading: IconButton(
                            tooltip: 'العودة إلى الملفات',
                            onPressed: () => setState(() {
                              _selected = null;
                              _source = null;
                            }),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          title: Text(_selected!.path, textDirection: TextDirection.ltr),
                          trailing: IconButton(
                            tooltip: 'فتح على GitHub',
                            onPressed: () => _openOnGitHub(_selected!),
                            icon: const Icon(Icons.open_in_new),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _sourceLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: SelectableText(
                                    _source ?? 'لا يوجد محتوى لعرضه.',
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'حدود النسخة الحالية: القراءة فقط وعلى فرع ثابت. لا تعدّل الملفات ولا تشغّل الأوامر أو CI. ربط المستودعات الخاصة أو الكتابة يتطلب خادماً آمناً وصلاحيات محدودة وموافقة المستخدم.',
                style: TextStyle(fontSize: 11),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepoEntry {
  const _RepoEntry({required this.path, required this.size});
  final String path;
  final int size;
}

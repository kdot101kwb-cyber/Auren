import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Local source register. A status records the user's review state, not an
/// independent claim that a source is authentic or factually correct.
class AurenSourceRegistryScreen extends StatefulWidget {
  const AurenSourceRegistryScreen({super.key});

  @override
  State<AurenSourceRegistryScreen> createState() =>
      _AurenSourceRegistryScreenState();
}

class _AurenSourceRegistryScreenState extends State<AurenSourceRegistryScreen> {
  static const _storageKey = 'auren_source_registry_v1';
  final List<_RegisteredSource> _sources = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final sources = decoded
          .whereType<Map<String, dynamic>>()
          .map(_RegisteredSource.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _sources
          ..clear()
          ..addAll(sources);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّرت قراءة سجل المصادر المحفوظ على الجهاز.';
      });
    }
  }

  Future<void> _save() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey,
        jsonEncode(_sources.map((source) => source.toJson()).toList()),
      );
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر حفظ التغيير؛ احتفظ بنسخة من بيانات المصدر.');
      }
    }
  }

  Future<void> _addSource() async {
    final result = await showDialog<_RegisteredSource>(
      context: context,
      builder: (_) => const _AddSourceDialog(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _sources.insert(0, result);
      _error = null;
    });
    await _save();
  }

  Future<void> _openSource(_RegisteredSource source) async {
    final uri = Uri.tryParse(source.url);
    if (uri == null ||
        !(uri.scheme == 'https' || uri.scheme == 'http') ||
        uri.host.isEmpty) {
      _showMessage('الرابط غير صالح. راجعه قبل فتحه.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _showMessage('تعذّر فتح الرابط على هذا الجهاز.');
    } catch (_) {
      if (mounted) _showMessage('تعذّر فتح الرابط على هذا الجهاز.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setStatus(
    _RegisteredSource source,
    _SourceStatus status,
  ) async {
    setState(() {
      final index = _sources.indexWhere((item) => item.id == source.id);
      if (index != -1) _sources[index] = source.copyWith(status: status);
    });
    await _save();
  }

  Future<void> _delete(_RegisteredSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المصدر؟'),
        content: Text('سيتم حذف «${source.title}» من السجل المحلي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sources.removeWhere((item) => item.id == source.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Source Registry')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSource,
        icon: const Icon(Icons.add_link),
        label: const Text('إضافة مصدر'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  'مصادرك، وحالة مراجعتها',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سجل محلي للروابط التي تريد مراجعتها. حالة المصدر تعبّر عن اختيارك أنت، '
                  'وليست تحققاً آلياً من صحة المعلومات أو موثوقية الناشر.',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                if (_sources.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.source_outlined, size: 36),
                          SizedBox(height: 8),
                          Text('لا توجد مصادر محفوظة'),
                          SizedBox(height: 4),
                          Text('أضف رابط تقرير أو دراسة أو صفحة تريد الرجوع إليها.'),
                        ],
                      ),
                    ),
                  )
                else
                  ..._sources.map(
                    (source) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  child: Icon(Icons.link_outlined),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        source.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        source.url,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<_SourceStatus>(
                                  tooltip: 'تغيير حالة المراجعة',
                                  initialValue: source.status,
                                  onSelected: (status) => _setStatus(source, status),
                                  itemBuilder: (_) => _SourceStatus.values
                                      .map(
                                        (status) => PopupMenuItem(
                                          value: status,
                                          child: Text(status.label),
                                        ),
                                      )
                                      .toList(),
                                  icon: const Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(
                                  avatar: Icon(source.status.icon, size: 18),
                                  label: Text(source.status.label),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _openSource(source),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('فتح الرابط'),
                                ),
                                IconButton(
                                  tooltip: 'حذف المصدر',
                                  onPressed: () => _delete(source),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

enum _SourceStatus {
  needsReview('بحاجة للمراجعة', Icons.pending_outlined),
  reviewed('راجعه المستخدم', Icons.fact_check_outlined),
  notUseful('غير مناسب للبحث', Icons.remove_circle_outline);

  const _SourceStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _RegisteredSource {
  const _RegisteredSource({
    required this.id,
    required this.title,
    required this.url,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String url;
  final _SourceStatus status;
  final String createdAt;

  _RegisteredSource copyWith({_SourceStatus? status}) => _RegisteredSource(
        id: id,
        title: title,
        url: url,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'status': status.name,
        'createdAt': createdAt,
      };

  factory _RegisteredSource.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    return _RegisteredSource(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'مصدر بدون عنوان',
      url: json['url'] as String? ?? '',
      status: _SourceStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => _SourceStatus.needsReview,
      ),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}


class _AddSourceDialog extends StatefulWidget {
  const _AddSourceDialog();

  @override
  State<_AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends State<_AddSourceDialog> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final rawUrl = _urlController.text.trim();
    final uri = Uri.tryParse(rawUrl);
    final validUrl = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    if (title.isEmpty || !validUrl) {
      setState(() {
        _validationError = title.isEmpty
            ? 'أدخل اسم المصدر أولاً.'
            : 'أدخل رابطاً صحيحاً يبدأ بـ http:// أو https://.';
      });
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    Navigator.pop(
      context,
      _RegisteredSource(
        id: now,
        title: title,
        url: uri.toString(),
        status: _SourceStatus.needsReview,
        createdAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مصدر'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'اسم المصدر أو عنوان الصفحة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              maxLength: 2048,
              decoration: const InputDecoration(
                labelText: 'رابط المصدر',
                hintText: 'https://example.com/report',
                border: OutlineInputBorder(),
              ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'يُحفظ الرابط كما أدخلته. إضافته هنا لا تعني أنه موثوق أو تم التحقق منه.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ المصدر'),
        ),
      ],
    );
  }
}

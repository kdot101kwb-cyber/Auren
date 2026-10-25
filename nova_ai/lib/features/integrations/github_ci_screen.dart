import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Read-only live view of public GitHub Actions runs for the AUREN repository.
/// No token is embedded in the mobile app; private repositories need a secure backend.
class GitHubCiScreen extends StatefulWidget {
  const GitHubCiScreen({super.key});

  @override
  State<GitHubCiScreen> createState() => _GitHubCiScreenState();
}

class _GitHubCiScreenState extends State<GitHubCiScreen> {
  static final Uri _runsUri = Uri.https(
    'api.github.com',
    '/repos/kdot101kwb-cyber/Auren/actions/runs',
    const {'per_page': '15'},
  );

  bool _loading = false;
  String? _error;
  List<_WorkflowRun> _runs = const [];
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        _runsUri,
        headers: const {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('GitHub رجع رمز ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['workflow_runs'] is! List) {
        throw const FormatException('استجابة GitHub غير متوقعة');
      }
      final runs = (decoded['workflow_runs'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_WorkflowRun.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _runs = runs;
        _lastUpdated = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is FormatException
            ? 'تعذر قراءة بيانات GitHub.'
            : 'تعذر الاتصال بـ GitHub. تحقق من الإنترنت ثم أعد المحاولة.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRun(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تشغيل GitHub Actions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF263D32), Color(0xFF202039)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_done_outlined, size: 30, color: Color(0xFF79D7A4)),
                  SizedBox(height: 8),
                  Text('اتصال GitHub المباشر', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('قراءة مباشرة لتشغيلات GitHub Actions العامة في مستودع AUREN. الاتصال للقراءة فقط ولا يحتاج رمز وصول للمستودع العام.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _lastUpdated == null
                        ? 'حالة التحديث: ${_loading ? 'جارٍ الاتصال…' : 'لم يتم التحديث بعد'}'
                        : 'آخر تحديث: ${_lastUpdated!.toLocal().toString().substring(0, 16)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'تحديث من GitHub',
                  onPressed: _loading ? null : _refresh,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('لم يكتمل الاتصال', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_error!),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading && _runs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _error == null && _runs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('لم يعرض GitHub أي تشغيلات في الاستجابة الحالية. اسحب للتحديث.'),
              ),
            for (final run in _runs)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openRun(run.htmlUrl),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_iconFor(run.status, run.conclusion), color: _colorFor(context, run.status, run.conclusion)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(run.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                            const Icon(Icons.open_in_new, size: 17),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Workflow: ${run.workflow} · تشغيل #${run.runNumber}'),
                        const SizedBox(height: 4),
                        Text('الحالة: ${_statusLabel(run.status, run.conclusion)}'),
                        const SizedBox(height: 4),
                        Text('الفرع: ${run.branch}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          'Commit: ${run.sha.length > 7 ? run.sha.substring(0, 7) : run.sha} · ${run.createdAt.isEmpty ? 'وقت غير متاح' : run.createdAt.replaceFirst('T', ' ').replaceFirst('Z', ' UTC')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'الحدود الحالية: اتصال عام للقراءة فقط. لم يتم ربط GitHub الخاص أو تشغيل أوامر أو تعديل الكود من داخل التطبيق. أي صلاحية كتابة لاحقاً يجب أن تمر عبر خادم آمن وبأقل صلاحيات ممكنة.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String status, String conclusion) {
    if (status != 'completed') return Icons.pending_outlined;
    if (conclusion == 'success') return Icons.check_circle_outline;
    if (conclusion == 'failure' || conclusion == 'cancelled' || conclusion == 'timed_out') return Icons.error_outline;
    return Icons.info_outline;
  }

  static Color _colorFor(BuildContext context, String status, String conclusion) {
    if (status != 'completed') return Colors.amber;
    if (conclusion == 'success') return Colors.green;
    if (conclusion == 'failure' || conclusion == 'cancelled' || conclusion == 'timed_out') {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static String _statusLabel(String status, String conclusion) {
    if (status != 'completed') {
      switch (status) {
        case 'queued': return 'في الانتظار';
        case 'in_progress': return 'قيد التنفيذ';
        default: return 'غير مكتمل: $status';
      }
    }
    switch (conclusion) {
      case 'success': return 'نجاح';
      case 'failure': return 'فشل';
      case 'cancelled': return 'أُلغي';
      case 'timed_out': return 'انتهت المهلة';
      case 'skipped': return 'تم التخطي';
      default: return conclusion.isEmpty ? 'اكتمل دون نتيجة معروفة' : conclusion;
    }
  }
}

class _WorkflowRun {
  const _WorkflowRun({
    required this.title,
    required this.workflow,
    required this.status,
    required this.conclusion,
    required this.branch,
    required this.sha,
    required this.htmlUrl,
    required this.createdAt,
    required this.runNumber,
  });

  final String title;
  final String workflow;
  final String status;
  final String conclusion;
  final String branch;
  final String sha;
  final String htmlUrl;
  final String createdAt;
  final int runNumber;

  factory _WorkflowRun.fromJson(Map<String, dynamic> json) => _WorkflowRun(
        title: json['display_title'] as String? ?? 'تشغيل GitHub Actions',
        workflow: json['name'] as String? ?? 'Workflow',
        status: json['status'] as String? ?? 'unknown',
        conclusion: json['conclusion'] as String? ?? '',
        branch: json['head_branch'] as String? ?? 'unknown',
        sha: json['head_sha'] as String? ?? '',
        htmlUrl: json['html_url'] as String? ?? 'https://github.com/kdot101kwb-cyber/Auren/actions',
        createdAt: json['created_at'] as String? ?? '',
        runNumber: json['run_number'] is int ? json['run_number'] as int : 0,
      );
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// NOVA's unified DevOps overview.
///
/// GitHub Actions is read live for the public AUREN repository. CircleCI and
/// GitLab are explicitly marked as not connected until a trusted backend
/// integration is configured. Provider tokens must never be stored in Flutter.
class NovaDevOpsCenterScreen extends StatefulWidget {
  const NovaDevOpsCenterScreen({super.key});

  @override
  State<NovaDevOpsCenterScreen> createState() => _NovaDevOpsCenterScreenState();
}

class _NovaDevOpsCenterScreenState extends State<NovaDevOpsCenterScreen> {
  static final Uri _runsUri = Uri.https(
    'api.github.com',
    '/repos/kdot101kwb-cyber/Auren/actions/runs',
    const {'per_page': '8'},
  );

  bool _loading = false;
  String? _error;
  List<_DevOpsRun> _runs = const [];
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _refreshGitHubActions();
  }

  Future<void> _refreshGitHubActions() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(_runsUri, headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('GitHub API returned ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['workflow_runs'] is! List) {
        throw const FormatException('Unexpected GitHub Actions response');
      }
      final runs = (decoded['workflow_runs'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_DevOpsRun.fromJson)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _runs = runs;
        _updatedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر جلب الحالة الحية من GitHub. قد يكون الاتصال غير متاح أو حدّ الطلبات قد انتهى.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة الخدمة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: RefreshIndicator(
      onRefresh: _refreshGitHubActions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF392A70), Color(0xFF202039)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hub_outlined, color: Color(0xFFC4B5FD), size: 34),
                SizedBox(height: 10),
                Text('NOVA DevOps Center',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('لوحة واحدة لمتابعة المستودعات والبناء والاختبارات. تُعرض حالة كل موصل بوضوح، ولا تعتبر الخدمة متصلة إلا بعد اختبار حي.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProviderCard(
            icon: Icons.code,
            name: 'GitHub',
            status: 'قراءة عامة',
            detail: 'يعرض المستودع العام ونتائج GitHub Actions المتاحة للعامة. لا توجد صلاحية كتابة أو إصلاح تلقائي من هذه الشاشة.',
            color: Colors.green,
            onOpen: () => _open('https://github.com/kdot101kwb-cyber/Auren'),
          ),
          _ProviderCard(
            icon: Icons.sync_alt,
            name: 'CircleCI',
            status: 'غير مربوط',
            detail: 'يتطلب ربط API آمن عبر خادم وسيط. لا تضع CircleCI token داخل تطبيق Android.',
            color: Colors.orange,
            onOpen: () => _open('https://circleci.com/docs/api/v2/'),
          ),
          _ProviderCard(
            icon: Icons.merge_type,
            name: 'GitLab CI/CD',
            status: 'غير مربوط',
            detail: 'يتطلب OAuth أو token محدود الصلاحيات محفوظاً على الخادم، ثم اختبار قراءة المشاريع والـ pipelines.',
            color: Colors.orange,
            onOpen: () => _open('https://docs.gitlab.com/api/pipelines/'),
          ),
          _ProviderCard(
            icon: Icons.verified_outlined,
            name: 'الموافقة والتنفيذ',
            status: 'بوابة أمان مطلوبة',
            detail: 'التعديل على الملفات، تشغيل مهام البناء، وإعادة المحاولة يجب أن تُعرض كإجراءات منفصلة مع معاينة وموافقة صريحة وسجل تدقيق. لم تُفعّل هذه الإجراءات بعد.',
            color: Colors.deepPurpleAccent,
            onOpen: () => _open('https://docs.github.com/en/rest/actions/workflows'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text('تشغيلات GitHub Actions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: 'تحديث النتائج',
                onPressed: _loading ? null : _refreshGitHubActions,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          if (_updatedAt != null)
            Text('آخر تحديث: ${_updatedAt!.toLocal().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodySmall),
          if (_error != null)
            Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, textDirection: TextDirection.rtl),
            )),
          if (_loading && _runs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && _error == null && _runs.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('لا توجد تشغيلات ظاهرة في استجابة GitHub الحالية.'),
            )),
          for (final run in _runs)
            Card(
              child: ListTile(
                leading: Icon(_statusIcon(run.status, run.conclusion),
                  color: _statusColor(context, run.status, run.conclusion)),
                title: Text(run.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${run.workflow} · ${run.branch}\n${_statusLabel(run.status, run.conclusion)} · ${run.sha.isEmpty ? 'commit غير متاح' : run.sha.substring(0, run.sha.length > 7 ? 7 : run.sha.length)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(run.url),
              ),
            ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'حدود التنفيذ الحالية: GitHub Actions قراءة عامة فقط. CircleCI وGitLab غير مربوطين. لا توجد هنا صلاحية لإصلاح الملفات أو تشغيل CI أو دمج PR. الخطوة الآمنة التالية هي إعداد backend موثوق وحفظ الأسرار فيه، ثم إضافة موافقة المستخدم لكل عملية كتابة أو تشغيل.',
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  static IconData _statusIcon(String status, String conclusion) {
    if (status != 'completed') return Icons.pending_outlined;
    if (conclusion == 'success') return Icons.check_circle_outline;
    if (conclusion == 'failure' || conclusion == 'cancelled' || conclusion == 'timed_out') {
      return Icons.error_outline;
    }
    return Icons.info_outline;
  }

  static Color _statusColor(BuildContext context, String status, String conclusion) {
    if (status != 'completed') return Colors.amber;
    if (conclusion == 'success') return Colors.green;
    if (conclusion == 'failure' || conclusion == 'cancelled' || conclusion == 'timed_out') {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static String _statusLabel(String status, String conclusion) {
    if (status != 'completed') {
      if (status == 'queued') return 'في الانتظار';
      if (status == 'in_progress') return 'قيد التنفيذ';
      return 'غير مكتمل: $status';
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

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.name,
    required this.status,
    required this.detail,
    required this.color,
    required this.onOpen,
  });

  final IconData icon;
  final String name;
  final String status;
  final String detail;
  final Color color;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            Chip(label: Text(status)),
          ]),
          const SizedBox(height: 8),
          Text(detail, textDirection: TextDirection.rtl),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 17),
              label: const Text('فتح توثيق الخدمة'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DevOpsRun {
  const _DevOpsRun({
    required this.title,
    required this.workflow,
    required this.status,
    required this.conclusion,
    required this.branch,
    required this.sha,
    required this.url,
  });

  final String title;
  final String workflow;
  final String status;
  final String conclusion;
  final String branch;
  final String sha;
  final String url;

  factory _DevOpsRun.fromJson(Map<String, dynamic> json) => _DevOpsRun(
    title: json['display_title'] as String? ?? 'GitHub Actions run',
    workflow: json['name'] as String? ?? 'Workflow',
    status: json['status'] as String? ?? 'unknown',
    conclusion: json['conclusion'] as String? ?? '',
    branch: json['head_branch'] as String? ?? 'unknown',
    sha: json['head_sha'] as String? ?? '',
    url: json['html_url'] as String? ?? 'https://github.com/kdot101kwb-cyber/Auren/actions',
  );
}

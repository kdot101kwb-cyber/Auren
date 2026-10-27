import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first secretary workspace. Email providers and unattended sending
/// are deliberately not simulated: drafts stay on this device until a real,
/// permissioned provider integration is implemented.
class NovaSecretaryCenterScreen extends StatefulWidget {
  const NovaSecretaryCenterScreen({super.key});

  @override
  State<NovaSecretaryCenterScreen> createState() =>
      _NovaSecretaryCenterScreenState();
}

class _NovaSecretaryCenterScreenState extends State<NovaSecretaryCenterScreen> {
  static const _storageKey = 'nova.secretary.drafts.v1';
  final _recipientController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _searchController = TextEditingController();
  String _category = 'استفسار عميل';
  String _filter = 'الكل';
  List<_SecretaryDraft> _drafts = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded != null) {
        final values = jsonDecode(encoded) as List<dynamic>;
        _drafts = values
            .whereType<Map<String, dynamic>>()
            .map(_SecretaryDraft.fromJson)
            .toList();
      }
    } catch (_) {
      // Keep the secretary usable when local storage contains invalid data.
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_drafts.map((draft) => draft.toJson()).toList()),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ المسودات على هذا الجهاز')),
      );
    }
  }

  Future<void> _addDraft() async {
    final recipient = _recipientController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (recipient.isEmpty || subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل البريد والموضوع ونص الرسالة أولاً')),
      );
      return;
    }
    setState(() {
      _drafts.insert(
        0,
        _SecretaryDraft(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          recipient: recipient,
          subject: subject,
          body: body,
          category: _category,
          status: 'مسودة محلية',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      _recipientController.clear();
      _subjectController.clear();
      _bodyController.clear();
    });
    await _persist();
  }

  Future<void> _setStatus(_SecretaryDraft draft, String status) async {
    setState(() {
      final index = _drafts.indexWhere((item) => item.id == draft.id);
      if (index >= 0) _drafts[index] = draft.copyWith(status: status);
    });
    await _persist();
  }

  Future<void> _delete(_SecretaryDraft draft) async {
    setState(() => _drafts.removeWhere((item) => item.id == draft.id));
    await _persist();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visibleDrafts = _drafts.where((draft) {
      final matchesFilter = _filter == 'الكل' ||
          (_filter == 'بانتظار الموافقة' && draft.status == 'بانتظار الموافقة') ||
          (_filter == 'مسودات' && draft.status == 'مسودة محلية');
      final text = '${draft.recipient} ${draft.subject} ${draft.body} ${draft.category}'
          .toLowerCase();
      return matchesFilter && text.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Secretary Center · سكرتير NOVA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF382B70), Color(0xFF202039)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent, size: 30, color: Color(0xFFB9A8FF)),
                  SizedBox(height: 8),
                  Text('سكرتيرك يعمل على تجهيز الشغل',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('مسودات البريد، ردود العملاء، المتابعات، وتسليم واضح للمهام عند عودتك.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _SecretaryNotice(
              text: 'حالة الربط: البريد الإلكتروني غير متصل بعد. ما تنشئه هنا يُحفظ كمسودة محلية فقط؛ لا تُقرأ صناديق البريد ولا تُرسل رسائل تلقائياً في هذه النسخة.',
            ),
            const SizedBox(height: 18),
            Text('تجهيز إيميل أو رد عميل',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            TextField(
              controller: _recipientController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'إلى / بريد العميل',
                hintText: 'customer@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'موضوع الرسالة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'نوع الرسالة',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'استفسار عميل', child: Text('استفسار عميل')),
                DropdownMenuItem(value: 'عميل محتمل', child: Text('عميل محتمل')),
                DropdownMenuItem(value: 'متابعة', child: Text('متابعة')),
                DropdownMenuItem(value: 'دعم فني', child: Text('دعم فني')),
                DropdownMenuItem(value: 'شكوى — تحتاج مراجعة', child: Text('شكوى — تحتاج مراجعة')),
                DropdownMenuItem(value: 'إداري / شخصي', child: Text('إداري / شخصي')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 8,
              textDirection: TextDirection.auto,
              decoration: const InputDecoration(
                labelText: 'نص الإيميل أو الرد',
                hintText: 'اكتب المسودة هنا...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _addDraft,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ المسودة على الجهاز'),
            ),
            const SizedBox(height: 22),
            Text('صندوق المسودات والمتابعة',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ابحث في المسودات',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['الكل', 'مسودات', 'بانتظار الموافقة']
                  .map((filter) => ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            if (!_loaded)
              const Center(child: CircularProgressIndicator())
            else if (visibleDrafts.isEmpty)
              const _SecretaryNotice(
                text: 'لا توجد مسودات مطابقة. أضف مسودة أعلاه؛ سيبقى البريد غير متصل حتى إعداد تكامل رسمي واختباره.',
              )
            else
              ...visibleDrafts.map((draft) => _DraftCard(
                    draft: draft,
                    onReview: () => _setStatus(draft, 'بانتظار الموافقة'),
                    onReturnToDraft: () => _setStatus(draft, 'مسودة محلية'),
                    onDelete: () => _delete(draft),
                  )),
            const SizedBox(height: 18),
            Text('عند غيابك', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const _SecretaryNotice(
              text: 'المرحلة التالية: ربط Gmail أو مزوّد بريد رسمي عبر OAuth وخادم آمن، ثم تصنيف الرسائل الواردة وصياغة الردود. الردود الحساسة ستُرفع إليك للموافقة. العمل أثناء إغلاق التطبيق يتطلب عاملاً خلفياً وجدولة؛ لا يضمنه تشغيل الواجهة وحدها.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SecretaryDraft {
  const _SecretaryDraft({
    required this.id,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String recipient;
  final String subject;
  final String body;
  final String category;
  final String status;
  final String createdAt;

  _SecretaryDraft copyWith({String? status}) => _SecretaryDraft(
        id: id,
        recipient: recipient,
        subject: subject,
        body: body,
        category: category,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient': recipient,
        'subject': subject,
        'body': body,
        'category': category,
        'status': status,
        'createdAt': createdAt,
      };

  factory _SecretaryDraft.fromJson(Map<String, dynamic> json) => _SecretaryDraft(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        recipient: json['recipient'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? 'استفسار عميل',
        status: json['status'] as String? ?? 'مسودة محلية',
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onReview,
    required this.onReturnToDraft,
    required this.onDelete,
  });

  final _SecretaryDraft draft;
  final VoidCallback onReview;
  final VoidCallback onReturnToDraft;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.mail_outline, color: Color(0xFFB9A8FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(draft.subject,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(draft.recipient),
                        Text('${draft.category} · ${draft.status}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(draft.body, maxLines: 5, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                if (draft.status == 'مسودة محلية')
                  OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('إرسال للمراجعة'),
                  ),
                if (draft.status == 'بانتظار الموافقة')
                  OutlinedButton(
                    onPressed: onReturnToDraft,
                    child: const Text('إرجاع للمسودات'),
                  ),
                IconButton(
                  tooltip: 'حذف المسودة',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ]),
            ],
          ),
        ),
      );
}

class _SecretaryNotice extends StatelessWidget {
  const _SecretaryNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF282438),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, textDirection: TextDirection.rtl),
      );
}

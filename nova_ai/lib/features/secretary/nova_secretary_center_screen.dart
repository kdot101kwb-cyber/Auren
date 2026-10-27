import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _secretaryViolet = Color(0xFF9B87FF);
const _draftsKey = 'nova.secretary.drafts.v1';

class SecretaryDraft {
  final String id;
  final String workspace;
  final String recipient;
  final String subject;
  final String body;
  final String status;
  final DateTime updatedAt;

  const SecretaryDraft({
    required this.id,
    required this.workspace,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.status,
    required this.updatedAt,
  });

  SecretaryDraft copyWith({String? recipient, String? subject, String? body, String? status, DateTime? updatedAt}) =>
      SecretaryDraft(id: id, workspace: workspace, recipient: recipient ?? this.recipient,
        subject: subject ?? this.subject, body: body ?? this.body, status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt);

  Map<String, Object?> toJson() => {
    'id': id, 'workspace': workspace, 'recipient': recipient, 'subject': subject,
    'body': body, 'status': status, 'updatedAt': updatedAt.toIso8601String(),
  };

  factory SecretaryDraft.fromJson(Map<String, dynamic> json) => SecretaryDraft(
    id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    workspace: json['workspace'] as String? ?? 'NOVA',
    recipient: json['recipient'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    body: json['body'] as String? ?? '',
    status: json['status'] as String? ?? 'مسودة محلية',
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class NovaSecretaryCenterScreen extends StatefulWidget {
  const NovaSecretaryCenterScreen({super.key});

  @override
  State<NovaSecretaryCenterScreen> createState() => _NovaSecretaryCenterScreenState();
}

class _NovaSecretaryCenterScreenState extends State<NovaSecretaryCenterScreen> {
  String workspace = 'NOVA';
  final recipientController = TextEditingController();
  final subjectController = TextEditingController();
  final bodyController = TextEditingController();
  List<SecretaryDraft> drafts = [];
  String? editingId;
  bool loading = true;
  String filter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  @override
  void dispose() {
    recipientController.dispose();
    subjectController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftsKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        drafts = decoded.whereType<Map<String, dynamic>>().map(SecretaryDraft.fromJson).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<bool> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftsKey, jsonEncode(drafts.map((d) => d.toJson()).toList()));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _newDraft({String? templateSubject, String? templateBody}) {
    setState(() {
      editingId = null;
      recipientController.clear();
      subjectController.text = templateSubject ?? '';
      bodyController.text = templateBody ?? '';
    });
  }

  void _edit(SecretaryDraft draft) {
    setState(() {
      workspace = draft.workspace;
      editingId = draft.id;
      recipientController.text = draft.recipient;
      subjectController.text = draft.subject;
      bodyController.text = draft.body;
    });
  }

  Future<void> _save({bool awaitingApproval = false}) async {
    final subject = subjectController.text.trim();
    final body = bodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل عنوان الرسالة ونصها أولاً')));
      return;
    }
    final now = DateTime.now();
    final existingIndex = drafts.indexWhere((d) => d.id == editingId);
    final draft = SecretaryDraft(
      id: editingId ?? now.microsecondsSinceEpoch.toString(),
      workspace: workspace,
      recipient: recipientController.text.trim(),
      subject: subject,
      body: body,
      status: awaitingApproval ? 'بانتظار موافقتك' : 'مسودة محلية',
      updatedAt: now,
    );
    setState(() {
      if (existingIndex >= 0) {
        drafts[existingIndex] = draft;
      } else {
        drafts.insert(0, draft);
      }
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      editingId = draft.id;
    });
    final saved = await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved
        ? (awaitingApproval ? 'حُفظت المسودة في قائمة المراجعة — لم تُرسل' : 'حُفظت المسودة على هذا الجهاز')
        : 'تعذر حفظ المسودة؛ تحقق من مساحة التخزين'),
    ));
  }

  Future<void> _delete(SecretaryDraft draft) async {
    setState(() => drafts.removeWhere((d) => d.id == draft.id));
    final saved = await _persist();
    if (!mounted) return;
    if (editingId == draft.id) _newDraft();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved ? 'حُذفت المسودة المحلية' : 'تعذر تحديث التخزين'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final visibleDrafts = drafts.where((d) => filter == 'الكل' || d.status == filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('مركز السكرتير التنفيذي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF49317C), Color(0xFF202039)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.mark_email_read_outlined, color: _secretaryViolet, size: 30),
              SizedBox(height: 8),
              Text('سكرتيرك يجهّز العمل وأنت غائب', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('جهّز رسائل العملاء، رتّب المتابعات، واحفظ المسودات للمراجعة عند عودتك.'),
            ]),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'NOVA', label: Text('بريدي الشخصي'), icon: Icon(Icons.person_outline)),
              ButtonSegment(value: 'AUREN', label: Text('عملاء AUREN'), icon: Icon(Icons.business_outlined)),
            ],
            selected: {workspace},
            onSelectionChanged: (selection) => setState(() { workspace = selection.first; editingId = null; }),
          ),
          const SizedBox(height: 10),
          const _SecretaryNotice(
            text: 'هذه النسخة تحفظ المسودات محلياً فقط. لم يتم ربط Gmail/Outlook أو صندوق عملاء AUREN، ولا تُقرأ الرسائل الحقيقية ولا تُرسل رسائل من هذه الشاشة.',
          ),
          const SizedBox(height: 18),
          const Text('قوالب سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(
              avatar: const Icon(Icons.waving_hand_outlined, size: 18),
              label: const Text('رد ترحيبي'),
              onPressed: () => _newDraft(
                templateSubject: workspace == 'AUREN' ? 'شكراً لتواصلك مع AUREN' : 'شكراً لرسالتك',
                templateBody: workspace == 'AUREN'
                  ? 'مرحباً،\n\nشكراً لتواصلك مع AUREN. استلمنا استفسارك وسنراجعه ونعود إليك بالمعلومات المتاحة.\n\nمع التحية،\nفريق AUREN'
                  : 'مرحباً،\n\nشكراً لرسالتك. اطلعت على رسالتك وسأعود إليك قريباً.\n\nمع التحية',
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: const Text('متابعة'),
              onPressed: () => _newDraft(
                templateSubject: 'متابعة بخصوص رسالتنا السابقة',
                templateBody: 'مرحباً،\n\nأتابع معك بخصوص رسالتنا السابقة. هل توجد أي مستجدات يمكنني المساعدة فيها؟\n\nمع التحية',
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.support_agent, size: 18),
              label: const Text('طلب تفاصيل'),
              onPressed: () => _newDraft(
                templateSubject: 'نحتاج بعض التفاصيل الإضافية',
                templateBody: 'مرحباً،\n\nحتى نساعدك بصورة دقيقة، هل يمكنك مشاركة مزيد من التفاصيل حول طلبك؟ يرجى عدم إرسال كلمات المرور أو بيانات الدفع السرية.\n\nشكراً لك',
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.event_note, size: 18),
              label: const Text('ملخص اجتماع'),
              onPressed: () => _newDraft(
                templateSubject: 'ملخص الاجتماع والخطوات التالية',
                templateBody: 'مرحباً،\n\nملخص النقاط المتفق عليها:\n1. \n2. \n\nالخطوات التالية والمسؤوليات:\n- \n\nيرجى تصحيح أي نقطة غير دقيقة.',
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Text(editingId == null ? 'إنشاء مسودة' : 'تعديل المسودة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: recipientController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'إلى (اختياري)', hintText: 'customer@example.com', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(labelText: 'عنوان الرسالة', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bodyController,
            minLines: 5,
            maxLines: 10,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'نص الرسالة', alignLabelWithHint: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: () => _save(),
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ المسودة'),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _save(awaitingApproval: true),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('للمراجعة'),
            )),
          ]),
          const SizedBox(height: 22),
          const Text('صندوق المتابعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('المحفوظ على هذا الجهاز — وليس صندوق بريد متصلاً.'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: filter,
            decoration: const InputDecoration(labelText: 'تصفية المسودات', border: OutlineInputBorder()),
            items: const ['الكل', 'مسودة محلية', 'بانتظار موافقتك']
              .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => setState(() => filter = value ?? 'الكل'),
          ),
          const SizedBox(height: 8),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (visibleDrafts.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد مسودات بعد. اختر قالباً أو اكتب رسالة جديدة.')))
          else
            ...visibleDrafts.map((draft) => Card(
              child: ListTile(
                leading: Icon(draft.status == 'بانتظار موافقتك' ? Icons.pending_actions : Icons.drafts_outlined, color: _secretaryViolet),
                title: Text(draft.subject, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${draft.workspace} • ${draft.status}\n${draft.recipient.isEmpty ? 'لم يُحدد المستلم' : draft.recipient}', maxLines: 3),
                isThreeLine: true,
                onTap: () => _edit(draft),
                trailing: IconButton(
                  tooltip: 'حذف المسودة',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(draft),
                ),
              ),
            )),
          const SizedBox(height: 12),
          const _SecretaryNotice(
            text: 'المرحلة التالية: OAuth رسمي للبريد، خادم آمن للفرز والجدولة، قاعدة معرفة لأسئلة العملاء، تنبيهات، سجل تدقيق ومنع التكرار. لن يحدث إرسال تلقائي قبل تحديد الصلاحيات واختبار التكامل.',
          ),
        ],
      ),
    );
  }
}

class _SecretaryNotice extends StatelessWidget {
  final String text;
  const _SecretaryNotice({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xFF282438), borderRadius: BorderRadius.circular(14)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, color: _secretaryViolet),
      const SizedBox(width: 10),
      Expanded(child: Text(text, textDirection: TextDirection.rtl)),
    ]),
  );
}

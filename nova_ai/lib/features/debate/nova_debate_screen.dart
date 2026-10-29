import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NovaDebateScreen extends StatefulWidget {
  const NovaDebateScreen({super.key});

  @override
  State<NovaDebateScreen> createState() => _NovaDebateScreenState();
}

class _NovaDebateScreenState extends State<NovaDebateScreen> {
  static const _ink = Color(0xFF11152B);
  static const _violet = Color(0xFF29245B);
  static const _lilac = Color(0xFF8B7CFF);
  static const _sky = Color(0xFF62C7F2);

  final prompt = TextEditingController();
  final contextNotes = TextEditingController();
  bool loading = false;
  String? error;
  Map<String, dynamic>? result;
  String? debateId;
  bool approving = false;
  bool approved = false;
  String? approvalMessage;

  @override
  void dispose() {
    prompt.dispose();
    contextNotes.dispose();
    super.dispose();
  }

  Future<void> review() async {
    if (prompt.text.trim().isEmpty || loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      result = null;
      debateId = null;
      approved = false;
      approvalMessage = null;
    });
    try {
      await _ensureSignedIn();
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('novaStrategicDebate');
      final response = await callable.call(<String, dynamic>{
        'prompt': prompt.text.trim(),
        'context': contextNotes.text.trim(),
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() {
        result = Map<String, dynamic>.from(data['debate'] as Map);
        debateId = data['debateId'] as String?;
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() => error = e.message ?? 'تعذر تنفيذ مراجعة النقاش.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'تعذر تسجيل الدخول أو قراءة النتيجة. تأكد من تفعيل تسجيل الدخول المجهول في Firebase ومن الاتصال.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> approve() async {
    if (debateId == null || approving || approved) return;
    setState(() {
      approving = true;
      approvalMessage = null;
    });
    try {
      await _ensureSignedIn();
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('novaApproveDebatePlan');
      final response =
          await callable.call(<String, dynamic>{'debateId': debateId});
      final data = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() {
        approved = data['status'] == 'plan_approved';
        approvalMessage = data['message'] as String? ?? 'تمت معالجة الموافقة.';
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() => approvalMessage = e.message ?? 'تعذر تسجيل الموافقة.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => approvalMessage = 'تعذر تسجيل الموافقة. لم يبدأ التنفيذ.');
      }
    } finally {
      if (mounted) setState(() => approving = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _lilac),
      alignLabelWithHint: true,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _lilac, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مجلس النقاش الاستراتيجي'),
        centerTitle: false,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildHero(),
            const SizedBox(height: 22),
            const _SectionHeading(
              eyebrow: 'ابدأ من القرار',
              title: 'ما الذي تريد من NOVA اختباره؟',
              subtitle: 'أعطه هدفك والسياق المتاح، وسيعرض لك الاعتراضات والبدائل.',
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('nova-debate-prompt'),
              controller: prompt,
              minLines: 3,
              maxLines: 6,
              maxLength: 5000,
              textDirection: TextDirection.rtl,
              decoration: _inputDecoration(
                label: 'الخطة أو القرار',
                hint: 'مثلاً: قيّم أفضل طريقة لبناء مصدر دخل دون رأس مال...',
                icon: Icons.lightbulb_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('nova-debate-context'),
              controller: contextNotes,
              minLines: 2,
              maxLines: 5,
              maxLength: 12000,
              textDirection: TextDirection.rtl,
              decoration: _inputDecoration(
                label: 'السياق والأدلة (اختياري)',
                hint: 'الوقت، الميزانية، القيود، أو ما جربته سابقاً',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: loading || prompt.text.trim().isEmpty ? null : review,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _lilac,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.balance_rounded),
              label: Text(
                loading ? 'المجلس يراجع الخطة...' : 'راجع الخطة واعترض عليها',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لن ينفّذ NOVA أي إجراء خارجي من هذه الشاشة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              _MessagePanel(
                key: const Key('nova-debate-error'),
                icon: Icons.error_outline_rounded,
                title: 'لم تكتمل المراجعة',
                message: error!,
                isError: true,
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 26),
              const _SectionHeading(
                eyebrow: 'ملخص المجلس',
                title: 'نتيجة المراجعة',
                subtitle: 'اقرأ المقترح والاعتراضات قبل اعتماد أي خطة.',
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant),
                ),
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  JsonEncoder.withIndent('  ').convert(_visibleResult),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'monospace', height: 1.5),
                ),
              ),
              const SizedBox(height: 14),
              _buildApprovalPanel(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_ink, _violet],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _lilac.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lilac.withValues(alpha: 0.55)),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: _sky, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOVA / DECISION LAB',
                      style: TextStyle(
                        color: _sky,
                        fontSize: 11,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'فكّر بوضوح. قرّر بثقة.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'مراجعة من أربع زوايا: التطوير، الجودة، الأمان، والتكلفة — لمساعدتك على كشف المخاطر قبل البدء.',
            style: TextStyle(color: Color(0xFFE4E5F4), height: 1.55),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _PerspectiveChip(icon: Icons.build_outlined, label: 'التطوير'),
              _PerspectiveChip(icon: Icons.verified_outlined, label: 'الجودة'),
              _PerspectiveChip(icon: Icons.shield_outlined, label: 'الأمان'),
              _PerspectiveChip(icon: Icons.timer_outlined, label: 'الوقت والتكلفة'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'شفافية: أربع زوايا مراجعة من نموذج واحد، وليست أربعة نماذج مستقلة.',
            style: TextStyle(color: Color(0xFFBFC3DE), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalPanel() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('nova-debate-approval'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.check_circle_outline : Icons.gpp_good_outlined,
                color: approved ? colors.primary : _lilac,
                size: 25,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'بوابة التنفيذ',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              _StatusPill(label: approved ? 'تم تسجيلها' : 'بانتظارك'),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'الخطة بانتظار موافقتك. لم يتم تنفيذ أي أمر أو تغيير. تسجيل الموافقة لا يعني أن منفّذ المهام متصل أو أن تغييرات نُشرت.',
            style: TextStyle(height: 1.5),
          ),
          if (debateId != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              'معرّف السجل: $debateId',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
          if (debateId != null && !approved) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: approving ? null : approve,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: approving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(
                  approving ? 'تسجيل الموافقة...' : 'اعتماد الخطة وتسجيل الاتفاق',
                ),
              ),
            ),
          ],
          if (approvalMessage != null) ...[
            const SizedBox(height: 10),
            Text(approvalMessage!, style: const TextStyle(height: 1.4)),
          ],
          if (approved) ...[
            const SizedBox(height: 10),
            const _MessagePanel(
              icon: Icons.info_outline_rounded,
              title: 'تم تسجيل الموافقة فقط',
              message: 'التنفيذ الفعلي لم يُفعّل من هذه الشاشة.',
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> get _visibleResult => result ?? <String, dynamic>{};
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: _NovaDebateScreenState._lilac,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
        ),
      ],
    );
  }
}

class _PerspectiveChip extends StatelessWidget {
  const _PerspectiveChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _NovaDebateScreenState._sky, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _NovaDebateScreenState._lilac.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _NovaDebateScreenState._lilac,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.primary;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/offline/nova_local_workspace_backup_service.dart';

/// Manual copy/paste backup. No file or cloud transfer is performed.
class NovaLocalBackupScreen extends StatefulWidget {
  const NovaLocalBackupScreen({super.key});

  @override
  State<NovaLocalBackupScreen> createState() => _NovaLocalBackupScreenState();
}

class _NovaLocalBackupScreenState extends State<NovaLocalBackupScreen> {
  String? _backup;
  bool _busy = false;
  String? _message;

  Future<NovaLocalWorkspaceBackupService> _service() async =>
      NovaLocalWorkspaceBackupService(
        preferences: await SharedPreferences.getInstance(),
      );

  Future<void> _createBackup() async {
    setState(() { _busy = true; _message = null; });
    try {
      final value = await (await _service()).exportJson();
      if (!mounted) return;
      setState(() { _backup = value; _message = 'تم تجهيز نسخة المهام المحلية.'; });
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذر تجهيز النسخة الاحتياطية.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyBackup() async {
    final value = _backup;
    if (value == null) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) setState(() => _message = 'نُسخت النسخة إلى الحافظة. احفظها في مكان آمن.');
  }

  Future<void> _restoreDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة نسخة المهام'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 10,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'الصق محتوى نسخة NOVA JSON هنا',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تحقق واستعد')),
        ],
      ),
    );
    final source = controller.text;
    controller.dispose();
    if (confirmed != true) return;
    setState(() { _busy = true; _message = null; });
    try {
      final restored = await (await _service()).restoreJson(source);
      if (mounted) setState(() => _message = restored
          ? 'تمت استعادة المهام المحلية.'
          : 'النسخة غير صالحة أو لا تتوافق مع الإصدار الحالي. لم تتغير البيانات.');
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذرت الاستعادة. لم يتم تأكيد أي تغيير.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('النسخ الاحتياطي المحلي')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'هذه النسخة تشمل مهام مساحة العمل فقط. لا تشمل حسابات الدخول أو كلمات المرور أو بيانات المحافظ أو سجل الموافقات. النسخ والاستعادة يدويان عبر نص JSON.',
            textDirection: TextDirection.rtl,
          ),
        )),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _createBackup,
          icon: const Icon(Icons.backup_outlined),
          label: const Text('إنشاء نسخة احتياطية'),
        ),
        OutlinedButton.icon(
          onPressed: _busy || _backup == null ? null : _copyBackup,
          icon: const Icon(Icons.copy),
          label: const Text('نسخ JSON'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restoreDialog,
          icon: const Icon(Icons.restore),
          label: const Text('استعادة من JSON'),
        ),
        if (_busy) const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        if (_message != null) Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_message!, textDirection: TextDirection.rtl),
        ),
        if (_backup != null) Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(_backup!, maxLines: 12),
          ),
        ),
      ],
    ),
  );
}

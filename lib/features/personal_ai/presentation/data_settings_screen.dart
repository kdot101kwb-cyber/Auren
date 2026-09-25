import 'package:flutter/material.dart';
import '../../../services/offline/auren_low_data_settings.dart';

class AurenDataSettingsScreen extends StatefulWidget {
  const AurenDataSettingsScreen({super.key});

  @override
  State<AurenDataSettingsScreen> createState() => _AurenDataSettingsScreenState();
}

class _AurenDataSettingsScreenState extends State<AurenDataSettingsScreen> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await AurenLowDataSettings.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await AurenLowDataSettings.instance.setEnabled(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? 'تم تفعيل توفير البيانات' : 'تم إيقاف توفير البيانات')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Data & Offline')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: SwitchListTile(
                value: _enabled,
                onChanged: _loading ? null : _toggle,
                title: const Text('Low Data Mode'),
                subtitle: const Text('خلي AUREN يقلل استهلاك البيانات عندما تكون الباقة محدودة.'),
                secondary: const Icon(Icons.data_saver_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.cloud_off_outlined),
                title: Text('Offline Sync'),
                subtitle: Text('الإجراءات التي يسجلها النظام في الطابور تنتظر رجوع الاتصال ثم تُعاد عبر الـhandlers المسجلة.'),
              ),
            ),
          ],
        ),
      );
}

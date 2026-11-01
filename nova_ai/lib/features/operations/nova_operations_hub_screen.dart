import 'package:flutter/material.dart';

import '../approvals/nova_approval_center_screen.dart';
import '../audit/nova_audit_timeline_screen.dart';
import '../backup/nova_local_backup_screen.dart';
import '../planning/nova_daily_planner_screen.dart';
import '../workspace/nova_workspace_screen.dart';

/// Single entry point for NOVA's offline operations tools.
class NovaOperationsHubScreen extends StatelessWidget {
  const NovaOperationsHubScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مركز تشغيل NOVA')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hub_outlined, size: 30),
              SizedBox(height: 10),
              Text('إدارة العمل والقرارات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('المهام والتخطيط والموافقات وسجل التدقيق في مساحة واحدة.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _HubTile(
          icon: Icons.checklist,
          title: 'مساحة العمل',
          description: 'أضف المهام وتابع إنجازها محلياً',
          onTap: () => _open(context, const NovaWorkspaceScreen()),
        ),
        _HubTile(
          icon: Icons.today_outlined,
          title: 'المخطط اليومي',
          description: 'وزّع وقتك واعرف ما سيؤجل',
          onTap: () => _open(context, const NovaDailyPlannerScreen()),
        ),
        _HubTile(
          icon: Icons.verified_user_outlined,
          title: 'موافقات المالك',
          description: 'راجع الطلبات الحساسة ووافق أو ارفض',
          onTap: () => _open(context, const NovaApprovalCenterScreen()),
        ),
        _HubTile(
          icon: Icons.backup_outlined,
          title: 'النسخ الاحتياطي المحلي',
          description: 'صدّر مهامك أو استعدها بنص JSON',
          onTap: () => _open(context, const NovaLocalBackupScreen()),
        ),
        _HubTile(
          icon: Icons.receipt_long_outlined,
          title: 'سجل التدقيق',
          description: 'راجع القرارات والأحداث المسجلة محلياً',
          onTap: () => _open(context, const NovaAuditTimelineScreen()),
        ),
        const SizedBox(height: 12),
        const Text(
          'كل الأدوات الحالية محلية. النسخ يشمل المهام فقط. الموافقة لا تعني التنفيذ، ولا يوجد نشر أو إرسال أو تحويل أموال تلقائي.',
          textDirection: TextDirection.rtl,
        ),
      ],
    ),
  );
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title, textDirection: TextDirection.rtl),
      subtitle: Text(description, textDirection: TextDirection.rtl),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

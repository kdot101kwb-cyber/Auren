import 'package:flutter/material.dart';
import 'offline_safety_screen.dart';
import 'blocked_users_screen.dart';
import 'emergency_contacts_screen.dart';

class AurenSafetyCenterScreen extends StatelessWidget {
  const AurenSafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Safety Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined),
                      SizedBox(width: 10),
                      Text(
                        'Safety first',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أدوات الأمان في AUREN تجمع الحظر، نقاط الأمان، والمساعدة عند ضعف الاتصال في مكان واحد.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.offline_bolt_outlined),
              title: const Text('Offline Navigation + Safety'),
              subtitle: const Text('نقاط أمان ومعلومات مفيدة عند ضعف الإنترنت.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenOfflineSafetyScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.contact_emergency_outlined),
              title: const Text('Emergency Contacts'),
              subtitle: const Text('جهات موثوقة محفوظة للوصول السريع عند الحاجة.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenEmergencyContactsScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Blocked users'),
              subtitle: const Text('راجع الحسابات التي حظرتها وألغِ الحظر عند الحاجة.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenBlockedUsersScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('AUREN Safety'),
              subtitle: Text(
                'في الحالات الطارئة الحقيقية استخدم خدمات الطوارئ المحلية المتاحة في منطقتك.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

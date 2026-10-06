import 'package:flutter/material.dart';
import '../../../core/models/emergency.dart';
import '../../../services/emergency/emergency_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenEmergencyScreen extends StatefulWidget {
  const AurenEmergencyScreen({super.key});
  @override State<AurenEmergencyScreen> createState() => _AurenEmergencyScreenState();
}

class _AurenEmergencyScreenState extends State<AurenEmergencyScreen> {
  String city = '';
  String country = '';

  Future<void> _chooseArea() async {
    final a = TextEditingController(text: city);
    final b = TextEditingController(text: country);
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('منطقة الطوارئ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: a, decoration: const InputDecoration(labelText: 'المدينة')),
          TextField(controller: b, decoration: const InputDecoration(labelText: 'الدولة')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              setState(() { city = a.text.trim(); country = b.text.trim(); });
              Navigator.pop(d);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    a.dispose();
    b.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessengerScreen(
                  initialPrompt: 'أحتاج خطة طوارئ آمنة لهذه المنطقة. اذكر الخدمات المهمة وما المعلومات التي يجب تجهيزها.',
                ),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.location_city), onPressed: _chooseArea),
        ],
      ),
      body: StreamBuilder<List<AurenEmergencyContact>>(
        stream: AurenEmergencyService.instance.watch(city: city, country: country),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل خدمات الطوارئ.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final contacts = snapshot.data!;
          if (contacts.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد أرقام طوارئ موثقة لهذه المنطقة حالياً.')));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final x = contacts[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.emergency)),
                title: Text(x.name),
                subtitle: Text('${x.type} • ${x.city}, ${x.country}'),
                trailing: SelectableText(x.phone),
              );
            },
          );
        },
      ),
    );
  }
}
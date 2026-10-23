import 'package:flutter/material.dart';

import '../../../services/emergency/emergency_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'emergency_preparedness_card.dart';

class AurenEmergencyScreen extends StatefulWidget {
  const AurenEmergencyScreen({super.key});

  @override
  State<AurenEmergencyScreen> createState() => _AurenEmergencyScreenState();
}

class _AurenEmergencyScreenState extends State<AurenEmergencyScreen> {
  String city = '';
  String country = '';

  Future<void> _chooseArea() async {
    final cityController = TextEditingController(text: city);
    final countryController = TextEditingController(text: country);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('منطقة الطوارئ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'المدينة'),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'الدولة'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  city = cityController.text.trim();
                  country = countryController.text.trim();
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
    } finally {
      cityController.dispose();
      countryController.dispose();
    }
  }

  String get _areaLabel {
    final parts = [city.trim(), country.trim()]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        actions: [
          IconButton(
            tooltip: 'إنشاء خطة بمساعدة AUREN',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessengerScreen(
                  initialPrompt:
                      'أحتاج خطة طوارئ آمنة لهذه المنطقة. اذكر الخدمات المهمة وما المعلومات التي يجب تجهيزها، ولا تخترع أرقام طوارئ غير موثقة.',
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'اختيار المنطقة',
            icon: const Icon(Icons.location_city),
            onPressed: _chooseArea,
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEmergencyContact>>(
        stream: AurenEmergencyService.instance.watch(
          city: city,
          country: country,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('تعذر تحميل خدمات الطوارئ.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length + 2,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AurenEmergencyPreparednessCard(area: _areaLabel);
              }
              if (index == 1 && contacts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لا توجد أرقام طوارئ موثقة لهذه المنطقة حالياً. '
                    'لا تستخدم أرقاماً غير متحقق منها.',
                  ),
                );
              }
              if (contacts.isEmpty) {
                return const SizedBox.shrink();
              }
              final contact = contacts[index - 2];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.emergency),
                ),
                title: Text(contact.name),
                subtitle: Text(
                  '${contact.type} • ${contact.city}, ${contact.country}',
                ),
                trailing: SelectableText(contact.phone),
              );
            },
          );
        },
      ),
    );
  }
}

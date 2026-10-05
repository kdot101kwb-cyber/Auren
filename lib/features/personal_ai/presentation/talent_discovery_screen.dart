import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentDiscoveryScreen extends StatelessWidget {
  const AurenTalentDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talent Discovery')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, size: 38),
                  const SizedBox(height: 12),
                  const Text(
                    'Talent Discovery',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text('واجهة AUREN جاهزة للعمل ويمكن توسيعها وربطها بالخدمات دون تعطيل التطبيق.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessengerScreen(
                            initialPrompt: 'ساعدني في استخدام ميزة Talent Discovery داخل AUREN وحوّل هدفي إلى خطوات عملية.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('اسأل AUREN'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

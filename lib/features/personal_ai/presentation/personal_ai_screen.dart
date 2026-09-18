import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class PersonalAiScreen extends StatelessWidget {
  const PersonalAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal AI')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('What do you want to achieve?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('حوّل هدفك إلى خطوات، ثم نفّذها بإذنك.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen())),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Talk to AUREN AI'),
          ),
          const SizedBox(height: 12),
          const ListTile(leading: Icon(Icons.flag_outlined), title: Text('Goals'), subtitle: Text('Goal → Reality')), 
          const ListTile(leading: Icon(Icons.task_alt), title: Text('Action Center'), subtitle: Text('Actions requiring your approval')), 
          const ListTile(leading: Icon(Icons.memory), title: Text('AI Memory'), subtitle: Text('User-controlled personal context')), 
        ],
      ),
    );
  }
}

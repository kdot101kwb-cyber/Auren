import 'package:flutter/material.dart';
import '../../../services/talent/talent_categories.dart';
import '../../../services/talent/talent_specialized_catalog.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentSpecializedTools extends StatefulWidget {
  const AurenTalentSpecializedTools({super.key});

  @override
  State<AurenTalentSpecializedTools> createState() => _AurenTalentSpecializedToolsState();
}

class _AurenTalentSpecializedToolsState extends State<AurenTalentSpecializedTools> {
  String selected = 'music';

  @override
  Widget build(BuildContext context) {
    final tools = AurenTalentSpecializedCatalog.byCategory[selected] ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧩 Talent Labs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'أدوات متخصصة لكل مجال من مجالات Talent: تطوير، ممارسة، إنشاء، Portfolio وShowcase.',
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: 'اختر مجال الموهبة',
                border: OutlineInputBorder(),
              ),
              items: AurenTalentCategories.all
                  .map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selected = value);
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tools
                  .map(
                    (tool) => ActionChip(
                      avatar: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(tool.name),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessengerScreen(
                            initialPrompt: tool.prompt,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenMarketplaceScreen extends StatelessWidget {
  const AurenMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessengerScreen(
                  initialPrompt: 'ساعدني أجد منتجًا أو خدمة مناسبة لاحتياجي.',
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: MarketplaceRepository().watchPublic(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Text('لا توجد منتجات أو خدمات منشورة بعد.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((p) => Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                  p.priceMinor.toString() +
                      ' ' +
                      p.currency +
                      ' • ' +
                      p.category,
                ),
              ),
            )).toList(),
          );
        },
      ),
    );
  }
}

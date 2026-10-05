import 'package:flutter/material.dart';
import '../../../services/marketplace/marketplace_repository.dart';

class AurenSellerStorefrontScreen extends StatelessWidget {
  const AurenSellerStorefrontScreen({
    super.key,
    required this.ownerId,
  });

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Store')),
      body: StreamBuilder(
        stream: MarketplaceRepository().watchByOwnerIds([ownerId]),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Text('لا توجد منتجات منشورة بعد.'),
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

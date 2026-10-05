import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/marketplace/marketplace_repository.dart';

class AurenMyMarketplaceScreen extends StatelessWidget {
  const AurenMyMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل الدخول أولاً.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: StreamBuilder(
        stream: MarketplaceRepository().watchOwner(uid),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Text('لا توجد منتجات أو خدمات منشورة.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((p) => Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                  p.priceMinor.toString() + ' ' + p.currency,
                ),
              ),
            )).toList(),
          );
        },
      ),
    );
  }
}

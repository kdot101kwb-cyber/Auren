import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenSellerStorefrontScreen extends StatelessWidget {
  AurenSellerStorefrontScreen({super.key, required this.ownerId});
  final String ownerId;
@override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    if ('AurenSellerStorefrontScreen' == 'AurenMarketplaceScreen') return Scaffold(appBar: AppBar(title: const Text('Marketplace'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'ساعدني أجد منتجًا أو خدمة مناسبة لاحتياجي.'))), icon: const Icon(Icons.auto_awesome))]), body: StreamBuilder(stream: MarketplaceRepository().watchPublic(), builder: (context, snapshot) {
      final items = snapshot.data ?? const [];
      return ListView(padding: const EdgeInsets.all(16), children: [
        Text('Marketplace', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...items.map((p) => Card(child: ListTile(title: Text(p.name), subtitle: Text('${p.priceMinor / 100} ${p.currency} • ${p.category}')))),
      ]);
    }));
    if ('AurenSellerStorefrontScreen' == 'AurenMyMarketplaceScreen') return Scaffold(appBar: AppBar(title: const Text('My Listings')), body: StreamBuilder(stream: MarketplaceRepository().watchOwner(uid), builder: (context, snapshot) {
      final items = snapshot.data ?? const [];
      if (items.isEmpty) return const Center(child: Text('لا توجد منتجات أو خدمات منشورة.'));
      return ListView(padding: const EdgeInsets.all(16), children: items.map((p) => Card(child: ListTile(title: Text(p.name), subtitle: Text('${p.priceMinor / 100} ${p.currency}')))).toList();
    }));
    if ('AurenSellerStorefrontScreen' == 'AurenMarketplaceCommerceScreen') return Scaffold(appBar: AppBar(title: const Text('Marketplace Center')), body: ListView(padding: const EdgeInsets.all(16), children: const [
      Card(child: ListTile(leading: Icon(Icons.shopping_cart_outlined), title: Text('السلة'), subtitle: Text('إدارة عناصر الشراء هنا.'))),
      Card(child: ListTile(leading: Icon(Icons.local_shipping_outlined), title: Text('الطلبات'), subtitle: Text('متابعة حالات الطلبات هنا.'))),
      Card(child: ListTile(leading: Icon(Icons.payments_outlined), title: Text('الدفع'), subtitle: Text('بوابة الدفع الفعلية تُربط لاحقاً.'))),
    ]));
    return Scaffold(appBar: AppBar(title: const Text('My Store')), body: StreamBuilder(stream: MarketplaceRepository().watchByOwnerIds([ownerId]), builder: (context, snapshot) {
      final items = snapshot.data ?? const [];
      if (items.isEmpty) return const Center(child: Text('لا توجد منتجات منشورة بعد.'));
      return ListView(padding: const EdgeInsets.all(16), children: items.map((p) => Card(child: ListTile(title: Text(p.name), subtitle: Text('${p.priceMinor / 100} ${p.currency}')))).toList();
    }));
  }
}
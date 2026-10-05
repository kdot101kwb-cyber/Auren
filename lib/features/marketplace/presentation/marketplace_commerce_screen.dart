import 'package:flutter/material.dart';

class AurenMarketplaceCommerceScreen extends StatelessWidget {
  const AurenMarketplaceCommerceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.shopping_cart_outlined),
              title: Text('السلة'),
              subtitle: Text('إدارة عناصر الشراء هنا.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.local_shipping_outlined),
              title: Text('الطلبات'),
              subtitle: Text('متابعة حالات الطلبات هنا.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.payments_outlined),
              title: Text('الدفع'),
              subtitle: Text('بوابة الدفع الفعلية تُربط لاحقاً.'),
            ),
          ),
        ],
      ),
    );
  }
}

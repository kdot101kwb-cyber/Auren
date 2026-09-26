import 'package:flutter/material.dart';

import '../../../services/social/match_everything_service.dart';
import '../../../core/models/business.dart';
import '../../../core/models/product.dart';
import '../../business/presentation/business_detail_screen.dart';
import '../../marketplace/presentation/product_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'auren_opportunity_detail_screen.dart';
import 'auren_content_detail_screen.dart';

class AurenMatchDetailScreen extends StatelessWidget {
  final AurenMatchItem item;
  final String intent;

  const AurenMatchDetailScreen({
    super.key,
    required this.item,
    required this.intent,
  });

  String _kindLabel(AurenMatchKind kind) {
    switch (kind) {
      case AurenMatchKind.person: return 'شخص';
      case AurenMatchKind.opportunity: return 'فرصة';
      case AurenMatchKind.business: return 'شركة / نشاط';
      case AurenMatchKind.product: return 'منتج';
      case AurenMatchKind.content: return 'محتوى';
    }
  }

  IconData _kindIcon(AurenMatchKind kind) {
    switch (kind) {
      case AurenMatchKind.person: return Icons.person_outline;
      case AurenMatchKind.opportunity: return Icons.radar;
      case AurenMatchKind.business: return Icons.storefront_outlined;
      case AurenMatchKind.product: return Icons.shopping_bag_outlined;
      case AurenMatchKind.content: return Icons.play_circle_outline;
    }
  }

  List<MapEntry<String, String>> _details() {
    const keys = [
      'category', 'type', 'location', 'country', 'city',
      'price', 'currency', 'description', 'text', 'headline',
    ];
    final result = <MapEntry<String, String>>[];
    for (final key in keys) {
      final value = item.data[key];
      if (value == null) continue;
      final valueText = value.toString().trim();
      if (valueText.isEmpty || valueText == 'null') continue;
      result.add(MapEntry(key, valueText));
    }
    return result;
  }

  void _continue(BuildContext context) {
    switch (item.kind) {
      case AurenMatchKind.person:
        final uid = (item.data['uid'] ?? item.data['ownerId'])?.toString();
        if (uid != null && uid.isNotEmpty) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenProfileScreen(userId: uid)));
          return;
        }
        break;
      case AurenMatchKind.business:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AurenBusinessDetailScreen(
            business: AurenBusiness.fromMap(item.id, item.data),
          ),
        ));
        return;
      case AurenMatchKind.product:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AurenProductDetailScreen(
            product: AurenProduct.fromMap(item.id, item.data),
          ),
        ));
        return;
      case AurenMatchKind.opportunity:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenOpportunityDetailScreen(item: item, intent: intent)));
        return;
      case AurenMatchKind.content:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenContentDetailScreen(item: item, intent: intent)));
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الوحدة لم تُربط بوجهتها الأصلية بعد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = _details();
    return Scaffold(
      appBar: AppBar(title: Text(_kindLabel(item.kind))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 28, child: Icon(_kindIcon(item.kind), size: 28)),
                  const SizedBox(height: 14),
                  Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  if (item.subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(item.subtitle),
                  ],
                  const SizedBox(height: 14),
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 6),
                    Text('مطابقة ${item.score}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ],
              ),
            ),
          ),
          if (intent.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(child: ListTile(leading: const Icon(Icons.search), title: const Text('طلبك'), subtitle: Text(intent))),
          ],
          if (item.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('لماذا ظهر لك؟', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...item.reasons.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('• '), Expanded(child: Text(reason)),
                    ]),
                  )),
                ]),
              ),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('التفاصيل', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...details.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(text: '${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: entry.value),
                      ],
                    )),
                  )),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _continue(context),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('متابعة'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../services/social/adaptive_profile_service.dart';
import '../../../services/social/match_everything_service.dart';
import 'auren_match_detail_screen.dart';

class AurenIntentMatchCard extends StatefulWidget {
  final String uid;
  const AurenIntentMatchCard({super.key, required this.uid});

  @override
  State<AurenIntentMatchCard> createState() => _AurenIntentMatchCardState();
}

class _AurenIntentMatchCardState extends State<AurenIntentMatchCard> {
  final _controller = TextEditingController();
  final _service = AurenMatchEverythingService();
  bool _loading = false;
  String _intent = '';
  List<AurenMatchItem> _items = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search([String? value]) async {
    final intent = (value ?? _controller.text).trim();
    if (intent.isEmpty) return;
    _controller.text = intent;
    _controller.selection = TextSelection.collapsed(offset: intent.length);
    setState(() { _intent = intent; _loading = true; });
    try {
      final results = await _service.findMatches(
        uid: widget.uid,
        context: AurenProfileContext.unknown,
        intent: intent,
        limitPerKind: 4,
      );

      final normalized = intent.toLowerCase();
      final supplierIntent = [
        'مورد', 'توريد', 'مصنع', 'مصانع', 'جملة', 'شراء', 'اشترى',
        'supplier', 'factory', 'manufacturer', 'wholesale', 'sourcing', 'rfq',
      ].any(normalized.contains);

      var merged = results;
      if (supplierIntent) {
        try {
          final intelligence = await _service.findSupplierIntelligence(
            query: intent,
            limit: 8,
          );
          final existing = <String>{
            ...results.map((item) => '\${item.kind.name}:\${item.id}'),
          };
          merged = [
            ...intelligence.where(
              (item) => existing.add('\${item.kind.name}:\${item.id}'),
            ),
            ...results,
          ];
          merged.sort((a, b) => b.score.compareTo(a.score));
        } catch (_) {
          // Keep the normal Match Everything results if the intelligence
          // service is unavailable.
        }
      }

      if (!mounted) return;
      setState(() {
        _items = merged.take(12).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _items = const []; _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر البحث الآن. حاول مرة أخرى.')),
      );
    }
  }

  String _kindLabel(AurenMatchKind kind) {
    switch (kind) {
      case AurenMatchKind.person: return 'شخص';
      case AurenMatchKind.opportunity: return 'فرصة';
      case AurenMatchKind.business: return 'Business';
      case AurenMatchKind.product: return 'منتج';
      case AurenMatchKind.content: return 'محتوى';
    }
  }

  Future<void> _openMatch(AurenMatchItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AurenMatchDetailScreen(item: item, intent: _intent),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Tell AUREN what you need',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text('اكتب طلبك مباشرة، وAUREN يبحث لك في الأشخاص والفرص والشركات والمنتجات والمحتوى.'),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'مثلاً: أبحث عن مورد ملابس في أفريقيا',
                prefixIcon: const Icon(Icons.auto_awesome),
                suffixIcon: IconButton(
                  tooltip: 'Match Everything',
                  onPressed: _loading ? null : _search,
                  icon: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['عايز أفتح مطعم', 'أبحث عن مورد ملابس', 'أريد أتعلم Flutter']
                .map((example) => ActionChip(
                  label: Text(example),
                  onPressed: _loading ? null : () => _search(example),
                )).toList(),
            ),
            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (!_loading && _intent.isNotEmpty && _items.isEmpty) ...[
              const SizedBox(height: 12),
              const Text('ما لقينا نتائج مطابقة حالياً. جرّب صياغة مختلفة أو أضف تفاصيل أكثر.'),
            ],
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Match Everything',
                  style: TextStyle(fontWeight: FontWeight.w800))),
                Text('${_items.length} نتائج'),
              ]),
              const SizedBox(height: 4),
              ..._items.take(5).map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _openMatch(item),
                trailing: Chip(label: Text(item.actionLabel)),
                leading: CircleAvatar(child: Icon(_kindIcon(item.kind), size: 20)),
                title: Row(children: [
                  Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Text('${item.score}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                subtitle: Text(
                  '${_kindLabel(item.kind)} • ${item.reasons.join(' • ')}',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

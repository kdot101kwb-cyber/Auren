import 'package:flutter/material.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/social/match_everything_service.dart';
import '../../../services/social/follow_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/marketplace/marketplace_commerce_repository.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import '../../../services/business/business_repository.dart';
import '../../../services/opportunities/opportunity_repository.dart';
import '../../../core/models/business.dart';
import '../../../core/models/product.dart';
import '../../../core/models/opportunity.dart';
import '../../business/presentation/business_detail_screen.dart';
import '../../marketplace/presentation/product_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'auren_opportunity_detail_screen.dart';
import 'auren_content_detail_screen.dart';

class AurenMatchDetailScreen extends StatefulWidget {
  final AurenMatchItem item;
  final String intent;
  const AurenMatchDetailScreen({super.key, required this.item, required this.intent});
  @override State<AurenMatchDetailScreen> createState() => _AurenMatchDetailScreenState();
}

class _AurenMatchDetailScreenState extends State<AurenMatchDetailScreen> {
  final _auth = FirebaseAurenAuthService();
  final _follow = FollowRepository();
  final _conversations = ConversationRepository();
  final _commerce = MarketplaceCommerceRepository();
  final _marketplace = MarketplaceRepository();
  final _businesses = BusinessRepository();
  final _opportunities = OpportunityRepository();
  bool _busy = false;
  bool _interested = false;
  bool _applied = false;

  String _ownerId() => (widget.item.data['ownerId'] ?? widget.item.data['authorId'] ?? widget.item.data['uid'] ?? widget.item.data['creatorId'] ?? '').toString();

  Future<void> _contact({String? prompt}) async {
    final uid = _auth.currentUserId;
    final otherUid = _ownerId().isNotEmpty ? _ownerId() : widget.item.id;
    if (uid == null || otherUid.isEmpty || uid == otherUid) throw StateError('لا يمكن بدء محادثة مع هذا الحساب.');
    final conversation = await _conversations.getOrCreateDirectConversation(uid: uid, otherUid: otherUid, otherTitle: widget.item.title);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: conversation.id, initialPrompt: prompt)));
  }

  Future<void> _apply(String uid) async {
    if (widget.item.kind != AurenMatchKind.opportunity) { _openDestination(); return; }
    if (_applied || await _opportunities.hasApplied(uid, widget.item.id)) {
      if (mounted) setState(() => _applied = true);
      _toast('سبق أن تقدمت لهذه الفرصة.');
      return;
    }
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('التقديم على الفرصة'),
        content: TextField(controller: note, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'رسالة قصيرة لصاحب الفرصة (اختياري)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تأكيد التقديم')),
        ],
      ),
    );
    final clean = note.text.trim();
    note.dispose();
    if (confirmed != true) return;
    final opportunity = AurenOpportunity.fromMap(widget.item.id, widget.item.data);
    await _opportunities.apply(uid: uid, opportunity: opportunity, note: clean);
    if (mounted) setState(() => _applied = true);
    _toast('تم إرسال التقديم بنجاح.');
  }

  Future<void> _execute() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final uid = _auth.currentUserId;
      if (uid == null) throw StateError('سجّل الدخول أولاً.');
      switch (widget.item.action) {
        case AurenMatchAction.contact:
          await _contact();
          break;
        case AurenMatchAction.requestQuote:
          await _contact(prompt: 'مرحباً، وصلت إليكم عبر AUREN. أريد طلب عرض سعر بخصوص: ${widget.intent}. أرسلوا لي السعر، الحد الأدنى للطلب، العملة، مدة التجهيز، وخيارات الشحن إن وجدت.');
          break;
        case AurenMatchAction.addToCart:
          await _commerce.addToCart(uid: uid, productId: widget.item.id, quantity: 1);
          _toast('تمت إضافة المنتج إلى السلة.');
          break;
        case AurenMatchAction.follow:
          if (widget.item.kind == AurenMatchKind.opportunity) {
            final old = _interested;
            await _opportunities.toggleInterest(uid: uid, opportunityId: widget.item.id, interested: old, snapshot: widget.item.data);
            if (mounted) setState(() => _interested = !old);
            _toast(old ? 'تم إلغاء متابعة الفرصة.' : 'تم حفظ الفرصة في اهتماماتك.');
          } else {
            final following = await _follow.watchFollowing(uid, widget.item.id).first;
            await _follow.toggle(uid, widget.item.id, following);
            _toast(following ? 'تم إلغاء المتابعة.' : 'تمت المتابعة.');
          }
          break;
        case AurenMatchAction.apply:
          await _apply(uid);
          break;
        case AurenMatchAction.watch:
        case AurenMatchAction.open:
          _openDestination();
          break;
        case AurenMatchAction.save:
          if (widget.item.kind == AurenMatchKind.product) {
            final saved = await _marketplace.watchSavedIds(uid).first;
            await _marketplace.toggleSaved(uid, widget.item.id, saved.contains(widget.item.id));
            _toast(saved.contains(widget.item.id) ? 'تم إلغاء الحفظ.' : 'تم حفظ المنتج.');
          } else if (widget.item.kind == AurenMatchKind.business) {
            await _businesses.toggleSaved(uid, widget.item.id);
            _toast('تم تحديث حفظ النشاط.');
          } else {
            _openDestination();
          }
          break;
      }
    } catch (e) {
      if (mounted) _toast('تعذر تنفيذ الإجراء: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDestination() {
    switch (widget.item.kind) {
      case AurenMatchKind.person:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenProfileScreen(userId: _ownerId().isEmpty ? widget.item.id : _ownerId())));
        break;
      case AurenMatchKind.business:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenBusinessDetailScreen(business: AurenBusiness.fromMap(widget.item.id, widget.item.data))));
        break;
      case AurenMatchKind.product:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenProductDetailScreen(product: AurenProduct.fromMap(widget.item.id, widget.item.data))));
        break;
      case AurenMatchKind.opportunity:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenOpportunityDetailScreen(item: widget.item, intent: widget.intent)));
        break;
      case AurenMatchKind.content:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenContentDetailScreen(item: widget.item, intent: widget.intent)));
        break;
    }
  }

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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

  List<MapEntry<String,String>> _details() {
    const keys = ['category','type','location','country','city','price','currency','description','text','headline'];
    final out = <MapEntry<String,String>>[];
    for (final key in keys) {
      final value = widget.item.data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') out.add(MapEntry(key,value));
    }
    return out;
  }

  @override Widget build(BuildContext context) {
    final item = widget.item;
    final details = _details();
    return Scaffold(
      appBar: AppBar(title: Text(_kindLabel(item.kind))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 28, child: Icon(_kindIcon(item.kind), size: 28)),
            const SizedBox(height: 14),
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (item.subtitle.trim().isNotEmpty) ...[const SizedBox(height: 8), Text(item.subtitle)],
            const SizedBox(height: 14),
            Row(children: [const Icon(Icons.auto_awesome, size: 18), const SizedBox(width: 6), Text('مطابقة ${item.score}%', style: const TextStyle(fontWeight: FontWeight.w800))]),
          ]))),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.route_outlined)),
            title: const Text('الخطوة التي فهمها AUREN', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(item.actionReason),
            trailing: Chip(label: Text(_applied ? 'تم التقديم' : item.actionLabel)),
          )),
          if (widget.intent.trim().isNotEmpty) ...[const SizedBox(height: 12), Card(child: ListTile(leading: const Icon(Icons.search), title: const Text('طلبك'), subtitle: Text(widget.intent)))],
          if (item.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('لماذا ظهر لك؟', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...item.reasons.map((reason) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• '), Expanded(child: Text(reason))]))),
            ]))),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('التفاصيل', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...details.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8), child: RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [
                TextSpan(text: '${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: entry.value),
              ])))),
            ]))),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _execute,
            icon: _busy ? const SizedBox(width: 18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : Icon(item.action == AurenMatchAction.apply ? Icons.send : Icons.arrow_forward),
            label: Text(_applied ? 'تم التقديم' : item.actionLabel),
          ),
          TextButton.icon(onPressed: _busy ? null : _openDestination, icon: const Icon(Icons.open_in_new), label: const Text('فتح التفاصيل')),
        ],
      ),
    );
  }
}

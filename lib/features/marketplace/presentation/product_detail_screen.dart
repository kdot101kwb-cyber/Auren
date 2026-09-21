import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/product.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import '../../../services/marketplace/marketplace_commerce_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../business/presentation/business_detail_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenProductDetailScreen extends StatefulWidget {
  final AurenProduct product;
  const AurenProductDetailScreen({super.key, required this.product});
  @override State<AurenProductDetailScreen> createState() => _AurenProductDetailScreenState();
}
class _AurenProductDetailScreenState extends State<AurenProductDetailScreen> {
  final repo = MarketplaceRepository();
  final businessRepo = BusinessRepository();
  final commerce = MarketplaceCommerceRepository();
  @override void initState() { super.initState(); final uid = FirebaseAuth.instance.currentUser?.uid; if (uid != null) { repo.recordEvent(productId: widget.product.id, viewerUid: uid, type: 'view'); } }
  Future<void> _report() async {
    final reason = await showDialog<String>(context: context, builder: (d) => SimpleDialog(
      title: const Text('الإبلاغ عن الإعلان'),
      children: ['معلومات مضللة','احتيال أو خداع','محتوى غير مناسب','منتج أو خدمة غير قانونية','أخرى']
          .map((x) => SimpleDialogOption(onPressed: () => Navigator.pop(d, x), child: Text(x))).toList()));
    if (reason == null || !mounted) return;
    try {
      await repo.report(productId: widget.product.id, reporterUid: FirebaseAuth.instance.currentUser!.uid, reason: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال البلاغ: $e'))); }
  }
  Future<void> _contact() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.product.ownerId.isEmpty) return;
    try {
      await repo.recordEvent(productId: widget.product.id, viewerUid: uid, type: 'message');
      final conv = await ConversationRepository().getOrCreateDirectConversation(uid: uid, otherUid: widget.product.ownerId, otherTitle: widget.product.name);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: conv.id, initialPrompt: 'مرحباً، أريد الاستفسار عن ${widget.product.name}.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر فتح المحادثة: $e'))); }
  }
  @override Widget build(BuildContext context) {
    final p = widget.product; final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(p.service ? 'Service' : 'Product'), actions: [if (uid != null) IconButton(onPressed: () async { await Clipboard.setData(ClipboardData(text: 'https://auren.app/marketplace/product/${p.id}')); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط المنتج'))); }, icon: const Icon(Icons.share_outlined)), if (uid != null) IconButton(onPressed: _report, icon: const Icon(Icons.flag_outlined))]),
      body: ListView(children: [
        if (p.imageUrl.isNotEmpty) AspectRatio(aspectRatio: 1.15, child: Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 48)))),
        Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))), Chip(label: Text(p.service ? 'خدمة' : 'منتج'))]),
          const SizedBox(height: 10), Text('${(p.priceMinor / 100).toStringAsFixed(2)} ${p.currency}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14), Text(p.description.isEmpty ? 'لا يوجد وصف.' : p.description), const SizedBox(height: 20),
          StreamBuilder<AurenBusiness?>(stream: businessRepo.watchById(p.businessId), builder: (context, s) {
            final b = s.data; if (b == null) return const SizedBox.shrink();
            return Card(child: ListTile(leading: CircleAvatar(backgroundImage: b.imageUrl.isNotEmpty ? NetworkImage(b.imageUrl) : null, child: b.imageUrl.isEmpty ? const Icon(Icons.storefront_outlined) : null),
              title: Row(children: [Flexible(child: Text(b.name)), if (b.verified) const Icon(Icons.verified, size: 18)]),
              subtitle: Text([b.businessType, b.city, b.country].where((x) => x.isNotEmpty).join(' • ')),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenBusinessDetailScreen(business: b)))));
          }),
          const SizedBox(height: 20),
          Column(children: [
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: uid == null ? null : _contact, icon: const Icon(Icons.chat_outlined), label: const Text('تواصل مع البائع'))),
              const SizedBox(width: 10),
              IconButton(onPressed: uid == null ? null : () async { await commerce.addToCart(uid: uid!, productId: p.id, quantity: 1); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة للسلة'))); }, icon: const Icon(Icons.add_shopping_cart_outlined)),
            ]),
            const SizedBox(width: 10),
            IconButton(onPressed: uid == null ? null : () async { await commerce.addToCart(uid: uid!, productId: p.id, quantity: 1); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة للسلة'))); }, icon: const Icon(Icons.bookmark_add_outlined)),
          ]),
          const SizedBox(height: 20),
          StreamBuilder<List<Map<String,dynamic>>>(stream: commerce.watchReviews(p.id), builder: (context,s) { final rs=s.data??[]; final avg=rs.isEmpty?0.0:rs.map((x)=>(x['rating'] as num?)?.toDouble()??0).reduce((a,b)=>a+b)/rs.length; return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('⭐ ${avg.toStringAsFixed(1)}  (${rs.length})'),if(uid!=null) TextButton(onPressed:() async { int rating=5; final ctl=TextEditingController(); final ok=await showDialog<bool>(context:context,builder:(d)=>StatefulBuilder(builder:(d,setD)=>AlertDialog(title:const Text('تقييم المنتج'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<int>(value:rating,items:[1,2,3,4,5].map((x)=>DropdownMenuItem(value:x,child:Text('$x نجوم'))).toList(),onChanged:(v)=>setD(()=>rating=v!)),TextField(controller:ctl,maxLines:3,decoration:const InputDecoration(labelText:'تعليق'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حفظ'))])));if(ok==true)await commerce.review(productId:p.id,userId:uid!,rating:rating,text:ctl.text);ctl.dispose();},child:const Text('أضف تقييمك')), ...rs.take(5).map((x)=>ListTile(contentPadding:EdgeInsets.zero,title:Text('★'*((x['rating'] as num?)?.toInt()??0)),subtitle:Text(x['text']?.toString()??'')))])));}),
        ])),
      ]),
    );
  }
}

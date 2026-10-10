import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import 'business_detail_screen.dart';
import 'saved_businesses_screen.dart';
import 'supplier_requests_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
class AurenBusinessScreen extends StatefulWidget{const AurenBusinessScreen({super.key});@override State<AurenBusinessScreen> createState()=>_AurenBusinessScreenState();}
class _AurenBusinessScreenState extends State<AurenBusinessScreen>{
 final _repo=BusinessRepository(); final _search=TextEditingController(); String _category='All'; String _type='All';
 static const types=['All','Company','Store','Restaurant','Freelancer','Service Provider','Factory','Farm','Creator Business','NGO/Organization'];
 static const cats=['All','Retail','Food','Services','Technology','Manufacturing','Education','Travel','Creative','Agriculture','Other'];
 @override void dispose(){_search.dispose();super.dispose();}
 void _create(){if(FirebaseAuth.instance.currentUser==null)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenBusinessCreateScreen()));}
 Widget _chips(List<String> values, String selected, ValueChanged<String> onSelected) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: values.map((v) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(v), selected: selected == v, onSelected: (_) => onSelected(v)))).toList()));
 @override
 Widget build(BuildContext context) {
   final uid = FirebaseAuth.instance.currentUser?.uid;
   return Scaffold(
     appBar: AppBar(title: const Text('Business'), actions: [
       IconButton(tooltip: 'طلبات الموردين', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierRequestsScreen())), icon: const Icon(Icons.request_quote_outlined)),
       IconButton(onPressed: _create, icon: const Icon(Icons.add_business_outlined)),
       IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSavedBusinessesScreen())), icon: const Icon(Icons.bookmarks_outlined)),
       IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'حلّل احتياجي واقترح لي شركات ومتاجر وخدمات مناسبة.'))), icon: const Icon(Icons.auto_awesome)),
     ]),
     body: Column(children: [
       Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'ابحث عن شركة، متجر أو خدمة...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
       _chips(types, _type, (v) => setState(() => _type = v)),
       _chips(cats, _category, (v) => setState(() => _category = v)),
       Expanded(child: ListView(children: [
         if (uid != null) ...[
           AurenAdaptiveProfileSurface(uid: uid, context: AurenProfileContext.business, intent: _search.text.isEmpty ? 'العملاء والمنتجات ونمو النشاط' : 'البحث عن ' + _search.text),
           AurenAdaptiveActionRail(uid: uid, context: AurenProfileContext.business, intent: _search.text.isEmpty ? 'العملاء والمنتجات ونمو النشاط' : _search.text, onPrompt: (prompt) => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)))),
           const SizedBox(height: 8),
         ],
         StreamBuilder<List<AurenBusiness>>(
           stream: _repo.watchPublic(query: _search.text, category: _category, businessType: _type),
           builder: (context, s) {
             if (s.hasError) return Center(child: Text('حدث خطأ: ' + s.error.toString()));
             if (!s.hasData) return const Center(child: CircularProgressIndicator());
             final items = s.data!;
             if (items.isEmpty) return const Center(child: Text('لا توجد نتائج بعد.'));
             return ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _Card(b: items[i]));
           },
         ),
       ])),
     ]),
     floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('أضف Business')),
   );
 }
}
class _Card extends StatelessWidget{final AurenBusiness b;const _Card({required this.b});@override Widget build(BuildContext c)=>Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AurenBusinessDetailScreen(business:b))),leading:CircleAvatar(backgroundImage:b.imageUrl.isEmpty?null:NetworkImage(b.imageUrl),child:b.imageUrl.isEmpty?const Icon(Icons.storefront_outlined):null),title:Row(children:[Expanded(child:Text(b.name,maxLines:1,overflow:TextOverflow.ellipsis)),if(b.verified)const Icon(Icons.verified,size:17)]),subtitle:Text([b.category,b.city,b.country,b.description].where((x)=>x.isNotEmpty).join(' • ')),trailing:const Icon(Icons.chevron_right)));}

class AurenBusinessCreateScreen extends StatefulWidget {
  const AurenBusinessCreateScreen({super.key});

  @override
  State<AurenBusinessCreateScreen> createState() => _AurenBusinessCreateScreenState();
}

class _AurenBusinessCreateScreenState extends State<AurenBusinessCreateScreen> {
  final form = GlobalKey<FormState>();
  final n = TextEditingController();
  final d = TextEditingController();
  final city = TextEditingController();
  final country = TextEditingController();
  final phone = TextEditingController();
  final web = TextEditingController();
  final img = TextEditingController();

  String cat = 'Services';
  String type = 'Company';
  bool saving = false;

  static const types = [
    'Company',
    'Store',
    'Restaurant',
    'Freelancer',
    'Service Provider',
    'Factory',
    'Farm',
    'Creator Business',
    'NGO/Organization',
  ];

  static const cats = [
    'Retail',
    'Food',
    'Services',
    'Technology',
    'Manufacturing',
    'Education',
    'Travel',
    'Creative',
    'Agriculture',
    'Other',
  ];

  @override
  void dispose() {
    for (final controller in [n, d, city, country, phone, web, img]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => saving = true);
    try {
      await BusinessRepository().create(
        ownerId: uid,
        name: n.text,
        description: d.text,
        category: cat,
        city: city.text,
        country: country.text,
        phone: phone.text,
        website: web.text,
        imageUrl: img.text,
        businessType: type,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget f(
    TextEditingController controller,
    String label, {
    bool required = false,
    int lines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) =>
              value == null || value.trim().isEmpty ? 'مطلوب' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Business')),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            f(n, 'اسم النشاط', required: true),
            f(d, 'وصف النشاط', lines: 4),
            DropdownButtonFormField<String>(
              initialValue: cat,
              items: cats
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => cat = value);
              },
              decoration: const InputDecoration(labelText: 'التصنيف'),
            ),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: types
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => type = value);
              },
              decoration: const InputDecoration(labelText: 'نوع النشاط'),
            ),
            f(city, 'المدينة'),
            f(country, 'الدولة'),
            f(phone, 'الهاتف'),
            f(web, 'الموقع الإلكتروني'),
            f(img, 'رابط صورة/شعار'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'جاري الحفظ...' : 'إنشاء النشاط'),
            ),
          ],
        ),
      ),
    );
  }
}

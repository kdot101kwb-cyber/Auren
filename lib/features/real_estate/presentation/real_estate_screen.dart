import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../core/models/property.dart';
import '../../../services/real_estate/auren_real_estate_service.dart';

class AurenRealEstateScreen extends StatefulWidget{const AurenRealEstateScreen({super.key});@override State<AurenRealEstateScreen> createState()=>_AurenRealEstateScreenState();}
class _AurenRealEstateScreenState extends State<AurenRealEstateScreen>{
  final repo=AurenRealEstateService(); final q=TextEditingController(); final city=TextEditingController(); String listing='All',type='All';
  static const types=['All','Apartment','House','Villa','Office','Shop','Land','Warehouse'];
  @override void dispose(){q.dispose();city.dispose();super.dispose();}
  void _publish()async{
    final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;
    final title=TextEditingController(),desc=TextEditingController(),c=TextEditingController(text:'Sudan'),ct=TextEditingController(),price=TextEditingController(),area=TextEditingController();
    String t='Apartment',lt='sale';
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('إضافة عقار'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),TextField(controller:desc,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:ct,decoration:const InputDecoration(labelText:'المدينة')),TextField(controller:c,decoration:const InputDecoration(labelText:'الدولة')),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),TextField(controller:area,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المساحة m²')),
      DropdownButtonFormField<String>(initialValue:t,items:types.where((x)=>x!='All').map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>t=v??t),DropdownButtonFormField<String>(initialValue:lt,items:const [DropdownMenuItem(value:'sale',child:Text('بيع')),DropdownMenuItem(value:'rent',child:Text('إيجار'))],onChanged:(v)=>lt=v??lt)
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('نشر'))]))??false;
    if(!ok)return; await repo.publish(ownerId:uid,title:title.text,description:desc.text,city:ct.text,country:c.text,type:t,listingType:lt,currency:'USD',priceMinor:(int.tryParse(price.text)??0)*100,bedrooms:0,bathrooms:0,areaSqm:int.tryParse(area.text)??0,imageUrl:'');
  }
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Real Estate'),
        actions: [
          IconButton(onPressed: uid == null ? null : _publish, icon: const Icon(Icons.add_business_outlined)),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'ساعدني أبحث وأقارن عقارات مناسبة لاحتياجي.')),
            ),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن عقار...', border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(child: TextField(controller: city, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'المدينة/الدولة', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: listing,
                    decoration: const InputDecoration(labelText: 'النوع'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('الكل')),
                      DropdownMenuItem(value: 'sale', child: Text('بيع')),
                      DropdownMenuItem(value: 'rent', child: Text('إيجار')),
                    ],
                    onChanged: (v) => setState(() => listing = v ?? 'All'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(types[i]),
                selected: type == types[i],
                onSelected: (_) => setState(() => type = types[i]),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: uid == null ? const Stream<Set<String>>.empty() : repo.watchSavedIds(uid),
              builder: (context, saved) {
                final ids = saved.data ?? <String>{};
                return StreamBuilder<List<AurenProperty>>(
                  stream: repo.watchPublic(query: q.text, city: city.text, listingType: listing, type: type),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final properties = snapshot.data!;
                    if (properties.isEmpty) return const Center(child: Text('لا توجد عقارات مطابقة.'));
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: properties.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = properties[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Icon(p.listingType == 'rent' ? Icons.key_outlined : Icons.home_outlined)),
                            title: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${(p.priceMinor / 100).toStringAsFixed(0)} ${p.currency} • ${p.areaSqm} m² • ${p.city}'),
                            trailing: IconButton(
                              icon: Icon(ids.contains(p.id) ? Icons.bookmark : Icons.bookmark_border),
                              onPressed: uid == null ? null : () => repo.toggleSaved(uid, p.id),
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PropertyDetail(p: p))),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

class _PropertyDetail extends StatelessWidget{final AurenProperty p;const _PropertyDetail({required this.p});
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('العقار')),body:ListView(padding:const EdgeInsets.all(16),children:[Text(p.title,style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:8),Text('${(p.priceMinor/100).toStringAsFixed(0)} ${p.currency}',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:12),Wrap(spacing:8,children:[Chip(label:Text(p.listingType=='rent'?'إيجار':'بيع')),Chip(label:Text(p.type)),Chip(label:Text('${p.areaSqm} m²')),if(p.verified)const Chip(label:Text('Verified'))]),const SizedBox(height:12),Text(p.description),const SizedBox(height:20),FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'أريد التواصل بخصوص العقار: ${p.title}'))),icon:const Icon(Icons.chat_outlined),label:const Text('تواصل عبر Messenger'))]));}
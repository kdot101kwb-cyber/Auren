import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_repository.dart';
import '../../../core/models/talent.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'talent_agents_screen.dart';
import 'talent_scouts_screen.dart';
class AurenTalentScreen extends StatefulWidget{const AurenTalentScreen({super.key});@override State<AurenTalentScreen> createState()=>_AurenTalentScreenState();}
class _AurenTalentScreenState extends State<AurenTalentScreen>{final repo=TalentRepository();final search=TextEditingController();String skill='';
@override void dispose(){search.dispose();super.dispose();}
@override Widget build(BuildContext c){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لاكتشاف المواهب.')));return Scaffold(appBar:AppBar(title:const Text('AUREN Talent'),actions:[IconButton(icon:const Icon(Icons.radar),tooltip:'Talent Scouts',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentScoutsScreen()))),IconButton(icon:const Icon(Icons.psychology_outlined),tooltip:'Talent Agents',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentAgentsScreen()))),IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'حلّل مهاراتي وأهدافي واقترح كيف أطور ملفي المهني والفرص المناسبة لي.'))))]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_create(c,uid),icon:const Icon(Icons.add),label:const Text('أنشئ ملف موهبة')),body:Column(children:[Padding(padding:const EdgeInsets.all(16),child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن موهبة أو مهارة...',border:OutlineInputBorder()))),AurenAdaptiveProfileSurface(uid:uid,context:AurenProfileContext.work,intent:'المواهب والمهارات والفرص المهنية'),
AurenAdaptiveActionRail(uid:uid,context:AurenProfileContext.work,intent:'المواهب والمهارات والفرص المهنية',onPrompt:(prompt)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt)))),
const SizedBox(height:8),
Expanded(child:StreamBuilder<List<AurenTalent>>(stream:repo.watchPublic(query:search.text,skill:skill),builder:(c,s){if(s.hasError)return Center(child:Text('تعذر تحميل المواهب: '+s.error.toString()));if(!s.hasData)return const Center(child:CircularProgressIndicator());final list=s.data!;if(list.isEmpty)return const Center(child:Text('لا توجد مواهب مطابقة.'));return ListView.separated(padding:const EdgeInsets.all(16),itemCount:list.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i)=>_card(c,list[i]));}))]));}
Widget _card(BuildContext c, AurenTalent t) {
  return Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_search)),
      title: Text(t.displayName),
      subtitle: Text([t.category, t.city, t.country].where((x) => x.isNotEmpty).join(' • ')),
      onTap: () => showModalBottomSheet(
        context: c,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(t.bio),
              if (t.skills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(spacing: 6, children: t.skills.map((x) => Chip(label: Text(x))).toList()),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => MessengerScreen(
                      initialPrompt: 'ساعدني أتواصل مع هذه الموهبة: ${t.displayName}\nالمهارات: ${t.skills.join(', ')}',
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Connect'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
Future<void> _create(BuildContext c,String uid)async{final n=TextEditingController(),b=TextEditingController(),s=TextEditingController(),city=TextEditingController(),country=TextEditingController();final ok=await showDialog<bool>(context:c,builder:(ctx)=>AlertDialog(title:const Text('ملف موهبة'),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:b,maxLines:4,decoration:const InputDecoration(labelText:'نبذة')),TextField(controller:s,decoration:const InputDecoration(labelText:'Skills, comma separated')),TextField(controller:city,decoration:const InputDecoration(labelText:'المدينة')),TextField(controller:country,decoration:const InputDecoration(labelText:'الدولة'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]));if(ok==true&&n.text.trim().isNotEmpty)await repo.save(ownerId:uid,displayName:n.text,bio:b.text,category:'General',city:city.text,country:country.text,skills:s.text.split(','));for(final x in[n,b,s,city,country])x.dispose();}
}
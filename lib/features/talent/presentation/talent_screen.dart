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
@override Widget build(BuildContext c){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لاكتشاف المواهب.')));return Scaffold(appBar:AppBar(title:const Text('AUREN Talent & Sports'),actions:[IconButton(icon:const Icon(Icons.radar),tooltip:'Talent Scouts',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentScoutsScreen()))),IconButton(icon:const Icon(Icons.psychology_outlined),tooltip:'Talent Agents',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentAgentsScreen()))),IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'حلّل أدائي الرياضي أو مهاراتي وأهدافي واقترح كيف أطور ملفي والفرص المناسبة لي.')))),IconButton(icon:const Icon(Icons.calculate_outlined),tooltip:'Performance Tools',onPressed:()=>_tools(c))]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_create(c,uid),icon:const Icon(Icons.add),label:const Text('أنشئ ملف موهبة')),body:Column(children:[Padding(padding:const EdgeInsets.all(16),child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن موهبة، رياضة أو مهارة...',border:OutlineInputBorder()))),AurenAdaptiveProfileSurface(uid:uid,context:AurenProfileContext.work,intent:'المواهب والمهارات والفرص المهنية'),
AurenAdaptiveActionRail(uid:uid,context:AurenProfileContext.work,intent:'المواهب والمهارات والفرص المهنية',onPrompt:(prompt)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt)))),
const SizedBox(height:8),
Expanded(child:StreamBuilder<List<AurenTalent>>(stream:repo.watchPublic(query:search.text,skill:skill),builder:(c,s){if(s.hasError)return Center(child:Text('تعذر تحميل المواهب: '+s.error.toString()));if(!s.hasData)return const Center(child:CircularProgressIndicator());final list=s.data!;if(list.isEmpty)return const Center(child:Text('لا توجد مواهب مطابقة.'));return ListView.separated(padding:const EdgeInsets.all(16),itemCount:list.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i)=>_card(c,list[i]));}))]));}
void _tools(BuildContext c){showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>_PerformanceTools(onOpen:(tool)=>_openTool(c,tool)));}
Future<void> _openTool(BuildContext c,String tool)async{Navigator.pop(c);if(tool=='load'){final m=await _two(c,'مدة التدريب بالدقائق','RPE من 1 إلى 10');if(m!=null)_result(c,'حمل التدريب',(m[0]*m[1]).toStringAsFixed(1)+' وحدة');}else if(tool=='pace'){final m=await _two(c,'المسافة بالكيلومتر','الزمن بالدقائق');if(m!=null&&m[0]>0)_result(c,'الوتيرة',(m[1]/m[0]).toStringAsFixed(2)+' دقيقة/كم');}else if(tool=='speed'){final m=await _two(c,'المسافة بالكيلومتر','الزمن بالساعات');if(m!=null&&m[1]>0)_result(c,'السرعة',(m[0]/m[1]).toStringAsFixed(2)+' كم/ساعة');}else{final m=await _two(c,'المحاولات الناجحة','إجمالي المحاولات');if(m!=null&&m[1]>0)_result(c,'نسبة النجاح',(m[0]/m[1]*100).toStringAsFixed(1)+'%');}}
Future<List<double>?> _two(BuildContext c,String a,String b)async{final x=TextEditingController(),y=TextEditingController();final ok=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('أداة أداء رياضي'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:x,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:a)),TextField(controller:y,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:b))]),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('احسب'))]));final a1=double.tryParse(x.text),b1=double.tryParse(y.text);x.dispose();y.dispose();return ok==true&&a1!=null&&b1!=null?[a1,b1]:null;}
void _result(BuildContext c,String title,String value){showDialog(context:c,builder:(_)=>AlertDialog(title:Text(title),content:Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق'))]));}
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
Future<void> _create(BuildContext c,String uid)async{final n=TextEditingController(),b=TextEditingController(),s=TextEditingController(),city=TextEditingController(),country=TextEditingController(),sport=TextEditingController();final ok=await showDialog<bool>(context:c,builder:(ctx)=>AlertDialog(title:const Text('ملف موهبة'),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:b,maxLines:4,decoration:const InputDecoration(labelText:'نبذة')),TextField(controller:s,decoration:const InputDecoration(labelText:'Skills, comma separated')),TextField(controller:sport,decoration:const InputDecoration(labelText:'الرياضة / المجال (اختياري)')),TextField(controller:city,decoration:const InputDecoration(labelText:'المدينة')),TextField(controller:country,decoration:const InputDecoration(labelText:'الدولة'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]));if(ok==true&&n.text.trim().isNotEmpty)await repo.save(ownerId:uid,displayName:n.text,bio:b.text,category:sport.text.trim().isEmpty?'General':sport.text.trim(),city:city.text,country:country.text,skills:s.text.split(','));for(final x in[n,b,s,city,country,sport])x.dispose();}
}
class _PerformanceTools extends StatelessWidget{
 final ValueChanged<String> onOpen; const _PerformanceTools({required this.onOpen});
 @override Widget build(BuildContext context)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(16,12,16,24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('أدوات الأداء الرياضي',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('حسابات تخطيطية بسيطة؛ لا تستبدل تقييم المدرب أو المختص.'),const SizedBox(height:12),_b('حمل التدريب','المدة × RPE',Icons.fitness_center,'load'),_b('الوتيرة','الزمن ÷ المسافة',Icons.speed,'pace'),_b('السرعة','المسافة ÷ الزمن',Icons.directions_run,'speed'),_b('نسبة النجاح','المحاولات الناجحة ÷ الإجمالي',Icons.analytics,'accuracy')])));
 Widget _b(String a,String b,IconData i,String id)=>ListTile(leading:CircleAvatar(child:Icon(i)),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(b),trailing:const Icon(Icons.chevron_right),onTap:()=>onOpen(id));
}

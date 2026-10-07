import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_repository.dart';
import '../../../services/talent/talent_sports_catalog.dart';
import '../../../services/talent/talent_categories.dart';
import '../../../core/models/talent.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'talent_agents_screen.dart';
import 'talent_scouts_screen.dart';
import 'talent_performance_screen.dart';
import 'talent_radar_screen.dart';
import 'talent_star_profile_screen.dart';
import 'talent_general_ai_tools.dart';
import 'music_talent_tools.dart';
import 'talent_specialized_tools.dart';
import 'talent_frontier_tools.dart';
import 'talent_feed.dart';
import 'discovery_missions.dart';
import 'talent_skill_graph.dart';
class AurenTalentScreen extends StatefulWidget{const AurenTalentScreen({super.key});@override State<AurenTalentScreen> createState()=>_AurenTalentScreenState();}
class _AurenTalentScreenState extends State<AurenTalentScreen>{final repo=TalentRepository();final search=TextEditingController();String skill='';String selectedSport='';bool evidenceOnly=false;
static const sports=TalentSportsCatalog.all;
@override void dispose(){search.dispose();super.dispose();}
@override Widget build(BuildContext c){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لاكتشاف المواهب.')));return Scaffold(appBar:AppBar(title:const Text('AUREN Talent'),actions:[IconButton(icon:const Icon(Icons.radar),tooltip:'Talent Scouts',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentScoutsScreen()))),IconButton(icon:const Icon(Icons.track_changes),tooltip:'Talent Radar',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentRadarScreen()))),IconButton(icon:const Icon(Icons.psychology_outlined),tooltip:'Talent Agents',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentAgentsScreen()))),IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'حلّل موهبتي ومهاراتي وأهدافي واقترح كيف أطور ملفي والفرص المناسبة لي.')))),IconButton(icon:const Icon(Icons.insights_outlined),tooltip:'تحليل الأداء',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AurenTalentPerformanceScreen()))),IconButton(icon:const Icon(Icons.calculate_outlined),tooltip:'Performance Tools',onPressed:()=>_tools(c))]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_create(c,uid),icon:const Icon(Icons.add),label:const Text('أنشئ ملف موهبة')),body:ListView(children:[Padding(padding:const EdgeInsets.all(16),child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن موهبة أو مهارة...',border:OutlineInputBorder()))),AurenAdaptiveProfileSurface(uid:uid,context:AurenProfileContext.work,intent:'المواهب والمهارات والتطوير والفرص'),
Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:AurenTalentFeed(uid:uid)),
Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:const AurenDiscoveryMissions()),
Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:const AurenTalentSkillGraph()),
Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('استكشف الرياضات',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:8),Wrap(spacing:6,runSpacing:6,children:[ActionChip(label:Text(selectedSport.isEmpty?'كل الرياضات':'إلغاء: $selectedSport'),onPressed:()=>setState(()=>selectedSport='')), ...sports.map((sport)=>FilterChip(label:Text(sport),selected:selectedSport==sport,onSelected:(selected)=>setState(()=>selectedSport=selected?sport:'')))]),const SizedBox(height:8),Text('اختيار الرياضة يفلتر المواهب؛ اضغط اسم الرياضة مجدداً من هنا أو استخدم البحث الذكي.',style:TextStyle(fontSize:12,color:Theme.of(c).colorScheme.onSurfaceVariant)),const SizedBox(height:8),FilterChip(label:const Text('لديها أدلة'),selected:evidenceOnly,onSelected:(v)=>setState(()=>evidenceOnly=v))])))),
AurenAdaptiveActionRail(uid:uid,context:AurenProfileContext.work,intent:'المواهب والمهارات والتطوير',onPrompt:(prompt)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt)))),
Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
const Text('ابتكارات الموهبة',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
const SizedBox(height:6),
const Text('أدوات AI لتحويل الموهبة من ملف ثابت إلى مسار تطوير وفرص.'),
const SizedBox(height:10),
ExpansionTile(
  tilePadding: EdgeInsets.zero,
  initiallyExpanded: false,
  leading: const Icon(Icons.auto_awesome),
  title: const Text('أدوات AI المتقدمة'),
  subtitle: const Text('افتح الأدوات عند الحاجة بدل عرض عشرات الخيارات دفعة واحدة.'),
  children: [
    Wrap(spacing: 6, runSpacing: 6, children: [_ActionChip('Opportunity Ready','قيّم جاهزيتي لفرصة أو نادٍ أو مشروع، وحدد ما ينقصني قبل التقديم.'),
_ActionChip('AI Coach Plan','ابنِ لي خطة تطوير أسبوعية حسب رياضتي أو مهارتي ووقتي ومستواي، مع مؤشرات متابعة واضحة.'),
_ActionChip('Personal Coach','افتح إعداد مدربي الشخصي من ملف موهبتي واختر AI Coach أو مدرباً بشرياً مع تحديد الرياضة والهدف والحصص الأسبوعية.'),
_ActionChip('Highlight Story','حوّل إنجازاتي وبيانات أدائي إلى قصة مختصرة مناسبة لعرضها على مدرب أو شركة أو جمهور.'),
_ActionChip('Team Match','اقترح نوع الفريق أو النادي أو الشريك الذي يناسب مهاراتي وأهدافي، مع سبب المطابقة.'),
                  _ActionChip('Club & Coach Match','افتح المطابقة مع فرص الأندية والمدربين والفرق الرياضية المفتوحة من ملف موهبتي.'),
_ActionChip('AI Scout Report','أنشئ تقرير كشف موهبة احترافي يختصر نقاط القوة والمهارات والأداء والفرص ومجالات التطوير.'),
_ActionChip('Competition Ready','قيّم جاهزيتي للمنافسة القادمة من خلال أهدافي وبيانات أدائي المسجلة، وأنشئ قائمة تحقق عملية قبل المنافسة.'),
_ActionChip('Coach Brief','أنشئ ملخصاً سريعاً لمدرب أو نادي يوضح من أنا، رياضتي، مهاراتي، إنجازاتي، أهدافي وما أحتاج إلى تطويره.'),
_ActionChip('Skill → Opportunity','اربط مهاراتي الحالية بأنواع فرص مناسبة، وحدد المهارات التي ستزيد فرصي إذا طورتها تالياً.'),_ActionChip('Performance Review','راجع سجلات أدائي المسجلة، استخرج أفضل المؤشرات والتغيرات الملحوظة، واقترح أسئلة أطرحها على المدرب.'),_ActionChip('Tryout Prep','جهزني لاختبار أداء أو تجربة أداء عبر قائمة تحضير وأسئلة متوقعة ونقاط أركز عليها.'),
_ActionChip('Scouting Profile','حوّل بياناتي إلى بطاقة كشف مختصرة يفهمها المدرب أو الكشاف بسرعة.'),
_ActionChip('Goal Roadmap','حوّل أهدافي الرياضية أو المهنية إلى خارطة طريق بمراحل ومؤشرات إنجاز واضحة.'),
_ActionChip('Strength Finder','استخرج نقاط قوتي المتكررة من ملفي وإنجازاتي وبيانات أدائي، واقترح كيف أستخدمها.'),_ActionChip('Media Kit','أنشئ Media Kit احترافي للموهبة يتضمن نبذة، إنجازات، أرقام الأداء، المهارات وفرص التعاون.'),
_ActionChip('Career Path','اقترح مسارات مهنية محتملة مرتبطة برياضتي ومهاراتي وأهدافي، مع خطوات البداية لكل مسار.'),
_ActionChip('Personal Benchmark','أنشئ خط أساس شخصياً من أفضل سجلات أدائي الحالية لأقيس تطوري مستقبلاً دون مقارنة غير عادلة بالآخرين.'),
_ActionChip('Opportunity Pitch','اكتب عرضاً قصيراً ومقنعاً أرسله لنادٍ أو مدرب أو شريك يوضح قيمتي وما أبحث عنه.'),
_ActionChip('Talent Storyboard','حوّل رحلتي وإنجازاتي إلى مخطط لفيديو تعريفي أو Highlight Story مناسب للنشر.'),
_ActionChip('Next Best Action','حلل ملفي وحدد أهم خطوة واحدة ينبغي أن أنفذها الآن لرفع جاهزيتي أو فرصي.')
,
_ActionChip('AI Scouting Card','أنشئ بطاقة كشف ذكية تجمع الرياضة والمركز والمهارات والإنجازات ومؤشرات الأداء وأهم نقاط القوة.'),
_ActionChip('Competition Strategy','حلل هدفي في المنافسة واقترح استراتيجية تحضير ومؤشرات أتابعها قبل وأثناء وبعد المنافسة.'),
_ActionChip('Skill Upgrade Plan','اختر أهم مهارة أحتاج لتطويرها واقترح تمارين ومهام ومؤشرات أسبوعية لرفع مستواي.'),
_ActionChip('Recruiter View','اعرض ملفي بالطريقة التي قد يراه بها كشاف أو مدرب، وحدد أول 3 أشياء ستلفت الانتباه وأول 3 فجوات.'),
_ActionChip('Opportunity Match Score','قيّم مدى توافق ملفي مع فرصة أقدم عليها، ووضح أسباب التوافق والفجوات قبل اتخاذ القرار.'),
_ActionChip('Progress Story','حوّل سجلات تطوري وإنجازاتي إلى قصة زمنية مختصرة توضح كيف تقدمت وما الخطوة التالية.')
,
_ActionChip('Talent One-Pager','أنشئ صفحة واحدة احترافية تلخص هويتي ومهاراتي وإنجازاتي وأهدافي وروابط أعمالي للتقديم السريع.'),
_ActionChip('Tryout Checklist','أنشئ قائمة تحقق مخصصة لاختبار الأداء تشمل الملف والمعلومات والأسئلة والمواد التي يجب تجهيزها قبل الموعد.'),
_ActionChip('Coach Questions','استخرج أهم الأسئلة التي ينبغي أن أطرحها على المدرب بناءً على أهدافي وسجلات أدائي.'),
_ActionChip('Performance Signals','استخرج أهم إشارات الأداء من سجلاتي وحدد ما يتحسن وما يحتاج متابعة دون تشخيص طبي.'),
_ActionChip('Talent Pitch Deck','حوّل ملف موهبتي إلى مخطط عرض قصير يصلح لنادٍ أو أكاديمية أو شريك أو جهة توظيف.'),
_ActionChip('Growth Priorities','رتب لي أولويات التطوير إلى عاجل، قريب، ومتقدم مع سبب واضح لكل أولوية.'),
_ActionChip('Opportunity Follow-up','أنشئ خطة متابعة احترافية بعد التقديم لفرصة أو تجربة أداء دون إرسال أي رسالة تلقائياً.'),
_ActionChip('Talent FAQ','أنشئ أسئلة وأجوبة جاهزة عن ملفي ورياضتي ومهاراتي يمكن استخدامها عند التواصل مع كشاف أو مدرب.')
,_ActionChip('Personal Development Cycle','ابنِ دورة تطوير من تقييم حالي إلى هدف ثم تنفيذ ثم مراجعة ثم هدف جديد.'),
_ActionChip('Competition Debrief','بعد المنافسة، حوّل ملاحظاتي ونتائجي إلى مراجعة عملية: ما نجح، ما لم ينجح، وما الذي أغيره لاحقاً.'),
_ActionChip('Scouting Keywords','استخرج كلمات ومهارات احترافية من ملفي تساعد الكشافين أو الجهات في العثور عليّ.'),
_ActionChip('Talent Positioning','حدد أفضل طريقة لتقديم تخصصي الرياضي أو المهني بوضوح بدون مبالغة في القدرات.'),_ActionChip('Opportunity Questions','أنشئ قائمة أسئلة أتأكد بها من جودة الفرصة أو النادي أو المشروع قبل الموافقة.'),
_ActionChip('Talent Growth Score','أنشئ مؤشراً تخطيطياً لتقدم ملفي اعتماداً على اكتماله وأهدافي وسجلات أدائي، مع توضيح طريقة الحساب.')
,
_ActionChip('Sports Performance Lab','حلل رياضتي ومؤشرات أدائي المسجلة واقترح أهم المقاييس التي أتابعها وخطة تطوير مناسبة.'),
_ActionChip('Multi-Sport Explorer','قارن بين الرياضات المناسبة لمهاراتي وأهدافي وحدد الرياضات التي يمكن أن أطور فيها مساراً تنافسياً.'),
_ActionChip('Match Day Plan','أنشئ خطة يوم منافسة تشمل التجهيز، التركيز، الإحماء، إدارة الوقت، والمراجعة بعد المنافسة دون تشخيص طبي.'),
_ActionChip('Team Chemistry','حدد المهارات التي أحتاجها من زملاء أو شركاء لتكوين فريق متكامل لرياضتي أو مشروعي.'),
_ActionChip('Sports Career Map','ارسم مسارات محتملة داخل الرياضة مثل لاعب، مدرب، محلل، كشاف، صانع محتوى أو إدارة رياضية.'),
_ActionChip('Athlete Portfolio','حوّل إنجازاتي وسجلات أدائي إلى محفظة رياضية منظمة تصلح للمشاركة مع الأندية والأكاديميات.'),
_ActionChip('Competition Journal','أنشئ قالباً لتسجيل المنافسات والنتائج والملاحظات والدروس المستفادة ومقارنتها بتقدمي الشخصي.'),
_ActionChip('Sports Opportunity Radar','حدد أنواع الأندية والأكاديميات والمسابقات والشراكات التي تتوافق مع رياضتي ومستواي وأهدافي.')
,
_ActionChip('Athlete Match Profile','جهز ملفاً مختصراً للمطابقة مع نادٍ أو أكاديمية أو فريق، مع إبراز الرياضة والمركز والمهارات والهدف.'),
_ActionChip('Training Focus','حدد محور التدريب الأهم للفترة القادمة بناءً على أهدافي ومؤشرات أدائي المسجلة.'),
_ActionChip('Season Roadmap','حوّل موسمي الرياضي إلى مراحل: إعداد، منافسة، مراجعة، واستشفاء تخطيطي عام دون نصائح طبية.'),
_ActionChip('Performance Evidence','نظم أفضل سجلات الأداء والإنجازات إلى أدلة واضحة يمكن مشاركتها مع مدرب أو كشاف.'),
_ActionChip('Club Fit','حلل نوع النادي أو الأكاديمية الأنسب لي من حيث الرياضة والمستوى والأهداف والمهارات.'),
_ActionChip('Competition Goals','حوّل هدفي في المنافسة إلى مؤشرات قابلة للمتابعة قبل وبعد كل مباراة أو سباق أو بطولة.'),
_ActionChip('Sports Content Plan','أنشئ خطة محتوى رياضي تبني حضوري وتوثق تطوري دون تضخيم النتائج أو الادعاءات.'),
_ActionChip('Talent Network','حدد أنواع الأشخاص الذين يجب أن أبني معهم شبكة مهنية: مدرب، كشاف، لاعب، أكاديمية، شريك أو صانع محتوى.')
,_ActionChip('Scouting Readiness','تحقق من جاهزية ملفي ليكون قابلاً للمراجعة من كشاف، وحدد البيانات الناقصة التي يجب إضافتها.'),
_ActionChip('Performance Milestones','حوّل أهداف الأداء إلى مراحل صغيرة قابلة للمتابعة مع نقطة مراجعة لكل مرحلة.'),
_ActionChip('Personal Best Tracker','نظم أفضل أرقامي الحالية لكل مقياس وساعدني في تحديد ما أريد تحسينه لاحقاً.'),
_ActionChip('Tryout Pitch','اكتب مقدمة قصيرة أستخدمها عند تقديم نفسي في تجربة أداء أو أكاديمية أو نادٍ.'),
_ActionChip('Coach Handoff','أنشئ ملخصاً منظماً يمكنني عرضه على مدرب جديد ليسهل عليه فهم خلفيتي وأهدافي ومؤشرات أدائي.'),
_ActionChip('Talent Opportunity Matrix','رتب الفرص المحتملة حسب ملاءمتها لمهاراتي وأهدافي ومستوى جاهزيتي.'),
_ActionChip('Sports Skill Map','ابنِ خريطة تربط رياضتي بالمهارات الأساسية والفرعية والمهارات التي أحتاجها للانتقال للمستوى التالي.')
,
_ActionChip('Video Performance Analysis','حلل فيديو أدائي الرياضي عند إرفاقه، واستخرج الملاحظات الفنية الظاهرة ونقاط القوة ومجالات التحسين دون تشخيص طبي أو ادعاء قياسات لا يمكن للفيديو إثباتها.')
,
_ActionChip('Talent Verification','جهز ملف إثبات للمهارات والإنجازات يعتمد على أدلة يمكنني تقديمها مثل النتائج والشهادات والروابط والمقاطع، مع توضيح أن التحقق النهائي يحتاج جهة موثوقة.'),
_ActionChip('Achievements & Badges','استخرج إنجازات قابلة للتحويل إلى شارات من ملفي وسجلات أدائي، واقترح شروطاً واضحة لكل شارة بدون اختلاق إنجازات.'),
_ActionChip('Talent Radar','حدد معايير بحث شخصية للفرص الرياضية المناسبة لي مثل الرياضة والمستوى والموقع ونوع الفرصة، ثم اقترح كيف أتابعها داخل AUREN.')])
  ],
),])))),
const SizedBox(height: 12),
const AurenTalentGeneralAiTools(),
const SizedBox(height: 12),
const AurenMusicTalentTools(),
const SizedBox(height: 12),
const AurenTalentSpecializedTools(),
const SizedBox(height: 12),
const AurenTalentFrontierTools(),
const SizedBox(height: 12),
const SizedBox(height:8),
StreamBuilder<List<AurenTalent>>(stream:repo.watchPublic(query:search.text,skill:skill,sport:selectedSport,evidenceOnly:evidenceOnly),builder:(c,s){if(s.hasError)return Padding(padding:const EdgeInsets.all(16),child:Text('تعذر تحميل المواهب: '+s.error.toString()));if(!s.hasData)return const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator()));final list=s.data!;if(list.isEmpty)return const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('لا توجد مواهب مطابقة.')));return Padding(padding:const EdgeInsets.all(16),child:Column(children:List.generate(list.length,(i)=>Padding(padding:EdgeInsets.only(bottom:i==list.length-1?0:8),child:_card(c,list[i])))));})]));}
void _tools(BuildContext c){showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>_PerformanceTools(onOpen:(tool)=>_openTool(c,tool)));}
Future<void> _openTool(BuildContext c,String tool)async{Navigator.pop(c);if(tool=='load'){final m=await _two(c,'مدة التدريب بالدقائق','RPE من 1 إلى 10');if(m!=null)_result(c,'حمل التدريب',(m[0]*m[1]).toStringAsFixed(1)+' وحدة');}else if(tool=='pace'){final m=await _two(c,'المسافة بالكيلومتر','الزمن بالدقائق');if(m!=null&&m[0]>0)_result(c,'الوتيرة',(m[1]/m[0]).toStringAsFixed(2)+' دقيقة/كم');}else if(tool=='speed'){final m=await _two(c,'المسافة بالكيلومتر','الزمن بالساعات');if(m!=null&&m[1]>0)_result(c,'السرعة',(m[0]/m[1]).toStringAsFixed(2)+' كم/ساعة');}else{final m=await _two(c,'المحاولات الناجحة','إجمالي المحاولات');if(m!=null&&m[1]>0)_result(c,'نسبة النجاح',(m[0]/m[1]*100).toStringAsFixed(1)+'%');}}
Future<List<double>?> _two(BuildContext c,String a,String b)async{final x=TextEditingController(),y=TextEditingController();final ok=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('أداة أداء رياضي'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:x,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:a)),TextField(controller:y,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:b))]),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('احسب'))]));final a1=double.tryParse(x.text),b1=double.tryParse(y.text);x.dispose();y.dispose();return ok==true&&a1!=null&&b1!=null?[a1,b1]:null;}
void _result(BuildContext c,String title,String value){showDialog(context:c,builder:(d)=>AlertDialog(title:Text(title),content:Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إغلاق'))]));}
int _profileScore(AurenTalent t) {
  var score = 0;
  if (t.displayName.trim().isNotEmpty) score += 10;
  if (t.bio.trim().length >= 40) score += 10;
  if (t.category.trim().isNotEmpty) score += 15;
  if (t.discipline.trim().isNotEmpty) score += 10;
  if (t.level.trim().isNotEmpty) score += 10;
  if (t.city.trim().isNotEmpty && t.country.trim().isNotEmpty) score += 10;
  score += (t.skills.length.clamp(0, 5)) * 5;
  score += (t.achievements.length.clamp(0, 3)) * 3;
  score += (t.goals.length.clamp(0, 3)) * 2;
  return score.clamp(0, 100).toInt();
}

Widget _card(BuildContext c, AurenTalent t) {
  final score = _profileScore(t);
  return Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_search)),
      title: Text(t.displayName),
      subtitle: Text([AurenTalentCategories.byId(t.category).name, t.category == 'sports' ? t.sport : '', t.discipline, t.level, t.city, t.country].where((x) => x.isNotEmpty).join(' • ')),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.checklist_outlined,size:18),Text('اكتمال $score%',style:const TextStyle(fontWeight:FontWeight.w800))]),
      onTap: () => Navigator.push(
        c,
        MaterialPageRoute(builder: (_) => AurenTalentStarProfileScreen(talent: t)),
      ),
    ),
  );
}


Future<void> _create(BuildContext c, String uid) async {
  final n = TextEditingController();
  final b = TextEditingController();
  final s = TextEditingController();
  final sportsInput = TextEditingController();
  final city = TextEditingController();
  final country = TextEditingController();
  final sport = TextEditingController();
  final discipline = TextEditingController();
  final level = TextEditingController();
  final achievements = TextEditingController();
  final goals = TextEditingController();
  String selected = 'sports';

  try {
    final ok = await showDialog<bool>(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('ملف موهبة'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'مجال الموهبة'),
                  items: AurenTalentCategories.all
                      .map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() {
                    selected = v ?? 'other';
                  }),
                ),
                TextField(
                  controller: n,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                TextField(
                  controller: b,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(labelText: 'نبذة'),
                ),
                TextField(
                  controller: s,
                  maxLength: 600,
                  decoration: const InputDecoration(
                    labelText: 'Skills, comma separated',
                  ),
                ),
                if (selected == 'sports') ...[
                  TextField(
                    controller: sport,
                    decoration: const InputDecoration(
                      labelText: 'الرياضة الأساسية (اختياري)',
                    ),
                  ),
                  TextField(
                    controller: sportsInput,
                    decoration: const InputDecoration(
                      labelText: 'رياضات أخرى (افصل بينها بفاصلة)',
                    ),
                  ),
                ],
                TextField(
                  controller: discipline,
                  decoration: const InputDecoration(
                    labelText: 'التخصص / المركز (اختياري)',
                  ),
                ),
                TextField(
                  controller: level,
                  decoration: const InputDecoration(
                    labelText: 'المستوى (اختياري)',
                  ),
                ),
                TextField(
                  controller: achievements,
                  decoration: const InputDecoration(
                    labelText: 'الإنجازات (افصل بينها بفاصلة)',
                  ),
                ),
                TextField(
                  controller: goals,
                  decoration: const InputDecoration(
                    labelText: 'الأهداف (افصل بينها بفاصلة)',
                  ),
                ),
                TextField(
                  controller: city,
                  decoration: const InputDecoration(labelText: 'المدينة'),
                ),
                TextField(
                  controller: country,
                  decoration: const InputDecoration(labelText: 'الدولة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && n.text.trim().isNotEmpty) {
      final sports = sportsInput.text
          .split(',')
          .followedBy(sport.text.split(','))
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toSet()
          .toList();
      if (city.text.trim().isEmpty || country.text.trim().isEmpty) {
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(content: Text('المدينة والدولة مطلوبتان.')),
          );
        }
        return;
      }
      try {
        await repo.save(
          ownerId: uid,
          displayName: n.text,
          bio: b.text,
          category: selected,
          sport: sport.text,
          sports: sports,
          discipline: discipline.text,
          level: level.text,
          city: city.text,
          country: country.text,
          skills: s.text.split(','),
          achievements: achievements.text.split(','),
          goals: goals.text.split(','),
        );
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(content: Text('تم إنشاء ملف الموهبة بنجاح.')),
          );
        }
      } catch (e) {
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(
            SnackBar(content: Text('تعذر حفظ ملف الموهبة: $e')),
          );
        }
      }
    }
  } finally {
    for (final x in [
      n,
      b,
      s,
      sportsInput,
      city,
      country,
      sport,
      discipline,
      level,
      achievements,
      goals,
    ]) {
      x.dispose();
    }
  }
}

}

class _ActionChip extends StatelessWidget{
 final String title; final String prompt;
 const _ActionChip(this.title,this.prompt);
 @override Widget build(BuildContext context)=>ActionChip(avatar:const Icon(Icons.auto_awesome,size:16),label:Text(title),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt))));
}

class _PerformanceTools extends StatelessWidget{
 final ValueChanged<String> onOpen; const _PerformanceTools({required this.onOpen});
 @override Widget build(BuildContext context)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(16,12,16,24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('أدوات الأداء الرياضي',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('حسابات تخطيطية بسيطة؛ لا تستبدل تقييم المدرب أو المختص.'),const SizedBox(height:12),_b('حمل التدريب','المدة × RPE',Icons.fitness_center,'load'),_b('الوتيرة','الزمن ÷ المسافة',Icons.speed,'pace'),_b('السرعة','المسافة ÷ الزمن',Icons.directions_run,'speed'),_b('نسبة النجاح','المحاولات الناجحة ÷ الإجمالي',Icons.analytics,'accuracy')])));
 Widget _b(String a,String b,IconData i,String id)=>ListTile(leading:CircleAvatar(child:Icon(i)),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(b),trailing:const Icon(Icons.chevron_right),onTap:()=>onOpen(id));
}

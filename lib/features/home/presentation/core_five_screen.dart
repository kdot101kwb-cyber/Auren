import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../services/core/auren_core_five_repository.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../business/presentation/business_products_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../creator/presentation/creator_screen.dart';
import 'remaining_modules_screen.dart';

class AurenCoreFiveScreen extends StatefulWidget {
  const AurenCoreFiveScreen({super.key});
  @override State<AurenCoreFiveScreen> createState() => _AurenCoreFiveScreenState();
}

class _AurenCoreFiveScreenState extends State<AurenCoreFiveScreen> {
  late Future<AurenCoreFiveSnapshot> _snapshot;
  static const modules = <_CoreModule>[
    _CoreModule('Personal AI','الذكاء الشخصي: أهداف، ذاكرة، فرص وتحويل الفكرة إلى خطوة.',Icons.auto_awesome),
    _CoreModule('Social / Pulse','تواصل، نشر، تفاعل، أفكار وفرص داخل شبكة AUREN.',Icons.dynamic_feed_outlined),
    _CoreModule('Business','شركات، متاجر، خدمات وفرص نمو وربط مباشر بالعملاء.',Icons.storefront_outlined),
    _CoreModule('Marketplace','اكتشف المنتجات والخدمات، اشترِ، بع، وتابع الطلبات.',Icons.shopping_bag_outlined),
    _CoreModule('Creator Studio','أنشئ المحتوى، أدِر المسودات، وانشر وطوّر جمهورك.',Icons.video_camera_back_outlined),
  ];

  @override void initState() { super.initState(); _load(); }
  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _snapshot = uid == null ? Future.value(const AurenCoreFiveSnapshot(
      activeGoals:0,businesses:0,products:0,creatorDrafts:0,posts:0,
      goalTitles:[],businessNames:[],productNames:[],draftTitles:[],firstBusinessId:null,firstProductId:null,averageGoalProgress:0,hasGoal:false,hasBusiness:false,hasProduct:false,hasCreatorDraft:false,hasPulse:false,
    )) : AurenCoreFiveRepository().load(uid);
  }

  Widget _page(String title) {
    switch(title) {
      case 'Personal AI': return const PersonalAiScreen();
      case 'Social / Pulse': return const AurenTimelineScreen();
      case 'Business': return const AurenBusinessScreen();
      case 'Marketplace': return const AurenMarketplaceScreen();
      case 'Creator Studio': return const AurenAURENCreatorStudioScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Core 5'), actions: [
      IconButton(tooltip:'Refresh',onPressed:()=>setState(_load),icon:const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<AurenCoreFiveSnapshot>(
      future:_snapshot,
      builder:(context,state) {
        if(state.connectionState==ConnectionState.waiting) return const Center(child:CircularProgressIndicator());
        final snapshot=state.data;
        if(state.hasError) return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off_outlined,size:42),const SizedBox(height:10),const Text('تعذر تحميل حالة الوحدات الخمس.'),const SizedBox(height:10),OutlinedButton.icon(onPressed:()=>setState(_load),icon:const Icon(Icons.refresh),label:const Text('حاول مرة أخرى'))])));
        if(snapshot==null) return const Center(child:Text('تعذر تحميل حالة الوحدات الخمس.'));
        return ListView(
          padding:const EdgeInsets.fromLTRB(16,12,16,28),
          children:[
            Text('أول 5 وحدات أساسية',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),
            const SizedBox(height:6),
            const Text('AUREN يربط الذكاء الشخصي، التواصل، الأعمال، التجارة وصناعة المحتوى في مسار واحد.'),
            const SizedBox(height:14),
            Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[const Icon(Icons.hub_outlined),const SizedBox(width:8),const Expanded(child:Text('Core 5 Context',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))),Text(snapshot.readinessPercent.toString() + '%')]),
              const SizedBox(height:8),
              LinearProgressIndicator(value:snapshot.readinessPercent / 100),
              const SizedBox(height:6),
              Text(snapshot.readinessLabel,style:const TextStyle(fontWeight:FontWeight.w600)),
              const SizedBox(height:8),
              const SizedBox(height:10),
              Text(snapshot.nextMove,style:const TextStyle(fontWeight:FontWeight.w600)),
              const SizedBox(height:12),
              FilledButton.tonalIcon(
                onPressed: () => _runCoreFiveBatch(context),
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('شغّل دفعة Core 5'),
              ),
              const SizedBox(height:10),
              Wrap(spacing:8,runSpacing:8,children:[
                _metric(Icons.flag_outlined,snapshot.activeGoals,'Goals'),
                _metric(Icons.dynamic_feed_outlined,snapshot.posts,'Pulse'),
                _metric(Icons.storefront_outlined,snapshot.businesses,'Business'),
                _metric(Icons.shopping_bag_outlined,snapshot.products,'Products'),
                _metric(Icons.video_camera_back_outlined,snapshot.creatorDrafts,'Drafts'),
              ]),
              const SizedBox(height:12),
              FilledButton.icon(
                onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:snapshot.toPrompt()))),
                icon:const Icon(Icons.auto_awesome),
                label:const Text('اسأل AUREN عن الخطوة التالية'),
              ),
              const SizedBox(height:10),
              Wrap(
                spacing:8,
                runSpacing:8,
                children:[
                  ActionChip(
                    avatar:const Icon(Icons.flag_outlined,size:18),
                    label:const Text('هدف → محتوى'),
                    onPressed:() async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;
                      final id = await AurenCoreFiveRepository().createCreatorDraftFromTopGoal(uid);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(id == null ? 'أنشئ هدفًا نشطًا أولاً.' : 'تم إنشاء مسودة من هدفك.')));
                      if (id != null) Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAURENCreatorStudioScreen()));
                    },
                  ),
                  ActionChip(
                    avatar:const Icon(Icons.storefront_outlined,size:18),
                    label:const Text('Business → منتج'),
                    onPressed:() {
                      final id = snapshot.firstBusinessId;
                      if (id == null) {
                        Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenBusinessScreen()));
                        return;
                      }
                      Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenBusinessProductsScreen(businessId:id,businessName:snapshot.businessNames.isEmpty?'Business':snapshot.businessNames.first)));
                    },
                  ),
                  ActionChip(
                    avatar:const Icon(Icons.dynamic_feed_outlined,size:18),
                    label:const Text('هدف → Pulse'),
                    onPressed:() async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;
                      final id = await AurenCoreFiveRepository().createPulseFromTopGoal(uid);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(id == null ? 'أنشئ هدفًا نشطًا أولاً.' : 'تم نشر هدفك في Pulse.')),
                      );
                      if (id != null) Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTimelineScreen()));
                    },
                  ),
                  ActionChip(
                    avatar:const Icon(Icons.play_arrow_outlined,size:18),
                    label:const Text('افتح Pulse'),
                    onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenTimelineScreen())),
                  ),
                ],
              ),
            ]))),
            const SizedBox(height:12),
            _nextAction(context, snapshot),
            const SizedBox(height:12),
            Card(child: ListTile(
              leading: const Icon(Icons.apps_outlined),
              title: const Text('باقي وحدات AUREN'),
              subtitle: const Text('Messenger • Search • Discover • Education • Travel • Entertainment • Agents وغيرها'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenRemainingModulesScreen())),
            )),
            const SizedBox(height:12),
            ...modules.asMap().entries.map((entry)=>Card(
              margin:const EdgeInsets.only(bottom:12),
              child:ListTile(
                contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
                leading:CircleAvatar(child:Text((entry.key+1).toString())),
                title:Row(children:[Icon(entry.value.icon,size:20),const SizedBox(width:8),Expanded(child:Text(entry.value.title,style:const TextStyle(fontWeight:FontWeight.bold)))]),
                subtitle:Padding(padding:const EdgeInsets.only(top:6),child:Text(entry.value.description)),
                trailing:const Icon(Icons.chevron_right),
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_page(entry.value.title))),
              ),
            )),
          ],
        );
      },
    ),
  );

  Future<void> _runCoreFiveBatch(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تشغيل دفعة Core 5؟'),
        content: const Text(
          'سيحوّل هدفك النشط إلى مسودة Creator وينشر نسخة منه في Pulse. '
          'لن يتم شراء أو دفع أو تنفيذ إجراء حساس.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تشغيل'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تشغيل دفعة Core 5...')),
    );
    try {
      final repo = AurenCoreFiveRepository();
      final draftId = await repo.createCreatorDraftFromTopGoal(uid);
      final postId = await repo.createPulseFromTopGoal(uid);
      if (!context.mounted) return;
      final created = [
        if (draftId != null) 'Creator Draft',
        if (postId != null) 'Pulse',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created.isEmpty
                ? 'أنشئ هدفًا نشطًا أولاً.'
                : 'اكتملت الدفعة: ${created.join(' + ')}',
          ),
        ),
      );
      setState(_load);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تشغيل الدفعة: $e')),
        );
      }
    }
  }

  Widget _metric(IconData icon,int value,String label)=>Chip(avatar:Icon(icon,size:18),label:Text(value.toString() + ' ' + label));

  Widget _nextAction(BuildContext context, AurenCoreFiveSnapshot s) {
    final title=s.actionTitle;
    VoidCallback? action;
    if (s.activeGoals == 0) action=()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PersonalAiScreen()));
    else if (s.products == 0 && s.businesses > 0) action=()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenBusinessProductsScreen(businessId:s.firstBusinessId!,businessName:s.businessNames.isEmpty?'Business':s.businessNames.first)));
    else if (s.creatorDrafts == 0) action=()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenAURENCreatorStudioScreen()));
    else if (s.posts == 0) action=()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenTimelineScreen()));
    else action=()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenBusinessScreen()));
    return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.bolt)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(s.nextMove),trailing:action==null?null:const Icon(Icons.arrow_forward),onTap:action));
  }
}

class _CoreModule {
  final String title; final String description; final IconData icon;
  const _CoreModule(this.title,this.description,this.icon);
}

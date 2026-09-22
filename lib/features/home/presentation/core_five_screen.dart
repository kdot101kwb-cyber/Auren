import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/core/auren_core_five_repository.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../creator/presentation/creator_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

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
      goalTitles:[],businessNames:[],productNames:[],draftTitles:[],averageGoalProgress:0,
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
        if(snapshot==null) return const Center(child:Text('تعذر تحميل حالة الوحدات الخمس.'));
        return ListView(
          padding:const EdgeInsets.fromLTRB(16,12,16,28),
          children:[
            Text('أول 5 وحدات أساسية',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),
            const SizedBox(height:6),
            const Text('AUREN يربط الذكاء الشخصي، التواصل، الأعمال، التجارة وصناعة المحتوى في مسار واحد.'),
            const SizedBox(height:14),
            Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[const Icon(Icons.hub_outlined),const SizedBox(width:8),const Expanded(child:Text('Core 5 Context',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))),Text(snapshot.averageGoalProgress.toString() + '%')]),
              const SizedBox(height:8),
              LinearProgressIndicator(value:snapshot.averageGoalProgress.clamp(0,100)/100),
              const SizedBox(height:10),
              Text(snapshot.nextMove,style:const TextStyle(fontWeight:FontWeight.w600)),
              const SizedBox(height:12),
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
            ]))),
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

  Widget _metric(IconData icon,int value,String label)=>Chip(avatar:Icon(icon,size:18),label:Text(value.toString() + ' ' + label));
}

class _CoreModule {
  final String title; final String description; final IconData icon;
  const _CoreModule(this.title,this.description,this.icon);
}

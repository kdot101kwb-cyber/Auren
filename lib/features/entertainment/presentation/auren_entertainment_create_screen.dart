import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';

class AurenEntertainmentCreateScreen extends StatefulWidget {
  const AurenEntertainmentCreateScreen({super.key});
  @override State<AurenEntertainmentCreateScreen> createState() => _AurenEntertainmentCreateScreenState();
}

class _AurenEntertainmentCreateScreenState extends State<AurenEntertainmentCreateScreen> {
  final _promptController = TextEditingController();
  String _mode = 'أغنية'; String _mood = 'سينمائي'; String _length = 'متوسط';
  static const _modes = <String, IconData>{'أغنية': Icons.music_note_rounded, 'قصة': Icons.auto_stories_rounded, 'فيديو': Icons.movie_creation_rounded, 'بودكاست': Icons.podcasts_rounded, 'عالم': Icons.public_rounded};
  static const _moods = <String>['سينمائي','هادئ','حماسي','غامض','كوميدي','ملهم'];
  static const _lengths = <String>['قصير','متوسط','طويل'];
  @override void dispose(){ _promptController.dispose(); super.dispose(); }
  void _create(){
    final idea = _promptController.text.trim();
    final prompt = '''
أنت AUREN Entertainment Creator AI.
حوّل هذه الفكرة إلى مشروع ترفيهي أصلي قابل للتنفيذ داخل AUREN.
نوع المشروع: $_mode
الطابع: $_mood
الطول: $_length
فكرة المستخدم: ${idea.isEmpty ? 'اقترح فكرة أصلية مناسبة.' : idea}
المطلوب: Concept واضح، عنوان ووصف، خطة إنتاج، ما يمكن إنشاؤه بالذكاء الاصطناعي، وهيكل مناسب للمشروع، ثم خطوات تنفيذية. حافظ على الأصالة وحقوق الملكية ولا تقلد صوت أو هوية فنان حقيقي دون إذن.
''';
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)));
  }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: const Text('AUREN Create Studio'), actions:[IconButton(icon:const Icon(Icons.auto_awesome_rounded),onPressed:_create)]),
      body: ListView(padding:const EdgeInsets.fromLTRB(16,12,16,32),children:[
        _hero(context), const SizedBox(height:20),
        const Text('ماذا تريد أن تصنع؟',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)), const SizedBox(height:10),
        Wrap(spacing:9,runSpacing:9,children:_modes.entries.map((e)=>ChoiceChip(avatar:Icon(e.value,size:18),label:Text(e.key),selected:_mode==e.key,onSelected:(_)=>setState(()=>_mode=e.key))).toList()),
        const SizedBox(height:22), const Text('الطابع',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)), const SizedBox(height:9),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:_moods.map((m)=>Padding(padding:const EdgeInsetsDirectional.only(end:8),child:ChoiceChip(label:Text(m),selected:_mood==m,onSelected:(_)=>setState(()=>_mood=m))).toList())),
        const SizedBox(height:22), const Text('الطول',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)), const SizedBox(height:9),
        SegmentedButton<String>(segments:_lengths.map((v)=>ButtonSegment<String>(value:v,label:Text(v))).toList(),selected:{_length},onSelectionChanged:(v)=>setState(()=>_length=v.first)),
        const SizedBox(height:22), TextField(controller:_promptController,minLines:5,maxLines:8,decoration:InputDecoration(labelText:'فكرتك',hintText:'مثلاً: أريد أغنية سفر عربية هادئة بإحساس سينمائي...',alignLabelWithHint:true,border:OutlineInputBorder(borderRadius:BorderRadius.circular(18)))),
        const SizedBox(height:18), FilledButton.icon(onPressed:_create,icon:const Icon(Icons.auto_awesome_rounded),label:const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('ابدأ الإنشاء مع AUREN AI',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)))),
        const SizedBox(height:12), Text('هذه المرحلة تبني الـConcept وخطة الإنتاج عبر AUREN AI. ربط مولدات الصوت/الفيديو/العوالم الفعلية يتم عبر مزود الإنتاج المناسب لاحقاً.',textAlign:TextAlign.center,style:Theme.of(context).textTheme.bodySmall),
      ]));
  }
  Widget _hero(BuildContext context)=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:LinearGradient(colors:[Theme.of(context).colorScheme.primaryContainer,Theme.of(context).colorScheme.secondaryContainer])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.auto_awesome_rounded,size:34),SizedBox(height:10),Text('من فكرة إلى تجربة',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900)),SizedBox(height:7),Text('أنشئ أغنية، قصة، فيديو، بودكاست أو عالماً تفاعلياً — وخلّي AUREN يساعدك في تحويل الفكرة إلى خطة إنتاج.')])) ;
}
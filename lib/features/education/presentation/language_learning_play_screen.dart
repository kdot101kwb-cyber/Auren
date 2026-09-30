import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/language_learning_game_service.dart';

class LanguageLearningPlayScreen extends StatefulWidget {
  const LanguageLearningPlayScreen({super.key});
  @override State<LanguageLearningPlayScreen> createState() => _LanguageLearningPlayScreenState();
}

class _LanguageLearningPlayScreenState extends State<LanguageLearningPlayScreen> {
  final service = LanguageLearningGameService();
  String language = 'English';
  int index = 0, correct = 0, total = 0, streak = 0, xp = 0;
  final answer = TextEditingController();
  LanguageWord get word => LanguageLearningGameService.starterWords[index];

  void submit() {
    final value = answer.text.trim().toLowerCase();
    if (value.isEmpty) return;
    final isCorrect = value == word.answer.toLowerCase();
    final nextStreak = isCorrect ? streak + 1 : 0;
    setState(() {
      total++;
      if (isCorrect) correct++;
      streak = nextStreak;
      xp += service.xpForAnswer(correct:isCorrect, streak:nextStreak);
      answer.clear();
      index = (index + 1) % LanguageLearningGameService.starterWords.length;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      service.saveSession(uid, LanguageGameSession(language:language, mode:LanguageGameMode.vocabulary,
        xp:xp, correct:correct, total:total, streak:streak));
    }
  }

  @override void dispose() { answer.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Language Play')),
    body: ListView(padding:const EdgeInsets.all(16), children:[
      const Text('تعلم اللغة باللعب', style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
      const SizedBox(height:6),
      const Text('كلمات • تحديات • نقاط • سلاسل إجابات • تقدم محفوظ'),
      const SizedBox(height:16),
      DropdownButtonFormField<String>(
        value:language, decoration:const InputDecoration(labelText:'Language'),
        items:LanguageLearningGameService.languages.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
        onChanged:(v)=>setState(()=>language=v ?? language),
      ),
      const SizedBox(height:16),
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
        Text('Translate: ${word.prompt}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        if(word.hint != null) Padding(padding:const EdgeInsets.only(top:8),child:Text(word.hint!,textAlign:TextAlign.center)),
        const SizedBox(height:18),
        TextField(controller:answer,textInputAction:TextInputAction.done,onSubmitted:(_)=>submit(),
          decoration:const InputDecoration(labelText:'Your answer',border:OutlineInputBorder())),
        const SizedBox(height:12),
        FilledButton.icon(onPressed:submit,icon:const Icon(Icons.sports_esports),label:const Text('Play & Check')),
      ]))),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:_stat('XP','$xp')), Expanded(child:_stat('Accuracy','${total == 0 ? 0 : correct * 100 ~/ total}%')),
        Expanded(child:_stat('Streak','$streak')),
      ]),
      const SizedBox(height:20),
      const Text('More learning games',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      const Wrap(spacing:8,runSpacing:8,children:[
        Chip(avatar:Icon(Icons.grid_view),label:Text('Matching')),
        Chip(avatar:Icon(Icons.headphones),label:Text('Listening')),
        Chip(avatar:Icon(Icons.spellcheck),label:Text('Spelling')),
        Chip(avatar:Icon(Icons.quiz),label:Text('Quick Quiz')),
        Chip(avatar:Icon(Icons.timer),label:Text('Daily Challenge')),
      ]),
    ]),
  );

  Widget _stat(String label,String value)=>Card(child:Padding(padding:const EdgeInsets.symmetric(vertical:12),
    child:Column(children:[Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(label)])));
}

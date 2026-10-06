import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../core/models/opportunity.dart';
import '../../../services/talent/talent_scout_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenClubCoachMatchScreen extends StatefulWidget { const AurenClubCoachMatchScreen({super.key}); @override State<AurenClubCoachMatchScreen> createState()=>_AurenClubCoachMatchScreenState(); }
class _AurenClubCoachMatchScreenState extends State<AurenClubCoachMatchScreen>{
 bool loading=true; String? error; List<Map<String,dynamic>> matches=[]; int minScore=0; String sportFilter='all'; String locationFilter='';
 @override void initState(){super.initState(); _load();}
 Future<void> _load() async {
  final uid=FirebaseAuth.instance.currentUser?.uid; if(uid==null){setState(()=>loading=false);return;}
  try { final t=await FirebaseFirestore.instance.collection('talents').where('ownerId',isEqualTo:uid).limit(1).get(); if(t.docs.isEmpty){setState(()=>loading=false);return;} final talent=AurenTalent.fromMap(t.docs.first.id,t.docs.first.data()); final o=await FirebaseFirestore.instance.collection('opportunities').where('status',isEqualTo:'open').limit(100).get(); final ops=o.docs.map((d)=>AurenOpportunity.fromMap(d.id,d.data())).toList(); final found=await TalentScoutService().findSportsMatches(talent:talent,opportunities:ops); if(mounted)setState(() { loading = false; matches = found; }); } catch(e){if(mounted)setState(() { loading = false; error = e.toString(); });}
 }
 List<Map<String,dynamic>> get filteredMatches {
  return matches.where((m) {
    final score = (m['score'] as int?) ?? 0;
    final sports = (m['sportHits'] as List?)?.cast<String>() ?? const <String>[];
    final locationOk = locationFilter.trim().isEmpty || m['locationMatch'] == true;
    final sportOk = sportFilter == 'all' || sports.any((s) => s.toLowerCase().contains(sportFilter.toLowerCase()));
    return score >= minScore && locationOk && sportOk;
  }).toList();
 }
 @override
 Widget build(BuildContext context) {
  final visible = filteredMatches;
  final sportOptions = <String>{
    for (final m in matches)
      ...((m['sportHits'] as List?)?.map((e) => e.toString()) ?? const <String>[]),
  }.toList()..sort();

  return Scaffold(
   appBar: AppBar(title: const Text('Club & Coach Match')),
   body: loading
       ? const Center(child: CircularProgressIndicator())
       : error != null
           ? Center(child: Text('تعذر المطابقة: $error'))
           : matches.isEmpty
               ? const Center(child: Text('لا توجد فرص أندية أو مدربين مناسبة حالياً.'))
               : Column(
                   children: [
                     Padding(
                       padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                       child: Wrap(
                         spacing: 6,
                         runSpacing: 6,
                         children: [
                           const Text('الحد الأدنى:'),
                           for (final x in [0, 40, 60, 80])
                             FilterChip(
                               label: Text('$x%'),
                               selected: minScore == x,
                               onSelected: (_) => setState(() => minScore = x),
                             ),
                           FilterChip(
                             label: const Text('كل الرياضات'),
                             selected: sportFilter == 'all',
                             onSelected: (_) => setState(() => sportFilter = 'all'),
                           ),
                           for (final s in sportOptions.take(6))
                             FilterChip(
                               label: Text(s),
                               selected: sportFilter == s,
                               onSelected: (_) => setState(() => sportFilter = s),
                             ),
                           FilterChip(
                             label: const Text('نفس الموقع'),
                             selected: locationFilter.isNotEmpty,
                             onSelected: (_) => setState(
                               () => locationFilter = locationFilter.isEmpty ? 'same' : '',
                             ),
                           ),
                         ],
                       ),
                     ),
                     if (visible.isEmpty)
                       const Padding(
                         padding: EdgeInsets.all(20),
                         child: Text('لا توجد نتائج تطابق الفلاتر الحالية.'),
                       ),
                     if (visible.isNotEmpty)
                       Expanded(
                         child: ListView.builder(
                           padding: const EdgeInsets.all(16),
                           itemCount: visible.length,
                           itemBuilder: (_, i) {
                             final m = visible[i];
                             final skills = (m['matchedSkills'] as List).cast<String>();
                             final sports = (m['sportHits'] as List).cast<String>();
                             return Card(
                               child: Padding(
                                 padding: const EdgeInsets.all(14),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       children: [
                                         Expanded(
                                           child: Text(
                                             '${m['title']}',
                                             style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                           ),
                                         ),
                                         Chip(label: Text('${m['score']}%')),
                                       ],
                                     ),
                                     const SizedBox(height: 6),
                                     Text('${m['description']}'),
                                     if (sports.isNotEmpty)
                                       Padding(
                                         padding: const EdgeInsets.only(top: 8),
                                         child: Text('رياضة مطابقة: ${sports.join(' • ')}'),
                                       ),
                                     if (skills.isNotEmpty)
                                       Padding(
                                         padding: const EdgeInsets.only(top: 4),
                                         child: Text('مهارات مطابقة: ${skills.join(' • ')}'),
                                       ),
                                     if (m['levelMatch'] == true)
                                       const Padding(
                                         padding: EdgeInsets.only(top: 4),
                                         child: Text('المستوى متوافق'),
                                       ),
                                     if (m['locationMatch'] == true)
                                       const Padding(
                                         padding: EdgeInsets.only(top: 4),
                                         child: Text('الموقع متوافق'),
                                       ),
                                     const SizedBox(height: 10),
                                     SizedBox(
                                       width: double.infinity,
                                       child: OutlinedButton.icon(
                                         onPressed: () => Navigator.push(
                                           context,
                                           MaterialPageRoute(
                                             builder: (_) => MessengerScreen(
                                               initialPrompt: 'أريد التواصل بخصوص فرصة رياضية: ${m['title']}. استخدم فقط المعلومات الظاهرة، وساعدني في صياغة رسالة مهنية.',
                                             ),
                                           ),
                                         ),
                                         icon: const Icon(Icons.message_outlined),
                                         label: const Text('صياغة رسالة مع AUREN AI'),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             );
                           },
                         ),
                       ),
                   ],
                 ),
  );
 }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class EducationBadge {
  final String id, title, description;
  final int xp;
  const EducationBadge(this.id,this.title,this.description,this.xp);
}
class EducationGamificationState {
  final int xp, streak, completedMissions;
  final String lastActiveDay;
  final List<String> badges;
  const EducationGamificationState({this.xp=0,this.streak=0,this.completedMissions=0,this.lastActiveDay='',this.badges=const []});
  int get level => (xp ~/ 100) + 1;
  int get levelXp => xp % 100;
  double get progress => levelXp / 100;
  Map<String,dynamic> toMap()=>{'xp':xp,'streak':streak,'completedMissions':completedMissions,'lastActiveDay':lastActiveDay,'badges':badges};
  factory EducationGamificationState.fromMap(Map<String,dynamic> m)=>EducationGamificationState(
    xp:(m['xp'] as num?)?.toInt()??0,streak:(m['streak'] as num?)?.toInt()??0,
    completedMissions:(m['completedMissions'] as num?)?.toInt()??0,lastActiveDay:(m['lastActiveDay'] as String?)??'',
    badges:List<String>.from(m['badges']??const []));
}
class EducationGamificationService {
  final FirebaseFirestore db;
  EducationGamificationService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  DocumentReference<Map<String,dynamic>> _ref(String uid)=>db.collection('users').doc(uid).collection('education').doc('gamification');
  Stream<EducationGamificationState> watch(String uid)=>_ref(uid).snapshots().map((s)=>EducationGamificationState.fromMap(s.data()??{}));
  static const badges=[
    EducationBadge('first_game','أول لعبة','أكملت أول نشاط تعليمي',20),
    EducationBadge('ten_games','10 أنشطة','أكملت 10 أنشطة تعليمية',50),
    EducationBadge('seven_streak','أسبوع متواصل','حافظت على 7 أيام متتالية',100),
    EducationBadge('xp_500','500 XP','جمعت 500 نقطة خبرة',100),
    EducationBadge('xp_1000','1000 XP','جمعت 1000 نقطة خبرة',200),
  ];
  Future<EducationGamificationState> awardActivity(String uid,{int xp=10}) async {
    final ref=_ref(uid), snap=await ref.get(), old=EducationGamificationState.fromMap(snap.data()??{});
    final d=DateTime.now().toUtc();
    String key(DateTime x)=>x.year.toString().padLeft(4,'0')+'-'+x.month.toString().padLeft(2,'0')+'-'+x.day.toString().padLeft(2,'0');
    final day=key(d), yesterday=key(d.subtract(const Duration(days:1)));
    if(old.lastActiveDay==day)return old;
    final streak=old.lastActiveDay==yesterday?old.streak+1:1;
    final newXp=old.xp+xp, completed=old.completedMissions+1;
    final earned=<String>[...old.badges];
    void add(String id){if(!earned.contains(id))earned.add(id);}
    add('first_game'); if(completed>=10)add('ten_games'); if(streak>=7)add('seven_streak'); if(newXp>=500)add('xp_500'); if(newXp>=1000)add('xp_1000');
    final next=EducationGamificationState(xp:newXp,streak:streak,completedMissions:completed,lastActiveDay:day,badges:earned);
    await ref.set(next.toMap(),SetOptions(merge:true)); return next;
  }
}

import '../../../core/models/talent.dart';

class TalentSkillGraph {
  final List<String> coreSkills;
  final List<String> supportingSkills;
  final List<String> evidenceSkills;
  final List<String> nextSkills;
  const TalentSkillGraph({required this.coreSkills, required this.supportingSkills, required this.evidenceSkills, required this.nextSkills});
}

class TalentSkillGraphService {
  static TalentSkillGraph build(AurenTalent talent) {
    final skills = talent.skills.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final sports = {...talent.sports, if (talent.sport.trim().isNotEmpty) talent.sport}.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final evidence = <String>[];
    if (talent.verificationEvidence.isNotEmpty) evidence.add('أدلة الملف');
    if (talent.achievements.isNotEmpty) evidence.add('إنجازات مسجلة');
    final next = <String>[];
    if (skills.length < 3) next.add('إضافة مهارات أساسية');
    if (talent.goals.isEmpty) next.add('تحديد هدف تطوير');
    if (talent.verificationEvidence.isEmpty) next.add('إضافة أدلة للمهارات والإنجازات');
    if (next.isEmpty) next.add('تسجيل قياسات أداء مرتبطة بالرياضة');
    return TalentSkillGraph(coreSkills: skills.take(8).toList(), supportingSkills: sports.take(6).toList(), evidenceSkills: evidence, nextSkills: next.take(4).toList());
  }
}
